module Schemable
  # The Definition class provides a blueprint for generating and modifying schemas.
  # It includes methods for handling attributes, relationships, and various request and response attributes.
  # The definition class is meant to be inherited by a class that represents a model.
  # This class should be configured to match the model's attributes and relationships.
  # The default configuration is set in this class, but can be overridden in the model's definition class.
  #
  # @see Schemable
  class Definition
    attr_reader :configuration
    attr_writer :relationships, :additional_create_request_attributes, :additional_update_request_attributes

    def initialize
      @configuration = Schemable.configuration
    end

    # Returns the serializer of the model for the definition.
    # @example
    #   UsersSerializer
    # @return [JSONAPI::Serializable::Resource, nil] The model's serializer.
    def serializer
      raise NotImplementedError, 'You must implement the serializer method in the definition class in order to use the infer_serializer_from_jsonapi_serializable configuration option.' if configuration.infer_attributes_from_jsonapi_serializable

      nil
    end

    # Returns the attributes for the definition based on the configuration.
    # The attributes are inferred from the model's attribute names by default.
    # If the infer_attributes_from_custom_method configuration option is set, the attributes are inferred from the method specified.
    # If the infer_attributes_from_jsonapi_serializable configuration option is set, the attributes are inferred from the serializer's attribute blocks.
    #
    # @example
    #   attributes = definition.attributes # => [:id, :name, :email]
    #
    # @return [Array<Symbol>] The attributes used for generating the schemas.
    def attributes
      return (serializer&.attribute_blocks&.transform_keys { |key| key.to_s.underscore.to_sym }&.keys || nil) if configuration.infer_attributes_from_jsonapi_serializable

      return model.send(configuration.infer_attributes_from_custom_method).map(&:to_sym) if configuration.infer_attributes_from_custom_method

      model.attribute_names.map(&:to_sym)
    end

    # Returns the relationships defined in the serializer.
    #
    # @note Note that the format of the relationships is as follows:
    #   {
    #      belongs_to: { relationship_name: relationship_definition },
    #      has_many: { relationship_name: relationship_definition },
    #      addition_to_included: { relationship_name: relationship_definition }
    #   }
    #
    # @note The addition_to_included is used to define the extra nested relationships that are not defined in the belongs_to or has_many for included.
    #
    # @example
    #  {
    #    belongs_to: {
    #      district: Swagger::Definitions::District,
    #      user: Swagger::Definitions::User
    #    },
    #    has_many: {
    #      applicants: Swagger::Definitions::Applicant,
    #    },
    #    addition_to_included: {
    #      applicants: Swagger::Definitions::Applicant
    #    }
    #  }
    #
    # @return [Hash] The relationships defined in the serializer.
    def relationships
      { belongs_to: {}, has_many: {} }
    end

    # Returns a hash of all the arrays defined for the model.
    # The schema for each array is defined in the definition class manually.
    # This method must be implemented in the definition class if there are any arrays.
    #
    # @return [Hash] The arrays of the model and their schemas.
    #
    # @example
    #  {
    #    metadata: {
    #        type: :array,
    #        items: {
    #            type: :object, nullable: true,
    #            properties: { name: { type: :string, nullable: true } }
    #        }
    #    }
    #  }
    def array_types
      {}
    end

    # Attributes that are not required in the create request.
    #
    # @example
    #   optional_create_request_attributes = definition.optional_create_request_attributes
    #   # => [:email]
    #
    # @return [Array<Symbol>] The attributes that are not required in the create request.
    def optional_create_request_attributes
      %i[]
    end

    # Attributes that are not required in the update request.
    #
    # @example
    #   optional_update_request_attributes = definition.optional_update_request_attributes
    #   # => [:email]
    #
    # @return [Array<Symbol>] The attributes that are not required in the update request.
    def optional_update_request_attributes
      %i[]
    end

    # Returns the attributes that are nullable in the request/response body.
    # This means that they can be present in the request/response body but they can be null.
    # They are not required to be present in the request body.
    #
    # @example
    #  [:name, :email]
    #
    # @return [Array<Symbol>] The attributes that are nullable in the request/response body.
    def nullable_attributes
      %i[]
    end

    # Returns the additional create request attributes that are not automatically generated.
    # These attributes are appended to the create request schema.
    #
    # @example
    #  { name: { type: :string } }
    #
    # @return [Hash] The additional create request attributes that are not automatically generated (if any).
    def additional_create_request_attributes
      {}
    end

    # Returns the additional update request attributes that are not automatically generated.
    # These attributes are appended to the update request schema.
    #
    # @example
    #  { name: { type: :string } }
    #
    # @return [Hash] The additional update request attributes that are not automatically generated (if any).
    def additional_update_request_attributes
      {}
    end

    # Returns the additional response attributes that are not automatically generated. These attributes are appended to the response schema.
    #
    # @example
    #  { name: { type: :string } }
    #
    # @return [Hash] The additional response attributes that are not automatically generated (if any).
    def additional_response_attributes
      {}
    end

    # Returns the additional response relations that are not automatically generated.
    # These relations are appended to the response schema's relationships.
    #
    # @example
    #  {
    #    users: {
    #      type: :object,
    #      properties: {
    #        data: {
    #          type: :array,
    #          items: {
    #            type: :object,
    #            properties: {
    #              id: { type: :string },
    #              type: { type: :string }
    #            }
    #          }
    #        }
    #      }
    #    }
    #  }
    #
    # @return [Hash] The additional response relations that are not automatically generated (if any).
    def additional_response_relations
      {}
    end

    # Returns the additional response included that are not automatically generated.
    # These included additions are appended to the response schema's included.
    #
    # @example
    #  {
    #    type: :object,
    #    properties: {
    #      id: { type: :string },
    #      type: { type: :string },
    #      attributes: {
    #        type: :object,
    #        properties: {
    #          name: { type: :string }
    #        }
    #      }
    #    }
    #  }
    #
    # @return [Hash] The additional response included that are not automatically generated (if any).
    def additional_response_included
      {}
    end

    # Returns the attributes that are excluded from the create request schema.
    # These attributes are not required or not needed to be present in the create request body.
    #
    # @example
    #  [:id, :updated_at, :created_at]
    #
    # @return [Array<Symbol>] The attributes that are excluded from the create request schema.
    def excluded_create_request_attributes
      %i[]
    end

    # Returns the attributes that are excluded from the response schema.
    # These attributes are not needed to be present in the response body.
    #
    # @example
    #  [:id, :updated_at, :created_at]
    #
    # @return [Array<Symbol>] The attributes that are excluded from the response schema.
    def excluded_update_request_attributes
      %i[]
    end

    # Returns the attributes that are excluded from the update request schema.
    # These attributes are not required or not needed to be present in the update request body.
    #
    # @example
    #  [:id, :updated_at, :created_at]
    #
    # @return [Array<Symbol>] The attributes that are excluded from the update request schema.
    def excluded_response_attributes
      %i[]
    end

    # Returns the relationships that are excluded from the response schema.
    # These relationships are not needed to be present in the response body.
    #
    # @example
    #  [:users, :applicants]
    #
    # @return [Array<Symbol>] The relationships that are excluded from the response schema.
    def excluded_response_relations
      %i[]
    end

    # Returns the included that are excluded from the response schema.
    # These included are not needed to be present in the response body.
    #
    # @example
    #  [:users, :applicants]
    #
    # @todo
    #  This method is not used anywhere yet.
    #
    # @return [Array<Symbol>] The included that are excluded from the response schema.
    def excluded_response_included
      %i[]
    end

    # Returns an instance of the model class that is already serialized into jsonapi format.
    #
    # @return [Hash] The serialized instance of the model class.
    def serialized_instance
      {}
    end

    # Returns the model class (Constantized from the definition class name)
    #
    # @example
    #  User
    #
    # @return [Class] The model class (Constantized from the definition class name)
    def model
      self.class.name.gsub('Swagger::Definitions::', '').constantize
    end

    # Returns the model name. Used for schema type naming.
    #
    # @return [String] The model name.
    #
    # @example
    #  'users' for the User model
    #  'citizen_applications' for the CitizenApplication model
    def model_name
      self.class.name.gsub('Swagger::Definitions::', '').pluralize.underscore.downcase
    end

    # Given a hash, it returns a new hash with all the keys camelized.
    #
    # @param hash [Hash] The hash with all the keys camelized.
    #
    # @return [Hash, Array] The hash with all the keys camelized.
    #
    # @example
    #  { first_name: 'John', last_name: 'Doe' } => { firstName: 'John', lastName: 'Doe' }
    def camelize_keys(hash)
      hash.deep_transform_keys { |key| key.to_s.camelize(:lower).to_sym }
    end

    # Returns the schema for the create request body, update request body, and response body.
    #
    # @return [Array<Hash>] The schema for the create request body, update request body, and response body.
    def self.generate
      instance = new

      [
        "#{instance.model}CreateRequest": instance.camelize_keys(RequestSchemaGenerator.new(instance).generate_for_create),
        "#{instance.model}UpdateRequest": instance.camelize_keys(RequestSchemaGenerator.new(instance).generate_for_update),
        "#{instance.model}Response": instance.camelize_keys(ResponseSchemaGenerator.new(instance).generate(collection: true)),
        "#{instance.model}ResponseExpanded": instance.camelize_keys(ResponseSchemaGenerator.new(instance).generate(expand: true))
      ]
    end
  end
end
