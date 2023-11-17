module Schemable
  # The RelationshipSchemaGenerator class is responsible for generating the 'relationships' part of a JSON:API compliant response.
  # This class generates schemas for each relationship of a model, including 'belongs_to' (and has_many) and 'has_many' relationships.
  #
  # @see Schemable
  class RelationshipSchemaGenerator
    attr_reader :model_definition, :schema_modifier, :relationships

    # Initializes a new RelationshipSchemaGenerator instance.
    #
    # @param model_definition [ModelDefinition] The model definition to generate the schema for.
    #
    # @example
    #   generator = RelationshipSchemaGenerator.new(model_definition)
    def initialize(model_definition)
      @model_definition = model_definition
      @schema_modifier = SchemaModifier.new
      @relationships = model_definition.relationships
    end

    # Generates the 'relationships' part of the JSON:API response.
    # It iterates over each relationship type (belongs_to, has_many) and for each relationship,
    # it prepares a schema unless the relationship is excluded from expansion.
    # If the 'expand' option is true, it changes the schema to include type and id properties inside the 'meta' property.
    #
    # @param relationships_to_exclude_from_expansion [Array] The relationships to exclude from expansion.
    # @param expand [Boolean] Whether to include the relationships of the related resource in the schema.
    #
    # @example
    #   schema = generator.generate(expand: true, relationships_to_exclude_from_expansion: [:some_relationship])
    #
    # @return [Hash] The generated schema.
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

    # Generates the schema for a specific relationship.
    # If the 'collection' option is true, it generates a schema for a 'has_many' relationship,
    # otherwise it generates a schema for a 'belongs_to' relationship. The difference between the two is that
    # 'data' is an array in the 'has_many' relationship and an object in the 'belongs_to' relationship.
    #
    # @param type_name [String] The type of the related resource.
    # @param collection [Boolean] Whether the relationship is a 'has_many' relationship.
    #
    # @example
    #   relationship_schema = generator.generate_schema('resource_type', collection: true)
    #
    # @return [Hash] The generated schema for the relationship.
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
