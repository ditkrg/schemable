module Schemable
  # The IncludedSchemaGenerator class is responsible for generating the 'included' part of a JSON:API compliant response.
  # This class generates schemas for related resources that should be included in the response.
  #
  # @see Schemable
  class IncludedSchemaGenerator
    attr_reader :model_definition, :schema_modifier, :relationships

    # Initializes a new IncludedSchemaGenerator instance.
    #
    # @param model_definition [ModelDefinition] The model definition to generate the schema for.
    #
    # @example
    #   generator = IncludedSchemaGenerator.new(model_definition)
    def initialize(model_definition)
      @model_definition = model_definition
      @schema_modifier = SchemaModifier.new
      @relationships = @model_definition.relationships
    end

    # Generates the 'included' part of the JSON:API response.
    # It iterates over each relationship type (belongs_to, has_many) and for each relationship,
    # it prepares a schema. If the 'expand' option is true, it also includes the relationships of the related resource in the schema.
    # In that case, the 'addition_to_included' relationships are also included in the schema unless they are excluded from expansion.
    #
    # @param expand [Boolean] Whether to include the relationships of the related resource in the schema.
    # @param relationships_to_exclude_from_expansion [Array] The relationships to exclude from the schema.
    #
    # @note Make sure to provide the names correctly in string format and pluralize them if necessary.
    #       For example, if you have a relationship named 'applicant', and an applicant has association
    #       named 'identity', you should provide 'identities' as the names of the relationship to exclude from expansion.
    #       In this case, the included schema of the applicant will not include the identity relationship.
    #
    # @example
    #   schema = generator.generate(expand: true, relationships_to_exclude_from_expansion: ['some_relationship'])
    #
    # @return [Hash] The generated schema.
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

    # Prepares the schema for a related resource to be included in the response.
    # It generates the attribute and relationship schemas for the related resource and combines them into a single schema.
    #
    # @param model_definition [ModelDefinition] The model definition of the related resource.
    # @param expand [Boolean] Whether to include the relationships of the related resource in the schema.
    # @param relationships_to_exclude_from_expansion [Array] The relationships to exclude from the schema.
    #
    # @example
    #   included_schema = generator.prepare_schema_for_included(related_model_definition, expand: true, relationships_to_exclude_from_expansion: ['some_relationship'])
    #
    # @return [Hash] The generated schema for the related resource.
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
