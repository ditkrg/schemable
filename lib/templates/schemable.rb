Schemable.configure do |config|
  # The following options are available for configuration.
  # If you do not specify a configuration option, then its default value will be used.
  # To configure them, uncomment them and set them to the desired value.

  # The ORM options are :active_record, :mongoid
  #
  # config.orm = :active_record

  # The gem uses `{ type: :number, format: :float }` for float attributes by default.
  # If you want to use `{ type: :string }` instead, set this option to true.
  #
  # config.float_as_string = false

  # The gem uses `{ type: :number, format: :decimal }` for decimal attributes by default.
  # If you want to use `{ type: :string }` instead, set this option to true.
  #
  # config.decimal_as_string = false

  # The gem by default sets the pagination_enabled option to true
  # which means in the meta section of the response schema
  # it will add the pagination links and the total count
  # if you don't want to have the pagination links and the total count
  # in the meta section of the response schema, set this option to false
  # If you want to define your own meta schema, you can set the custom_meta_response_schema option
  #
  # config.pagination_enabled = true
  #
  # config.custom_meta_response_schema = nil

  # The gem allows for custom defined schema for a specific type
  # for example if you wish to have all your arrays have the schema
  # { type: :array, items: { type: string } } then use the below method to add to custom_type_mappers
  #
  # config.add_custom_type_mapper(:array, { type: :array, items: { type: string } })

  # If you have a custom enum method defined on all of your model, you can set it here
  # for example if you have a method called `base_attributes` on all of your models
  # and you use that method to return an array of symbols that are the attributes
  # to be serialized then you can set the below to `base_attributes`
  #
  # config.infer_attributes_from_custom_method = nil

  # If you want to recursively expand the relationships in the response schema
  # then set this option to true, otherwise set it to false (default).
  #
  # config.infer_expand_nested_from_expand = true

  # If you want to get the list of attributes from the jsonapi-rails gem's
  # JSONAPI::Serializable::Resource class, set this option to true.
  # It uses the attribute_blocks method to get the list of attributes.
  #
  # config.infer_attributes_from_jsonapi_serializable = false

  # Sometimes you may have virtual attributes that are not in the database
  # Generating the schema for these attributes will fail, in that case you can
  # add your logic to return an instance of the model that is serialized in
  # jsonapi format and the gem will use that to generate the schema
  # this is useful if you use factory_bot and jsonapi-rails to generate the instance
  # check the commented out code in the definition template for an example
  # Set this option to true to enable this feature
  #
  # config.use_serialized_instance = false

  # By default the gem uses activerecord's defined_enums method to get the enums
  # with their keys and values, if you don't have this method defined on your model
  # then please set the below option to the name of the method that returns the
  # enums with their keys and values as a hash. This will handle the auto generation
  # of the enum schema for you, with correct values.
  #
  # config.custom_defined_enum_method = nil

  # If you use mongoid and simple_enum gem, you can set the below options to the prefix and suffix
  # Since simple_enum uses the prefix and suffix to generate the enum methods, and the fields' names
  # are usually the enum name with the prefix and suffix, the gem will remove the prefix and suffix
  # from the field name to get the enum name and then use that to get the enum values
  #
  # config.enum_prefix_for_simple_enum = nil
  #
  # config.enum_suffix_for_simple_enum = nil
end
