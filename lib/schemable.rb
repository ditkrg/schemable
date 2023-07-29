# frozen_string_literal: true

require_relative "schemable/version"
require 'active_support/concern'

module Schemable
  class Error < StandardError; end

  extend ActiveSupport::Concern

  included do

    # Maps a given type name to a corresponding JSON schema object that represents that type.
    #
    # @param type_name [String, Symbol]  A String or Symbol representing the type of the property to be mapped.
    #
    # @return [Hash, nil] A Hash that represents a JSON schema object for the given type, or nil if the type is not recognized.
    def type_mapper(type_name)
      {
        text: { type: :string },
        string: { type: :string },
        integer: { type: :integer },
        float: { type: :number, format: :float },
        decimal: { type: :number, format: :double },
        datetime: { type: :string, format: :"date-time" },
        date: { type: :string, format: :date },
        time: { type: :string, format: :time },
        boolean: { type: :boolean },
        trueclass: { type: :boolean, default: true },
        falseclass: { type: :boolean, default: false },
        binary: { type: :string, format: :binary },
        json: { type: :object, properties: {} },
        jsonb: { type: :object, properties: {} },
        array: { type: :array, items: { anyOf: [
          { type: :string }, { type: :integer }, { type: :number, format: :float }, { type: :number, format: :double }, { type: :boolean }, { type: :object, properties: {} }
        ] } },
        hash: { type: :object, properties: {} },
        object: { type: :object, properties: {} }
      }[type_name.try(:to_sym)]
    end

    # Modify a JSON schema object by merging new properties into it or deleting a specified path.
    #
    # @param original_schema [Hash] The original schema object to modify.
    # @param new_props [Hash] The new properties to merge into the schema.
    # @param given_path [String, nil] The path to the property to modify or delete, if any.
    # Use dot notation to specify nested properties (e.g. "person.address.city").
    # @param delete [Boolean] Whether to delete the property at the given path, if it exists.
    # @raise [ArgumentError] If `delete` is true but `given_path` is nil, or if `given_path` does not exist in the original schema.
    #
    # @return [Hash] A new schema object with the specified modifications.
    #
    # @example Merge new properties into the schema
    #   original_schema = { type: 'object', properties: { name: { type: 'string' } } }
    #   new_props = { properties: { age: { type: 'integer' } } }
    #   modify_schema(original_schema, new_props)
    #   # => { type: 'object', properties: { name: { type: 'string' }, age: { type: 'integer' } } }
    #
    # @example Delete a property from the schema
    #   original_schema = { type: 'object', properties: { name: { type: 'string' } } }
    #   modify_schema(original_schema, {}, 'properties.name', delete: true)
    #   # => { type: 'object', properties: {} }
    def modify_schema(original_schema, new_props, given_path = nil, delete: false)
      return new_props if original_schema.nil?

      if given_path.nil? && delete
        raise ArgumentError, "Cannot delete without a given path"
      end

      if given_path.present?
        path_segments = given_path.split('.').map(&:to_sym)

        if path_segments.size == 1
          unless original_schema.key?(path_segments.first)
            raise ArgumentError, "Given path does not exist in the original schema"
          end
        else
          unless original_schema.dig(*path_segments[0..-2]).is_a?(Hash) && original_schema.dig(*path_segments)
            raise ArgumentError, "Given path does not exist in the original schema"
          end
        end

        path_hash = path_segments.reverse.reduce(new_props) { |a, n| { n => a } }

        if delete
          new_schema = original_schema.deep_dup
          parent_hash = path_segments.size > 1 ? new_schema.dig(*path_segments[0..-2]) : new_schema
          parent_hash.delete(path_segments.last)
          new_schema
        else
          original_schema.deep_merge(path_hash)
        end
      else
        original_schema.deep_merge(new_props)
      end
    end

    # Returns a JSON Schema attribute definition for a given attribute on the model.
    #
    # @param attribute [Symbol] The name of the attribute.
    #
    # @raise [NoMethodError] If the `model` object does not respond to `columns_hash`.
    #
    # @return [Hash] The JSON Schema attribute definition as a Hash or an empty Hash if the attribute does not exist on the model.
    #
    # @example
    #  attribute_schema(:title)
    #  # => { "type": "string" }
    def attribute_schema(attribute)
      # Get the column hash for the attribute
      column_hash = model.columns_hash[attribute.to_s]

      # Check if this attribute has a custom JSON Schema definition
      if array_types.keys.include?(attribute)
        return array_types[attribute]
      end

      if additional_response_attributes.keys.include?(attribute)
        return additional_response_attributes[attribute]
      end

      # Check if this is an array attribute
      if column_hash.as_json.try(:[], 'sql_type_metadata').try(:[], 'sql_type').include?('[]')
        return type_mapper(:array)
      end

      # Map the column type to a JSON Schema type if none of the above conditions are met
      response = type_mapper(column_hash.try(:type))

      # If the attribute is nullable, modify the schema accordingly
      if response && nullable_attributes.include?(attribute)
        return modify_schema(response, { nullable: true })
      end

      # If attribute is an enum, modify the schema accordingly
      if response && model.defined_enums.key?(attribute.to_s)
        return modify_schema(response, { type: :string, enum: model.defined_enums[attribute.to_s].keys })
      end

      return response unless response.nil?

      # If we haven't found a schema type yet, try to infer it from the type of the attribute's value in the instance data
      type_from_factory = @instance.as_json['data']['attributes'][attribute.to_s.camelize(:lower)].class.name.downcase
      response = type_mapper(type_from_factory) if type_from_factory.present?

      return response unless response.nil?

      # If we still haven't found a schema type, default to object
      type_mapper(:object)

    rescue NoMethodError
      # Log a warning if the attribute does not exist on the model
      Rails.logger.warn("\e[33mWARNING: #{model} does not have an attribute named \e[31m#{attribute}\e[0m")
      {}
    end

    # Returns a JSON Schema for the model's attributes.
    # This method is used to generate the schema for the `attributes` that are automatically generated by using the `attribute_schema` method on each attribute.
    #
    # @note The `additional_response_attributes` and `excluded_response_attributes` are applied to the schema returned by this method.
    #
    # @example
    # {
    #   type: :object,
    #   properties: {
    #     id: { type: :string },
    #     title: { type: :string }
    #   }
    # }
    #
    # @return [Hash] The JSON Schema for the model's attributes.
    def attributes_schema
      schema = {
        type: :object,
        properties: attributes.reduce({}) do |props, attr|
          props[attr] = attribute_schema(attr)
          props
        end
      }

      # modify the schema to include additional response relations
      schema = modify_schema(schema, additional_response_attributes, given_path = "properties")

      # modify the schema to exclude response relations
      excluded_response_attributes.each do |key|
        schema = modify_schema(schema, {}, "properties.#{key}", delete: true)
      end

      schema
    end

    # Generates the schema for the relationships of a resource.
    #
    # @param relations [Hash] A hash representing the relationships of the resource in the form of { belongs_to: {}, has_many: {} }.
    # If not provided, the relationships will be inferred from the model's associations.
    #
    # @note The `additional_response_relations` and `excluded_response_relations` are applied to the schema returned by this method.
    #
    # @param expand [Boolean] A boolean indicating whether to expand the relationships in the schema.
    # @param exclude_from_expansion [Array] An array of relationship names to exclude from expansion.
    #
    # @example
    # {
    #   type: :object,
    #   properties: {
    #     province: {
    #       type: :object,
    #       properties: {
    #         meta: {
    #           type: :object,
    #           properties: {
    #             included: {
    #               type: :boolean, default: false
    #             }
    #           }
    #         }
    #       }
    #     }
    #   }
    # }
    #
    # @return [Hash] A hash representing the schema for the relationships.
    def relationships_schema(relations = try(:relationships), expand: false, exclude_from_expansion: [])
      return {} if relations.blank?
      return {} if relations == { belongs_to: {}, has_many: {} }

      schema = {
        type: :object,
        properties: relations.reduce({}) do |props, (relation_type, relation_definitions)|
          non_expanded_data_properties = {
            type: :object,
            properties: {
              meta: {
                type: :object,
                properties: {
                  included: { type: :boolean, default: false }
                }
              }
            }
          }

          if relation_type == :has_many
            props.merge!(
              relation_definitions.keys.index_with do |relationship|

                result = {
                  type: :object,
                  properties: {
                    data: {
                      type: :array,
                      items: {
                        type: :object,
                        properties: {
                          id: { type: :string },
                          type: { type: :string, default: relation_definitions[relationship].model_name }
                        }
                      }
                    }
                  }
                }

                result = non_expanded_data_properties if !expand || exclude_from_expansion.include?(relationship)

                result
              end
            )
          else
            props.merge!(
              relation_definitions.keys.index_with do |relationship|

                result = {
                  type: :object,
                  properties: {
                    data: {
                      type: :object,
                      properties: {
                        id: { type: :string },
                        type: { type: :string, default: relation_definitions[relationship].model_name }

                      }
                    }
                  }
                }

                result = non_expanded_data_properties if !expand || exclude_from_expansion.include?(relationship)

                result
              end
            )
          end
        end
      }

      # modify the schema to include additional response relations
      schema = modify_schema(schema, additional_response_relations, "properties")

      # modify the schema to exclude response relations
      excluded_response_relations.each do |key|
        schema = modify_schema(schema, {}, "properties.#{key}", delete: true)
      end

      schema
    end

    # Generates the schema for the included resources in a response.
    #
    # @note The `additional_response_includes` and `excluded_response_includes` (yet to be implemented) are applied to the schema returned by this method.
    #
    # @param relations [Hash] A hash representing the relationships of the resource in the form of { belongs_to: {}, has_many: {} }.
    # If not provided, the relationships will be inferred from the model's associations.
    # @param expand [Boolean] A boolean indicating whether to expand the relationships of the relationships in the schema.
    # @param exclude_from_expansion [Array] An array of relationship names to exclude from expansion.
    # @param metadata [Hash] Additional metadata to include in the schema, usually received from the nested_relationships method sent by the response_schema method.
    #
    # @example
    # {
    #   included: {
    #     type: :array,
    #     items: {
    #       anyOf:
    #         [
    #           {
    #             type: :object,
    #             properties: {
    #               type: { type: :string, default: "provinces" },
    #               id: { type: :string },
    #               attributes: {
    #                 type: :object,
    #                 properties: {
    #                   id: { type: :string },
    #                   name: { type: :string }
    #                 }
    #               }
    #             }
    #           }
    #         ]
    #     }
    #   }
    # }
    #
    # @return [Hash] A hash representing the schema for the included resources.
    def included_schema(relations = try(:relationships), expand: false, exclude_from_expansion: [], metadata: {})
      return {} if relations.blank?
      return {} if relations == { belongs_to: {}, has_many: {} }

      schema = {
        included: {
          type: :array,
          items: {
            anyOf:
              relations.reduce([]) do |props, (relation_type, relation_definitions)|
                props + relation_definitions.keys.reduce([]) do |props, relationship|
                  props + [
                    unless exclude_from_expansion.include?(relationship)
                      {
                        type: :object,
                        properties: {
                          type: { type: :string, default: relation_definitions[relationship].model_name },
                          id: { type: :string },
                          attributes: begin
                                        relation_definitions[relationship].new.attributes_schema || {}
                                      rescue NoMethodError
                                        {}
                                      end
                        }.merge(
                          if relation_definitions[relationship].new.relationships != { belongs_to: {}, has_many: {} } || relation_definitions[relationship].new.relationships.blank?
                            if !expand || metadata.blank?
                              { relationships: relation_definitions[relationship].new.relationships_schema(expand: false) }
                            else
                              { relationships: relation_definitions[relationship].new.relationships_schema(relations = metadata[:nested_relationships][relationship], expand: true, exclude_from_expansion: exclude_from_expansion) }
                            end
                          else
                            {}
                          end
                        )
                      }
                    end
                  ].concat(
                    [
                      if expand && metadata.present? && !exclude_from_expansion.include?(relationship)
                        extra_relations = []
                        metadata[:nested_relationships].keys.reduce({}) do |props, nested_relationship|
                          if metadata[:nested_relationships][relationship].present?
                            props.merge!(metadata[:nested_relationships][nested_relationship].keys.each_with_object({}) do |relationship_type, inner_props|
                              props.merge!(metadata[:nested_relationships][nested_relationship][relationship_type].keys.each_with_object({}) do |relationship, inner_inner_props|

                                extra_relation_schema = {
                                  type: :object,
                                  properties: {
                                    type: { type: :string, default: metadata[:nested_relationships][nested_relationship][relationship_type][relationship].model_name },
                                    id: { type: :string },
                                    attributes: metadata[:nested_relationships][nested_relationship][relationship_type][relationship].new.attributes_schema
                                  }.merge(
                                    if metadata[:nested_relationships][nested_relationship][relationship_type][relationship].new.relationships == { belongs_to: {}, has_many: {} } || metadata[:nested_relationships][nested_relationship][relationship_type][relationship].new.relationships.blank?
                                      {}
                                    else
                                      result = { relationships: metadata[:nested_relationships][nested_relationship][relationship_type][relationship].new.relationships_schema(expand: false) }
                                      return {} if result == { relationships: {} }
                                      result
                                    end
                                  )
                                }

                                extra_relations << extra_relation_schema
                              end
                              )
                            end
                            )
                          end
                        end

                        extra_relations
                      end
                    ].flatten
                  ).compact_blank
                end
              end
          }
        }
      }

      schema = modify_schema(schema, additional_response_included, "included.items")

      schema
    end

    # Generates the schema for the response of a resource or collection of resources in JSON API format.
    #
    # @param relations [Hash] A hash representing the relationships of the resource in the form of { belongs_to: {}, has_many: {} }.
    # If not provided, the relationships will be inferred from the model's associations.
    # @param expand [Boolean] A boolean indicating whether to expand the relationships of the relationships in the schema.
    # @param exclude_from_expansion [Array] An array of relationship names to exclude from expansion.
    # @param multi [Boolean] A boolean indicating whether the response contains multiple resources.
    # @param nested [Boolean] A boolean indicating whether the response is to be expanded further than the first level of relationships. (expand relationships of relationships)
    # @param metadata [Hash] Additional metadata to include in the schema, usually received from the nested_relationships method sent by the response_schema method.
    #
    # @example
    # The returned schema will have a JSON API format, including the data (included attributes and relationships), included and meta keys.
    #
    # @return [Hash] A hash representing the schema for the response.
    def response_schema(relations = try(:relationships), expand: false, exclude_from_expansion: [], multi: false, nested: false, metadata: { nested_relationships: try(:nested_relationships) })

      data = {
        type: :object,
        properties: {
          type: { type: :string, default: itself.class.model_name },
          id: { type: :string },
          attributes: attributes_schema,
        }.merge(
          if relations.blank? || relations == { belongs_to: {}, has_many: {} }
            {}
          else
            { relationships: relationships_schema(relations, expand: expand, exclude_from_expansion: exclude_from_expansion) }
          end
        )
      }

      schema = if multi
                 {
                   data: {
                     type: :array,
                     items: data
                   }
                 }
               else
                 {
                   data: data
                 }
               end

      schema.merge!(
        if nested && expand
          included_schema(relations, expand: nested, exclude_from_expansion: exclude_from_expansion, metadata: metadata)
        elsif !nested && expand
          included_schema(relations, expand: nested, exclude_from_expansion: exclude_from_expansion)
        else
          {}
        end
      ).merge!(
        if !expand
          { meta: meta }
        else
          {}
        end
      ).merge!(
        jsonapi: jsonapi
      )

      {
        type: :object,
        properties: schema
      }
    end

    # Generates the schema for the request payload of a resource.
    #
    # @note The `additional_request_attributes` and `excluded_request_attributes` applied to the returned schema by this method.
    # @note The `required_attributes` are applied to the returned schema by this method.
    # @note The `nullable_attributes` are applied to the returned schema by this method.
    #
    # @example
    # {
    #     type: :object,
    #     properties: {
    #       data: {
    #         type: :object,
    #         properties: {
    #           firstName: { type: :string },
    #           lastName: { type: :string }
    #         },
    #         required: [:firstName, :lastName]
    #       }
    #     }
    # }
    #
    # @return [Hash] A hash representing the schema for the request payload.
    def request_schema
      schema = {
        type: :object,
        properties: {
          data: attributes_schema
        }
      }

      schema = modify_schema(schema, additional_request_attributes, "properties.data.properties")

      excluded_request_attributes.each do |key|
        schema = modify_schema(schema, {}, "properties.data.properties.#{key}", delete: true)
      end

      required_attributes = {
        required: (schema.as_json['properties']['data']['properties'].keys - optional_request_attributes.map(&:to_s) - nullable_attributes.map(&:to_s)).map { |key| key.to_s.camelize(:lower).to_sym }
      }

      schema = modify_schema(schema, required_attributes, "properties.data")

      schema
    end

    # Returns the schema for the meta data of the response body.
    #
    # This is used to provide pagination information usually (in the case of a collection).
    #
    # Note that this is an opinionated schema and may not be suitable for all use cases.
    # If you need to override this schema, you can do so by overriding the `meta` method in your definition.
    #
    # @return [Hash] The schema for the meta data of the response body.
    def meta
      {
        type: :object,
        properties: {
          page: {
            type: :object,
            properties: {
              totalPages: {
                type: :integer,
                default: 1
              },
              count: {
                type: :integer,
                default: 1
              },
              limitValue: {
                type: :integer,
                default: 1
              },
              currentPage: {
                type: :integer,
                default: 1
              }
            }
          }
        }
      }
    end

    # Returns the schema for the JSONAPI version.
    #
    # @return [Hash] The schema for the JSONAPI version.
    def jsonapi
      {
        type: :object,
        properties: {
          version: {
            type: :string,
            default: "1.0"
          }
        }
      }
    end

    # Returns the resource serializer to be used for serialization. This method must be implemented in the definition class.
    #
    # @raise [NotImplementedError] If the method is not implemented in the definition class.
    #
    # @example V1::UserSerializer
    #
    # @abstract This method must be implemented in the definition class.
    #
    # @return [Class] The resource serializer class.
    def serializer
      raise NotImplementedError, 'serializer method must be implemented in the definition class'
    end

    # Returns the attributes defined in the serializer (Auto generated from the serializer).
    #
    # @example
    # [:id, :name, :email, :created_at, :updated_at]
    #
    # @return [Array<Symbol>, nil] The attributes defined in the serializer or nil if there are none.
    def attributes
      serializer.attribute_blocks.transform_keys { |key| key.to_s.underscore.to_sym }.keys || nil
    end

    # Returns the relationships defined in the serializer.
    #
    # Note that the format of the relationships is as follows: { belongs_to: { relationship_name: relationship_definition }, has_many: { relationship_name: relationship_definition }
    #
    # @example
    # {
    #   belongs_to: {
    #     district: Swagger::Definitions::District,
    #     user: Swagger::Definitions::User
    #   },
    #   has_many: {
    #     applicants: Swagger::Definitions::Applicant,
    #   }
    # }
    #
    # @return [Hash] The relationships defined in the serializer.
    def relationships
      { belongs_to: {}, has_many: {} }
    end

    # Returns a hash of all the arrays defined for the model. The schema for each array is defined in the definition class manually.
    #
    # This method must be implemented in the definition class if there are any arrays.
    #
    # @example
    # {
    #   metadata: {
    #       type: :array,
    #       items: {
    #           type: :object, nullable: true,
    #           properties: { name: { type: :string, nullable: true } }
    #       }
    #   }
    # }
    #
    # @return [Hash] The arrays of the model and their schemas.
    def array_types
      {}
    end

    # Returns the attributes that are optional in the request body. This means that they are not required to be present in the request body thus they are taken out of the required array.
    #
    # @example
    # [:name, :email]
    #
    # @return [Array<Symbol>] The attributes that are optional in the request body.
    def optional_request_attributes
      %i[]
    end

    # Returns the attributes that are nullable in the request/response body. This means that they can be present in the request/response body but they can be null.
    #
    # They are not required to be present in the request body.
    #
    # @example
    # [:name, :email]
    #
    # @return [Array<Symbol>] The attributes that are nullable in the request/response body.
    def nullable_attributes
      %i[]
    end

    # Returns the additional request attributes that are not automatically generated. These attributes are appended to the request schema.
    #
    # @example
    # {
    #  name: { type: :string }
    # }
    #
    # @return [Hash] The additional request attributes that are not automatically generated (if any).
    def additional_request_attributes
      {}
    end

    # Returns the additional response attributes that are not automatically generated. These attributes are appended to the response schema.
    #
    # @example
    # {
    # name: { type: :string }
    # }
    #
    # @return [Hash] The additional response attributes that are not automatically generated (if any).
    def additional_response_attributes
      {}
    end

    # Returns the additional response relations that are not automatically generated. These relations are appended to the response schema's relationships.
    #
    # @example
    # {
    #   users: {
    #     type: :object,
    #     properties: {
    #       data: {
    #         type: :array,
    #         items: {
    #           type: :object,
    #           properties: {
    #             id: { type: :string },
    #             type: { type: :string }
    #           }
    #         }
    #       }
    #     }
    #   }
    # }
    #
    # @return [Hash] The additional response relations that are not automatically generated (if any).
    def additional_response_relations
      {}
    end

    # Returns the additional response included that are not automatically generated. These included are appended to the response schema's included.
    #
    # @example
    # {
    #   type: :object,
    #   properties: {
    #     id: { type: :string },
    #     type: { type: :string },
    #     attributes: {
    #       type: :object,
    #       properties: {
    #         name: { type: :string }
    #       }
    #     }
    #   }
    # }
    #
    # @return [Hash] The additional response included that are not automatically generated (if any).
    def additional_response_included
      {}
    end

    # Returns the attributes that are excluded from the request schema.
    # These attributes are not required or not needed to be present in the request body.
    #
    # @example
    # [:id, :updated_at, :created_at]
    #
    # @return [Array<Symbol>] The attributes that are excluded from the request schema.
    def excluded_request_attributes
      %i[]
    end

    # Returns the attributes that are excluded from the response schema.
    # These attributes are not needed to be present in the response body.
    #
    # @example
    # [:id, :updated_at, :created_at]
    #
    # @return [Array<Symbol>] The attributes that are excluded from the response schema.
    def excluded_response_attributes
      %i[]
    end

    # Returns the relationships that are excluded from the response schema.
    # These relationships are not needed to be present in the response body.
    #
    # @example
    # [:users, :applicants]
    #
    # @return [Array<Symbol>] The relationships that are excluded from the response schema.
    def excluded_response_relations
      %i[]
    end

    # Returns the included that are excluded from the response schema.
    # These included are not needed to be present in the response body.
    #
    # @todo This method is not used anywhere yet.
    #
    # @example
    # [:users, :applicants]
    #
    # @return [Array<Symbol>] The included that are excluded from the response schema.
    def excluded_response_included
      %i[]
    end

    # Returns the relationships to be further expanded in the response schema.
    #
    # @example
    # {
    #   applicants: {
    #     belongs_to: {
    #       district: Swagger::Definitions::District,
    #       province: Swagger::Definitions::Province,
    #     },
    #     has_many: {
    #       attachments: Swagger::Definitions::Upload,
    #     }
    #   }
    # }
    #
    # @return [Hash] The relationships to be further expanded in the response schema.
    def nested_relationships
      {}
    end

    # Returns the model class (Constantized from the definition class name)
    #
    # @example
    # User
    #
    # @return [Class] The model class (Constantized from the definition class name)
    def model
      self.class.name.gsub("Swagger::Definitions::", '').constantize
    end

    # Returns the model name. Used for schema type naming.
    #
    # @example
    # 'users' for the User model
    # 'citizen_applications' for the CitizenApplication model
    #
    # @return [String] The model name.
    def self.model_name
      name.gsub("Swagger::Definitions::", '').pluralize.underscore.downcase
    end

    # Returns the generated schemas in JSONAPI format that are used in the swagger documentation.
    #
    # @note This method is used for generating schema in 3 different formats: request, response and response expanded.
    # request: The schema for the request body.
    # response: The schema for the response body (without any relationships expanded), used for collection responses.
    # response expanded: The schema for the response body with all the relationships expanded, used for single resource responses.
    #
    # @note The returned schemas are in JSONAPI format are usually appended to the rswag component's 'schemas' in swagger_helper.
    #
    # @note The method can be overridden in the definition class if there are any additional customizations needed.
    #
    # @return [Array<Hash>] The generated schemas in JSONAPI format that are used in the swagger documentation.
    def self.definitions
      schema_instance = self.new
      [
        "#{schema_instance.model}Request": schema_instance.camelize_keys(schema_instance.request_schema),
        "#{schema_instance.model}Response": schema_instance.camelize_keys(schema_instance.response_schema(multi: true)),
        "#{schema_instance.model}ResponseExpanded": schema_instance.camelize_keys(schema_instance.response_schema(expand: true))
      ]
    end

    # Given a hash, it returns a new hash with all the keys camelized.
    #
    # @param hash [Array | Hash] The hash with all the keys camelized.
    #
    # @example
    # { first_name: 'John', last_name: 'Doe' } => { firstName: 'John', lastName: 'Doe' }
    #
    # @return [Array | Hash] The hash with all the keys camelized.
    def camelize_keys(hash)
      hash.deep_transform_keys { |key| key.to_s.camelize(:lower).to_sym }
    end
  end
end
