require_relative 'schemable/version'
require_relative 'schemable/definition'
require_relative 'schemable/configuration'
require_relative 'schemable/schema_modifier'
require_relative 'schemable/attribute_schema_generator'
require_relative 'schemable/relationship_schema_generator'
require_relative 'schemable/included_schema_generator'
require_relative 'schemable/response_schema_generator'
require_relative 'schemable/request_schema_generator'

# The Schemable module provides a set of classes and methods for generating and modifying schemas in JSONAPI format.
# It includes classes for generating attribute, relationship, included, response, and request schemas.
# It also provides a configuration class for setting up the module's behavior.
#
# @example
# The following example shows how to use the Schemable module to generate a schema for a Comment model.
#
#   # config/initializers/schemable.rb
#   Schemable.configure do |config|
#     #... chosen configuration options ...
#   end
#
#    # lib/swagger/definitions/comment.rb
#   class Swagger::Definitions::Comment < Schemable::Definition; end
#
#    # whenever you need to generate the schema for a Comment model.
#    # i.e. in RSwag's swagger_helper.rb
#
#    #  spec/swagger_helper.rb
#    # ...
#   RSpec.configure do |config|
#
#     config.swagger_docs = {
#       # ...
#       components: {
#         # ...
#         schemas: Swagger::Definitions::Comment.generate.flatten.reduce({}, :merge)
#         # ...
#       }
#       # ...
#     }
#     # ...
#   end
#
# @see Schemable::Definition
# @see Schemable::Configuration
# @see Schemable::SchemaModifier
# @see Schemable::AttributeSchemaGenerator
# @see Schemable::RelationshipSchemaGenerator
# @see Schemable::IncludedSchemaGenerator
# @see Schemable::ResponseSchemaGenerator
# @see Schemable::RequestSchemaGenerator
module Schemable
  # Error class for handling exceptions specific to the Schemable module.
  class Error < StandardError; end

  class << self
    # Accessor for the module's configuration.
    attr_accessor :configuration

    # Configures the module. If a block is given, it yields the current configuration.
    #
    # @yield [Configuration] The current configuration.
    def configure
      @configuration ||= Configuration.new
      yield(@configuration) if block_given?
    end
  end
end
