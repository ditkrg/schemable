module Schemable
  module Constants
    TYPES_MAP = {
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
        type: (configs[:float_as_string] ? :string : :number).to_s.to_sym,
        format: :float
      },
      decimal: {
        type: (configs[:decimal_as_string] ? :string : :number).to_s.to_sym,
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
    }.freeze
  end
end
