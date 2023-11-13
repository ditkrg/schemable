module Schemable
  class Definition
    attr_reader :configuration
    attr_writer :relationships, :additional_create_request_attributes, :additional_update_request_attributes

    def initialize
      @configuration = Schemable.configuration
    end

    def serializer
      raise NotImplementedError, 'You must implement the serializer method in the definition class in order to use the infer_serializer_from_jsonapi_serializable configuration option.' if configuration.infer_attributes_from_jsonapi_serializable

      nil
    end

    def attributes
      return (serializer&.attribute_blocks&.transform_keys { |key| key.to_s.underscore.to_sym }&.keys || nil) if configuration.infer_attributes_from_jsonapi_serializable

      return model.send(configuration.infer_attributes_from_custom_method).map(&:to_sym) if configuration.infer_attributes_from_custom_method

      model.attribute_names.map(&:to_sym)
    end

    def relationships
      { belongs_to: {}, has_many: {} }
    end

    def array_types
      {}
    end

    def optional_create_request_attributes
      %i[]
    end

    def optional_update_request_attributes
      %i[]
    end

    def nullable_attributes
      %i[]
    end

    def additional_create_request_attributes
      {}
    end

    def additional_update_request_attributes
      {}
    end

    def additional_response_attributes
      {}
    end

    def additional_response_relations
      {}
    end

    def additional_response_included
      {}
    end

    def excluded_create_request_attributes
      %i[]
    end

    def excluded_update_request_attributes
      %i[]
    end

    def excluded_response_attributes
      %i[]
    end

    def excluded_response_relations
      %i[]
    end

    def excluded_response_included
      %i[]
    end

    def nested_relationships
      {}
    end

    def serialized_instance
      {}
    end

    def model
      self.class.name.gsub('Swagger::Definitions::', '').constantize
    end

    def model_name
      self.class.name.gsub('Swagger::Definitions::', '').pluralize.underscore.downcase
    end

    def camelize_keys(hash)
      hash.deep_transform_keys { |key| key.to_s.camelize(:lower).to_sym }
    end

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
