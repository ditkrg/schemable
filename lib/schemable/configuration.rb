module Schemable
  # The Configuration class provides a set of configuration options for the Schemable module.
  # It includes options for setting the ORM, handling enums, custom type mappers, and more.
  # It is worth noting that the configuration options are global, and will affect all Definitions.
  #
  # @see Schemable
  class Configuration
    attr_accessor(
      :orm,
      :float_as_string,
      :decimal_as_string,
      :pagination_enabled,
      :custom_type_mappers,
      :disable_factory_bot,
      :use_serialized_instance,
      :custom_defined_enum_method,
      :enum_prefix_for_simple_enum,
      :enum_suffix_for_simple_enum,
      :custom_meta_response_schema,
      :infer_attributes_from_custom_method,
      :infer_attributes_from_jsonapi_serializable
    )

    # Initializes a new Configuration instance with default values.
    def initialize
      @orm = :active_record # orm options are :active_record, :mongoid
      @float_as_string = false
      @custom_type_mappers = {}
      @pagination_enabled = true
      @decimal_as_string = false
      @disable_factory_bot = true
      @use_serialized_instance = false
      @custom_defined_enum_method = nil
      @custom_meta_response_schema = nil
      @enum_prefix_for_simple_enum = nil
      @enum_suffix_for_simple_enum = nil
      @infer_attributes_from_custom_method = nil
      @infer_attributes_from_jsonapi_serializable = false
    end

    # Returns a type mapper for a given type name.
    #
    # @note If a custom type mapper is defined for the given type name, it will be returned.
    #
    # @example
    #   type_mapper(:string) #=> { type: :string }
    #
    # @param type_name [Symbol, String] The name of the type.
    # @return [Hash] The type mapper for the given type name.
    def type_mapper(type_name)
      return @custom_type_mappers[type_name] if @custom_type_mappers.key?(type_name.to_sym)

      {
        text: { type: :string },
        string: { type: :string },
        symbol: { type: :string },
        integer: { type: :integer },
        boolean: { type: :boolean },
        date: { type: :string, format: :date },
        time: { type: :string, format: :time },
        json: { type: :object, properties: {} },
        hash: { type: :object, properties: {} },
        jsonb: { type: :object, properties: {} },
        object: { type: :object, properties: {} },
        binary: { type: :string, format: :binary },
        trueclass: { type: :boolean, default: true },
        falseclass: { type: :boolean, default: false },
        datetime: { type: :string, format: :'date-time' },
        big_decimal: { type: (@decimal_as_string ? :string : :number).to_s.to_sym, format: :double },
        'bson/objectid': { type: :string, format: :object_id },
        'mongoid/boolean': { type: :boolean },
        'mongoid/stringified_symbol': { type: :string },
        'active_support/time_with_zone': { type: :string, format: :date_time },
        float: {
          type: (@float_as_string ? :string : :number).to_s.to_sym,
          format: :float
        },
        decimal: {
          type: (@decimal_as_string ? :string : :number).to_s.to_sym,
          format: :double
        },
        array: {
          type: :array,
          items: {
            anyOf: [
              { type: :string },
              { type: :integer },
              { type: :boolean },
              { type: :number, format: :float },
              { type: :object, properties: {} },
              { type: :number, format: :double }
            ]
          }
        }
      }[type_name.to_s.underscore.try(:to_sym)]
    end

    # Adds a custom type mapper for a given type name.
    #
    # @example
    #  add_custom_type_mapper(:custom_type, { type: :custom })
    #  type_mapper(:custom_type) #=> { type: :custom }
    #
    #  # It preferable to invoke this method in the config/initializers/schemable.rb file.
    #  # This way, the custom type mapper will be available for all Definitions.
    #  Schemable.configure do |config|
    #   config.add_custom_type_mapper(:custom_type, { type: :custom })
    #  end
    #
    # @param type_name [Symbol, String] The name of the type.
    # @param mapping [Hash] The mapping to add.
    def add_custom_type_mapper(type_name, mapping)
      custom_type_mappers[type_name.to_sym] = mapping
    end
  end
end
