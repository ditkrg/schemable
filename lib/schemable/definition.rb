module Schemable
  class Definition
    attr_reader :configuration

    def initialize(configuration)
      @configuration = configuration
    end

    # Returns the resource serializer to be used for serialization. This method must be implemented in the definition class.
    #
    # @abstract This method must be implemented in the definition class.
    #
    # @raise [NotImplementedError] If the method is not implemented in the definition class.
    #
    # @return [Class] The resource serializer class.
    #
    # @example
    #  V1::UserSerializer
    #
    def serializer
      raise NotImplementedError, 'You must implement the serializer method in the definition class in order to use the infer_serializer_from_jsonapi_serializable configuration option.' if configuration.infer_attributes_from_jsonapi_serializable

      nil
    end

    # Returns the attributes defined in the serializer (Auto generated from the serializer).
    #
    # @return [Array<Symbol>, nil] The attributes defined in the serializer or nil if there are none.
    #
    # @example
    #  [:id, :name, :email, :created_at, :updated_at]
    def attributes
      return (serializer&.attribute_blocks&.transform_keys { |key| key.to_s.underscore.to_sym }&.keys || nil) if configuration.infer_attributes_from_jsonapi_serializable

      return model.send(configuration.infer_attributes_from_custom_method).map(&:to_sym) if configuration.infer_attributes_from_custom_method

      model.attribute_names
    end

    # Returns the relationships defined in the serializer.
    #
    # @return [Hash] The relationships defined in the serializer.
    #
    # @note Note that the format of the relationships is as follows:
    #   { belongs_to: { relationship_name: relationship_definition }, has_many: { relationship_name: relationship_definition }
    #
    # @example
    #  {
    #    belongs_to: {
    #      district: Swagger::Definitions::District,
    #      user: Swagger::Definitions::User
    #    },
    #    has_many: {
    #      applicants: Swagger::Definitions::Applicant,
    #    }
    #  }
    def relationships
      { belongs_to: {}, has_many: {} }
    end

    # Returns a hash of all the arrays defined for the model. The schema for each array is defined in the definition class manually.
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

    # Returns the attributes that are optional in the create request body. This means that they are not required to be present in the create request body thus they are taken out of the required array.
    #
    # @return [Array<Symbol>] The attributes that are optional in the create request body.
    #
    # @example
    #  [:name, :email]
    def optional_create_request_attributes
      %i[]
    end

    # Returns the attributes that are optional in the update request body. This means that they are not required to be present in the update request body thus they are taken out of the required array.
    #
    # @return [Array<Symbol>] The attributes that are optional in the update request body.
    #
    # @example
    #  [:name, :email]
    def optional_update_request_attributes
      %i[]
    end

    # Returns the attributes that are nullable in the request/response body. This means that they can be present in the request/response body but they can be null.
    # They are not required to be present in the request body.
    #
    # @return [Array<Symbol>] The attributes that are nullable in the request/response body.
    #
    # @example
    #  [:name, :email]
    def nullable_attributes
      %i[]
    end

    # Returns the additional create request attributes that are not automatically generated. These attributes are appended to the create request schema.
    #
    # @return [Hash] The additional create request attributes that are not automatically generated (if any).
    #
    # @example
    #  {
    #    name: { type: :string }
    #  }
    def additional_create_request_attributes
      {}
    end

    # Returns the additional update request attributes that are not automatically generated. These attributes are appended to the update request schema.
    #
    # @return [Hash] The additional update request attributes that are not automatically generated (if any).
    #
    # @example
    #  {
    #    name: { type: :string }
    #  }
    def additional_update_request_attributes
      {}
    end

    # Returns the additional response attributes that are not automatically generated. These attributes are appended to the response schema.
    #
    # @return [Hash] The additional response attributes that are not automatically generated (if any).
    #
    # @example
    #  {
    #    name: { type: :string }
    #  }
    def additional_response_attributes
      {}
    end

    # Returns the additional response relations that are not automatically generated. These relations are appended to the response schema's relationships.
    #
    # @return [Hash] The additional response relations that are not automatically generated (if any).
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
    def additional_response_relations
      {}
    end

    # Returns the additional response included that are not automatically generated. These included are appended to the response schema's included.
    #
    # @return [Hash] The additional response included that are not automatically generated (if any).
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
    def additional_response_included
      {}
    end

    # Returns the attributes that are excluded from the create request schema.
    # These attributes are not required or not needed to be present in the create request body.
    #
    # @return [Array<Symbol>] The attributes that are excluded from the create request schema.
    #
    # @example
    #  [:id, :updated_at, :created_at]
    def excluded_create_request_attributes
      %i[]
    end

    # Returns the attributes that are excluded from the update request schema.
    # These attributes are not required or not needed to be present in the update request body.
    #
    # @return [Array<Symbol>] The attributes that are excluded from the update request schema.
    #
    # @example
    #  [:id, :updated_at, :created_at]
    def excluded_update_request_attributes
      %i[]
    end

    # Returns the attributes that are excluded from the response schema.
    # These attributes are not needed to be present in the response body.
    #
    # @return [Array<Symbol>] The attributes that are excluded from the response schema.
    #
    # @example
    #  [:id, :updated_at, :created_at]
    def excluded_response_attributes
      %i[]
    end

    # Returns the relationships that are excluded from the response schema.
    # These relationships are not needed to be present in the response body.
    #
    # @return [Array<Symbol>] The relationships that are excluded from the response schema.
    #
    # @example
    #  [:users, :applicants]
    def excluded_response_relations
      %i[]
    end

    # Returns the included that are excluded from the response schema.
    # These included are not needed to be present in the response body.
    #
    # @return [Array<Symbol>] The included that are excluded from the response schema.
    #
    # @example
    #  [:users, :applicants]
    #
    # @todo
    #  This method is not used anywhere yet.
    def excluded_response_included
      %i[]
    end

    # Returns the relationships to be further expanded in the response schema.
    #
    # @return [Hash] The relationships to be further expanded in the response schema.
    #
    # @example
    #  {
    #    applicants: {
    #      belongs_to: {
    #        district: Swagger::Definitions::District,
    #        province: Swagger::Definitions::Province,
    #      },
    #      has_many: {
    #        attachments: Swagger::Definitions::Upload,
    #      }
    #    }
    #  }
    def nested_relationships
      {}
    end

    # Returns the model class (Constantized from the definition class name)
    #
    # @return [Class] The model class (Constantized from the definition class name)
    #
    # @example
    #  User
    def model
      self.class.name.gsub('Swagger::Definitions::', '').constantize
    end

    def serialized_instance
      {}
    end

    # Returns the model name. Used for schema type naming.
    #
    # @return [String] The model name.
    #
    # @example
    #  'users' for the User model
    #  'citizen_applications' for the CitizenApplication model
    def self.model_name
      name.gsub('Swagger::Definitions::', '').pluralize.underscore.downcase
    end
  end
end
