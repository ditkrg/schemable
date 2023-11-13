module Schemable
  class IncludedSchemaGenerator
    attr_reader :model_definition, :schema_modifier, :relationships

    def initialize(model_definition)
      @model_definition = model_definition
      @schema_modifier = SchemaModifier.new
      @relationships = @model_definition.relationships
    end

    def generate(expand: false, relationships_to_exclude_from_expansion: [])
      return {} if @relationships.blank?
      return {} if @relationships == { belongs_to: {}, has_many: {} }

      definitions = []

      %i[belongs_to has_many addition_to_included].each do |relation_type|
        next if @relationships[relation_type].blank?

        definitions << @relationships[relation_type].values
      end

      definitions.flatten!

      included_schemas = definitions.map do |definition|
        next if relationships_to_exclude_from_expansion.include?(definition.model_name)

        if expand
          definition_relations = definition.relationships[:belongs_to].values.map(&:model_name) + definition.relationships[:has_many].values.map(&:model_name)
          relations_to_exclude = []
          definition_relations.each do |relation|
            relations_to_exclude << relation if relationships_to_exclude_from_expansion.include?(relation)
          end

          prepare_schema_for_included(definition, expand:, relationships_to_exclude_from_expansion: relations_to_exclude)
        else
          prepare_schema_for_included(definition)
        end
      end

      schema = {
        included: {
          type: :array,
          items: {
            anyOf: included_schemas.compact_blank
          }
        }
      }

      @schema_modifier.add_properties(schema, @model_definition.additional_response_included, 'included.items') if @model_definition.additional_response_included.present?

      schema
    end

    def prepare_schema_for_included(model_definition, expand: false, relationships_to_exclude_from_expansion: [])
      attributes_schema = AttributeSchemaGenerator.new(model_definition).generate
      relationships_schema = RelationshipSchemaGenerator.new(model_definition).generate(relationships_to_exclude_from_expansion:, expand:)

      {
        type: :object,
        properties: {
          type: { type: :string, default: model_definition.model_name },
          id: { type: :string },
          attributes: attributes_schema
        }.merge!(relationships_schema.blank? ? {} : { relationships: relationships_schema })
      }.compact_blank
    end
  end
end
