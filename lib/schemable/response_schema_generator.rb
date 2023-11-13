module Schemable
  class ResponseSchemaGenerator
    attr_reader :model_definition, :model, :schema_modifier

    def initialize(model_definition)
      @model_definition = model_definition
      @model = model_definition.model
      @schema_modifier = SchemaModifier.new
    end

    def generate(expand: false, relationships_to_exclude_from_expansion: [], collection: false)
      data = {
        type: :object,
        properties: {
          type: { type: :string, default: @model_definition.model_name },
          id: { type: :string },
          attributes: AttributeSchemaGenerator.new(@model_definition).generate
        }.merge(
          if @model_definition.relationships.blank? || @model_definition.relationships == { belongs_to: {}, has_many: {} }
            {}
          else
            { relationships: RelationshipSchemaGenerator.new(@model_definition).generate(expand:, relationships_to_exclude_from_expansion:) }
          end
        )
      }

      schema = collection ? { data: { type: :array, items: data } } : { data: }

      if expand
        included_schema = IncludedSchemaGenerator.new(@model_definition).generate(expand:, relationships_to_exclude_from_expansion:)
        @schema_modifier.add_properties(schema, included_schema, '.')
      end

      @schema_modifier.add_properties(schema, { meta: }, '.') if collection
      @schema_modifier.add_properties(schema, { jsonapi: }, '.')

      { type: :object, properties: schema }.compact_blank
    end

    def meta
      {
        type: :object,
        properties: {
          page: {
            type: :object,
            properties: {
              totalPages: {
                type: :integer,
                default: 1
              },
              count: {
                type: :integer,
                default: 1
              },
              rowsPerPage: {
                type: :integer,
                default: 1
              },
              currentPage: {
                type: :integer,
                default: 1
              }
            }
          }
        }
      }
    end

    def jsonapi
      {
        type: :object,
        properties: {
          version: {
            type: :string,
            default: '1.0'
          }
        }
      }
    end
  end
end
