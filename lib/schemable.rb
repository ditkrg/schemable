require_relative 'schemable/version'
require_relative 'schemable/definition'
require_relative 'schemable/configuration'
require_relative 'schemable/schema_modifier'
require_relative 'schemable/attribute_schema_generator'
require_relative 'schemable/relationship_schema_generator'
require_relative 'schemable/included_schema_generator'
require_relative 'schemable/response_schema_generator'
require_relative 'schemable/request_schema_generator'

module Schemable
  class Error < StandardError; end

  class << self
    attr_accessor :configuration

    def configure
      @configuration ||= Configuration.new
      yield(@configuration) if block_given?
    end
  end
end
