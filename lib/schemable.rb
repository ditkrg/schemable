# frozen_string_literal: true

require_relative 'schemable/version'
require_relative 'schemable/definition'
require_relative 'schemable/configuration'
require_relative 'schemable/schema_modifier'
require_relative 'schemable/attribute_schema_generator'
require_relative 'schemable/response_schema_generator'
require_relative 'schemable/relationship_schema_generator'
require_relative 'schemable/included_schema_generator'

module Schemable
  class Error < StandardError; end

  class << self
    attr_accessor :configuration

    def configure
      @configuration ||= Configuration.new
      yield(@configuration) if block_given?
    end

    def generate_schemas
      klasses = Schemable::Definition.descendants
      generated_schemas = []

      klasses.each do |klass|
        model_definition = klass.new
        schema = AttributeSchemaGenerator.new(model_definition).generate
        generated_schemas << schema
      end

      generated_schemas
    end
  end
end
