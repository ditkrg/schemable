module Schemable
  class RequestSchemaGenerator
    attr_accessor :model_definition, :schema_modifier

    def initialize(model_definition)
      @model_definition = model_definition
      @schema_modifier = SchemaModifier.new
    end

    def generate_for_create
      schema = {
        type: :object,
        properties: {
          data: AttributeSchemaGenerator.new(@model_definition).generate
        }
      }

      @schema_modifier.add_properties(schema, @model_definition.additional_create_request_attributes, 'properties.data.properties')

      @model_definition.excluded_create_request_attributes.each do |key|
        @schema_modifier.delete_properties(schema, "properties.data.properties.#{key}")
      end

      required_attributes = {
        required: (
          schema.as_json['properties']['data']['properties'].keys -
          @model_definition.optional_create_request_attributes.map(&:to_s) -
          @model_definition.nullable_attributes.map(&:to_s)
        ).map { |key| key.to_s.camelize(:lower).to_sym }
      }

      @schema_modifier.add_properties(schema, required_attributes, 'properties.data')
    end

    def generate_for_update
      schema = {
        type: :object,
        properties: {
          data: AttributeSchemaGenerator.new(@model_definition).generate
        }
      }

      @schema_modifier.add_properties(schema, @model_definition.additional_update_request_attributes, 'properties.data.properties')

      @model_definition.excluded_update_request_attributes.each do |key|
        @schema_modifier.delete_properties(schema, "properties.data.properties.#{key}")
      end

      required_attributes = {
        required: (
          schema.as_json['properties']['data']['properties'].keys -
            @model_definition.optional_update_request_attributes.map(&:to_s) -
            @model_definition.nullable_attributes.map(&:to_s)
        ).map { |key| key.to_s.camelize(:lower).to_sym }
      }

      @schema_modifier.add_properties(schema, required_attributes, 'properties.data')
    end
  end
end
