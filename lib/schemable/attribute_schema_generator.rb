module Schemable
  class AttributeSchemaGenerator
    attr_accessor :model_definition, :configuration, :model, :schema_modifier, :response

    def initialize(model_definition)
      @model_definition = model_definition
      @model = model_definition.model
      @configuration = Schemable.configuration
      @schema_modifier = SchemaModifier.new
      @response = nil
    end

    # Generate the JSON schema for attributes
    def generate
      schema = {
        type: :object,
        properties: @model_definition.attributes.index_with do |attr|
          generate_attribute_schema(attr)
        end
      }

      # modify the schema to include additional response relations
      schema = @schema_modifier.add_properties(schema, @model_definition.additional_response_attributes, 'properties')

      # modify the schema to exclude response relations
      @model_definition.excluded_response_attributes.each do |key|
        schema = @schema_modifier.delete_properties(schema, "properties.#{key}")
      end

      schema
    end

    # Generate the JSON schema for a specific attribute
    def generate_attribute_schema(attribute)
      if @configuration.orm == :mongoid
        # Get the column hash for the attribute
        attribute_hash = @model.fields[attribute.to_s]

        # Check if this attribute has a custom JSON Schema definition
        return @model_definition.array_types[attribute] if @model_definition.array_types.keys.include?(attribute)
        return @model_definition.additional_response_attributes[attribute] if @model_definition.additional_response_attributes.keys.include?(attribute)

        # Check if this is an array attribute
        return @configuration.type_mapper(:array) if attribute_hash.try(:[], 'options').try(:[], 'type') == 'Array'

        # Map the column type to a JSON Schema type if none of the above conditions are met
        @response = @configuration.type_mapper(attribute_hash.try(:type).to_s.downcase.to_sym)

      elsif @configuration.orm == :active_record
        # Get the column hash for the attribute
        attribute_hash = @model.columns_hash[attribute.to_s]

        # Check if this attribute has a custom JSON Schema definition
        return @model_definition.array_types[attribute] if @model_definition.array_types.keys.include?(attribute)
        return @model_definition.additional_response_attributes[attribute] if @model_definition.additional_response_attributes.keys.include?(attribute)

        # Check if this is an array attribute
        return @configuration.type_mapper(:array) if attribute_hash.as_json.try(:[], 'sql_type_metadata').try(:[], 'sql_type').include?('[]')

        # Map the column type to a JSON Schema type if none of the above conditions are met
        @response = @configuration.type_mapper(attribute_hash.try(:type))

      else
        raise 'ORM not supported'
      end

      # If the attribute is nullable, modify the schema accordingly
      return @schema_modifier.add_properties(@response, { nullable: true }, '.') if @response && @model_definition.nullable_attributes.include?(attribute)

      # If attribute is an enum, modify the schema accordingly
      if @configuration.custom_defined_enum_method
        return @schema_modifier.add_properties(@response, { enum: @model.send(@configuration.custom_defined_enum_method, attribute.to_s) }, '.') if @response && @model.respond_to?(@configuration.custom_defined_enum_method)
      elsif @model.respond_to?(:defined_enums)
        return @schema_modifier.add_properties(@response, { enum: @model.defined_enums[attribute.to_s].keys }, '.') if @response && @model.defined_enums.key?(attribute.to_s)
      end

      return @response unless @response.nil?

      # If we haven't found a schema type yet, try to infer it from the type of the attribute's value in the instance data
      if @configuration.use_serialized_instance
        serialized_instance = @model_definition.serialized_instance

        type_from_instance = serialized_instance.as_json['data']['attributes'][attribute.to_s.camelize(:lower)]&.class&.name&.downcase

        @response = @configuration.type_mapper(type_from_instance) if type_from_instance.present?

        return @response unless @response.nil?
      end

      # If we still haven't found a schema type, default to object
      @configuration.type_mapper(:object)
    rescue NoMethodError
      # Log a warning if the attribute does not exist on the @model
      Rails.logger.warn("\e[33mWARNING: #{@model} does not have an attribute named \e[31m#{attribute}\e[0m")
      {}
    end
  end
end
