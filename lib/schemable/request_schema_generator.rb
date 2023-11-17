module Schemable
  # The RequestSchemaGenerator class is responsible for generating JSON schemas for create and update requests.
  # This class generates schemas based on the model definition, including additional and excluded attributes.
  #
  # @see Schemable
  class RequestSchemaGenerator
    attr_reader :model_definition, :schema_modifier

    # Initializes a new RequestSchemaGenerator instance.
    #
    # @param model_definition [ModelDefinition] The model definition to generate the schema for.
    #
    # @example
    #   generator = RequestSchemaGenerator.new(model_definition)
    def initialize(model_definition)
      @model_definition = model_definition
      @schema_modifier = SchemaModifier.new
    end

    # Generates the JSON schema for a create request.
    # It generates a schema for the model attributes and then modifies it based on the additional and excluded attributes for create requests.
    # It also determines the required attributes based on the optional and nullable attributes.
    # Note that it is presumed that the model is using the same fields/columns for create as well as responses.
    #
    # @example
    #   schema = generator.generate_for_create
    #
    # @return [Hash] The generated schema for create requests.
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

    # Generates the JSON schema for a update request.
    # It generates a schema for the model attributes and then modifies it based on the additional and excluded attributes for update requests.
    # It also determines the required attributes based on the optional and nullable attributes.
    # Note that it is presumed that the model is using the same fields/columns for update as well as responses.
    #
    # @example
    #   schema = generator.generate_for_update
    #
    # @return [Hash] The generated schema for update requests.
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
