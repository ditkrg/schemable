# configuration.rb
module Schemable
  class Configuration
    attr_accessor(
      :orm,
      :timestamps,
      :float_as_string,
      :decimal_as_string,
      :custom_type_mappers,
      :disable_factory_bot
    )

    def initialize
      @timestamps = true
      @orm = :active_record # orm options are :active_record, :mongoid
      @float_as_string = false
      @custom_type_mappers = {}
      @decimal_as_string = false
      @disable_factory_bot = true
    end

    def type_mapper(type_name)
      return @custom_type_mappers[type_name] if @custom_type_mappers.key?(type_name)

      TYPES_MAP[type_name.try(:to_sym)]
    end

    def add_custom_type_mapper(type_name, mapping)
      custom_type_mappers[type_name.to_sym] = mapping
    end
  end
end
