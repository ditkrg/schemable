module Schemable
  class RelationshipSchemaGenerator
    attr_reader :model_definition, :schema_modifier, :relationships

    def initialize(model_definition)
      @model_definition = model_definition
      @schema_modifier = SchemaModifier.new
      @relationships = model_definition.relationships
    end

    def generate(relationships_to_exclude_from_expansion: [], expand: false)
      return {} if @relationships.blank? || @relationships == { belongs_to: {}, has_many: {} }

      schema = {
        type: :object,
        properties: {}
      }

      %i[belongs_to has_many].each do |relation_type|
        @relationships[relation_type]&.each do |relation, definition|
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

          result = relation_type == :belongs_to ? generate_schema(definition.model_name) : generate_schema(definition.model_name, collection: true)

          result = non_expanded_data_properties if !expand || relationships_to_exclude_from_expansion.include?(definition.model_name)

          schema[:properties].merge!(relation => result)
        end
      end

      # Modify the schema to include additional response relations
      schema = @schema_modifier.add_properties(schema, @model_definition.additional_response_relations, 'properties')

      # Modify the schema to exclude response relations
      @model_definition.excluded_response_relations.each do |key|
        schema = @schema_modifier.delete_properties(schema, "properties.#{key}")
      end

      schema
    end

    def generate_schema(type_name, collection: false)
      if collection
        {
          type: :object,
          properties: {
            data: {
              type: :array,
              items: {
                type: :object,
                properties: {
                  id: { type: :string },
                  type: { type: :string, default: type_name }
                }
              }
            }
          }
        }
      else
        {
          type: :object,
          properties: {
            data: {
              type: :object,
              properties: {
                id: { type: :string },
                type: { type: :string, default: type_name }
              }
            }
          }
        }
      end
    end
  end
end
