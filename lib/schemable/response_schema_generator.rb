module Schemable
  # The ResponseSchemaGenerator class is responsible for generating JSON schemas for responses.
  # This class generates schemas based on the model definition, including attributes, relationships, and included resources.
  #
  # @see Schemable
  class ResponseSchemaGenerator
    attr_reader :model_definition, :model, :schema_modifier, :configuration

    # Initializes a new ResponseSchemaGenerator instance.
    #
    # @param model_definition [ModelDefinition] The model definition to generate the schema for.
    #
    # @example
    #   generator = ResponseSchemaGenerator.new(model_definition)
    def initialize(model_definition)
      @model_definition = model_definition
      @model = model_definition.model
      @schema_modifier = SchemaModifier.new
      @configuration = Schemable.configuration
    end

    # Generates the JSON schema for a response.
    # It generates a schema for the model attributes and relationships, and if the 'expand' option is true,
    # it also includes the included resources in the schema.
    # It also adds meta and jsonapi information to the schema.
    #
    # @param expand [Boolean] Whether to include the included resources in the schema.
    # @param relationships_to_exclude_from_expansion [Array] The relationships to exclude from expansion in the schema.
    # @param collection [Boolean] Whether the response is for a collection of resources.
    # @param expand_nested [Boolean] Whether to include the nested relationships in the schema.
    #
    # @example
    #   schema = generator.generate(expand: true, relationships_to_exclude_from_expansion: ['some_relationship'], collection: true, expand_nested: true)
    #
    # @return [Hash] The generated schema.
    def generate(expand: false, relationships_to_exclude_from_expansion: [], collection: false, expand_nested: false)
      # Override expand_nested if infer_expand_nested_from_expand is true
      expand_nested = expand if @configuration.infer_expand_nested_from_expand

      data = {
        type: :object,
        properties: {
          type: { type: :string, default: @model_definition.model_name },
          id: { type: :string },
          attributes: AttributeSchemaGenerator.new(@model_definition).generate
        }.merge(
          if @model_definition.relationships.blank? || @model_definition.relationships == { belongs_to: {}, has_many: {} }
            {}
          else
            { relationships: RelationshipSchemaGenerator.new(@model_definition).generate(expand:, relationships_to_exclude_from_expansion:) }
          end
        )
      }

      schema = collection ? { data: { type: :array, items: data } } : { data: }

      if expand
        included_schema = IncludedSchemaGenerator.new(@model_definition).generate(expand: expand_nested, relationships_to_exclude_from_expansion:)
        @schema_modifier.add_properties(schema, included_schema, '.')
      end

      @schema_modifier.add_properties(schema, { meta: }, '.') if collection
      @schema_modifier.add_properties(schema, { jsonapi: }, '.')

      { type: :object, properties: schema }.compact_blank
    end

    # Generates the JSON schema for the 'meta' part of a response.
    # It returns a custom meta response schema if one is defined in the configuration, otherwise it generates a default meta schema.
    #
    # @example
    #   meta_schema = generator.meta
    #
    # @return [Hash] The generated schema for the 'meta' part of a response.
    def meta
      return @configuration.custom_meta_response_schema if @configuration.custom_meta_response_schema.present?

      if @configuration.pagination_enabled
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
                rowsPerPage: {
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
      else
        {}
      end
    end

    # Generates the JSON schema for the 'jsonapi' part of a response.
    #
    # @example
    #   jsonapi_schema = generator.jsonapi
    #
    # @return [Hash] The generated schema for the 'jsonapi' part of a response.
    def jsonapi
      {
        type: :object,
        properties: {
          version: {
            type: :string,
            default: '1.0'
          }
        }
      }
    end
  end
end
