module Schemable
  class RelationshipSchemaGenerator
    attr_accessor :model_definition, :schema_modifier, :configuration, :relationships, :expand, :relationships_to_exclude_from_expansion

    def initialize(model_definition, relationships_to_exclude_from_expansion: [], expand: false)
      @expand = expand
      @model_definition = model_definition
      @schema_modifier = SchemaModifier.new
      @configuration = Schemable.configuration
      @relationships = model_definition.relationships
      @relationships_to_exclude_from_expansion = relationships_to_exclude_from_expansion
    end

    def generate
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

          result = {
            type: :object,
            properties: {
              data: {
                type: :object,
                properties: {
                  id: { type: :string },
                  type: { type: :string, default: definition[:definition].model_name }
                }
              }
            }
          }

          result = non_expanded_data_properties if !expand || @relationships_to_exclude_from_expansion.include?(definition[:definition].model_name)

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
  end
end
