module Schemable
  class Configuration
    attr_accessor(
      :orm,
      :timestamps,
      :float_as_string,
      :decimal_as_string,
      :custom_type_mappers,
      :disable_factory_bot,
      :use_serialized_instance,
      :custom_defined_enum_method,
      :infer_attributes_from_custom_method,
      :infer_attributes_from_jsonapi_serializable
    )

    def initialize
      @timestamps = true
      @orm = :active_record # orm options are :active_record, :mongoid
      @float_as_string = false
      @custom_type_mappers = {}
      @decimal_as_string = false
      @disable_factory_bot = true
      @use_serialized_instance = false
      @custom_defined_enum_method = nil
      @infer_attributes_from_custom_method = nil
      @infer_attributes_from_jsonapi_serializable = false
    end

    def type_mapper(type_name)
      return @custom_type_mappers[type_name] if @custom_type_mappers.key?(type_name)

      {
        text: { type: :string },
        string: { type: :string },
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
      }[type_name.try(:to_sym)]
    end

    def add_custom_type_mapper(type_name, mapping)
      custom_type_mappers[type_name.to_sym] = mapping
    end
  end
end
