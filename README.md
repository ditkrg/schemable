# Schemable

The Schemable gem provides a simple way to define a schema for a Rails model in [JSONAPI](https://jsonapi.org/) format. It can automatically generate a schema for a model based on the model's factory and the model's attributes. It is also highly customizable, allowing you to modify the schema to your liking by overriding the default methods.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'schemable'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install schemable

## Usage

The installation command above will install the Schemable gem and its dependencies. However, in order for Schemable to work, you must also implement your own logic to use the generated schemas to feed it to RSwag.
 
 -

The below are some command to generate some files to get you started:

```ruby
rails g schemable:install
```

This will generate `schemable.rb` in your `config/initializers` directory. This file will contain the configuration for the Schemable gem. You can modify the configuration to your liking. For more information on the configuration options, see the [Configuration](#configuration) section below.


### Generating Definition Files

The Schemable gem provides a generator that can be used to generate definition files for your models. To generate a definition file for a model, run the following command:

```ruby
rails g schemable:model --model_name <model_name>
```

This will generate a definition file for the specified model in the `lib/swagger/definitions` directory. The definition file will be named `<model_name>.rb`. This file will have the bare minimum code required to generate a schema for the model. You can then modify the definition file to your liking by overriding the default methods. For example, you can add or remove attributes from the schema, or you can add or remove relationships from the schema. You can also add custom attributes to the schema. For more information on how to customize the schema, see the [Customizing the Schema](#customizing-the-schema) section below.


### Configuration
The Schemable gem provides a number of configuration options that can be used to customize the behavior of the gem. The following is a list of the configuration options that are available:

| Option Name | Description                                                                                                                                                                                                                        | Default Value |
| ----------- |------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------| ------------- |
| `orm` | The ORM that is used in the application. The options are `:active_record` and `:mongoid`.                                                                                                                                  | `true` |
| `float_as_string` | Whether or not to convert the `float` type to a `string` type in the schema.                                                                                                                                                       | `false` |
| `decimal_as_string` | Whether or not to convert the `decimal` type to a `string` type in the schema.                                                                                                                                                     | `false` |
| `custom_type_mappers` | A hash of custom type mappers that can be used to override the default type mappers. A specific method should be used, see annex 1.0 for more information.                                                                         | `{}` |
| `disable_factory_bot` | Whether or not to disable the use of FactoryBot in the gem. To automatically generate serialized instance. See annex 1.1 for an example.                                                                                           | `true` |
| `use_serialized_instance` | Whether or not to use the serialized instance in the process of schema geenration as type fallback for virtual attributes.                                                                                                         | `false` |
| `custom_defined_enum_method` | The name of the method that is used to get the enum keys and values. This allows applications with the orm `mongoid` define a method that mimicks what `defined_enums` does in `activerecord. Please see annex 1.2 for an example. | `nil` |
| `enum_prefix_for_simple_enum` | The prefix to be used for the enum values when `mongoid` is used.                                                                                                                                                                  | `nil` |
| `enum_suffix_for_simple_enum` | The suffix to be used for the enum values when `mongoid` is used.                                                                                                                                                                  | `nil` |
| `infer_attributes_from_custom_method` | The name of the custom method that is used to get the attributes to be generated in the schema.                                                                                                                                    | `nil` |
| `infer_attributes_from_jsonapi_serializable` | Whether or not to infer the attributes from the JSONAPI::Serializable::Resource class.                                                                                                                                             | `false` |



### Customizing the Schema

The Schemable gem provides a number of methods that can be used to customize the schema. These methods are defined in the `Schemable` module of the gem. To customize the schema, simply override the default methods in the definition file for the model. The following is a list of the methods that can be overridden:

| WARNING: please read the method inline documentation before overriding to avoid any unexpected behavior. |
| -------------------------------------------------------------------------------------------------------- |

The list of methods that can be overridden are as follows:

| Method Name                      | Description                                                                                                |
|----------------------------------|------------------------------------------------------------------------------------------------------------|
| `serializer`                     | Returns the serializer class. Useful when `infer_attributes_from_jsonapi_serializable` is used             |
| `attributes`                     | Returns the attributes that are auto generated from the model's fields/columns.                            |
| `relationships`                  | Returns the relationships in the format of { belongs_to: {}, has_many: {}, addition_to_included: {} }.     |
| `array_type`                     | Returns the type of arrays in the model that needs to be manually defined.                                 |
| `optional_request_attributes`    | Returns the attributes that are optional in the request schema.                                            |
| `nullable_attributes`            | Returns the attributes that are nullable in the request/response schema.                                   |
| `additional_request_attributes`  | Returns the attributes that are additional in the request schema.                                          |
| `additional_response_attributes` | Returns the attributes that are additional in the response schema.                                         |
| `additional_response_relations`  | Returns the relationships that are additional in the response schema (Appended to relationships).          |
| `additional_response_included`   | Returns the included that are additional in the response schema (Appended to included).                    |
| `excluded_request_attributes`    | Returns the attributes that are excluded from the request schema.                                          |
| `excluded_response_attributes`   | Returns the attributes that are excluded from the response schema.                                         |
| `excluded_response_relations`    | Returns the relationships that are excluded from the response schema.                                      |
| `excluded_response_included`     | (not implemented yet) Returns the included that are excluded from the response schema.                     |
| `serialized_instance`            | Returns a serialized instance of the model, used for type generating as a fallback.                        |
| `model`                          | Returns the model class (Constantized from the definition class name).                                     |
| `model_name`                     | Returns the model name. Used for schema type naming.                                                       |
| `definitions`                    | Returns the generated schemas in JSONAPI format (It is recommended to override this method to your liking) |

The following is an example of a definition file for a model that has been customized:

<Details>
<Summary>Click to view the example</Summary>

```ruby
module Swagger
  module Definitions
    class UserApplication

      include Schemable
      include SerializersHelper

      attr_accessor :instance

      def initialize
        @instance ||= JSONAPI::Serializable::Renderer.new.render(FactoryBot.create(:user, :with_user_application_applicants), class: serializers_map, include: [])
      end

      def serializer
        V1::UserApplicationSerializer
      end

      def relationships
        {
          belongs_to: {
            category: Swagger::Definitions::Category,
          },
          has_many: {
            applicants: Swagger::Definitions::Applicant,
          }
        }
      end

      def array_types
        {
          applicant_ids:
            {
              type: :array,
              items:
                {
                  type: :string
                },
              nullable: true
            }
        }
      end

      def excluded_request_attributes
        %i[id updated_at created_at applicant_ids comment]
      end

      def additional_request_attributes
        {
          applicants_attributes:
            {
              type: :array,
              items: {
                anyOf: [
                  {
                    type: :object,
                    properties: Swagger::Definitions::Applicant.new.request_schema.as_json['properties']['data']['properties']
                  }
                ]
              }
            }
        }
      end

      def additional_response_attributes
        {
          comment: { type: :object, properties: {}, nullable: true }
        }
      end

      def nested_relationships
        {
          applicants: {
            belongs_to: {
              district: Swagger::Definitions::District,
              province: Swagger::Definitions::Province,
            },
            has_many: {
              attachments: Swagger::Definitions::Upload,
            }
          }
        }
      end

      def self.definitions
        schema_instance = self.new
        [
          "#{schema_instance.model}Request": schema_instance.camelize_keys(schema_instance.request_schema),
          "#{schema_instance.model}Response": schema_instance.camelize_keys(schema_instance.response_schema(expand: true, exclude_from_expansion: [:category], multi: true)),
          "#{schema_instance.model}ResponseExpanded": schema_instance.camelize_keys(schema_instance.response_schema(expand: true, nested: true))
        ]
      end
    end
  end
end

```

</Details>

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/schemable. This project is intended to be a safe, welcoming space for collaboration, and contributors. Please go to issues page to report any bugs or feature requests. Open issues are tagged with the `help wanted` label. If you would like to contribute, please fork the repository and submit a pull request.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
