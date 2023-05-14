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

The installation command above will install the Schemable gem and its dependencies. However, in order for Schemable to work, you must also add the following files to your Rails application:

- `app/helpers/serializers_helper.rb` - This file contains the `serializers_map` helper method, which is used to map a model to its serializer.
- `spec/swagger/common_definitions.rb` - This file contains the `aggregate` method, which is used to aggregate the schemas of all the models in your application into a single place. This file is recommeded, but not required. If you do not use this file, you will need to manually aggregate the schemas of all the models in your application into a single place.

To generate these files, run the following command:

```ruby
rails g schemable:install
```

### Generating Definition Files

The Schemable gem provides a generator that can be used to generate definition files for your models. To generate a definition file for a model, run the following command:

```ruby
rails g schemable:model --model_name <model_name>
```

This will generate a definition file for the specified model in the `lib/swagger/definitions` directory. The definition file will be named `<model_name>.rb`. This file will have the bare minimum code required to generate a schema for the model. You can then modify the definition file to your liking by overriding the default methods. For example, you can add or remove attributes from the schema, or you can add or remove relationships from the schema. You can also add custom attributes to the schema. For more information on how to customize the schema, see the [Customizing the Schema](#customizing-the-schema) section below.

## Customizing the Schema

The Schemable gem provides a number of methods that can be used to customize the schema. These methods are defined in the `Schemable` module of the gem. To customize the schema, simply override the default methods in the definition file for the model. The following is a list of the methods that can be overridden:

| WARNING: please read the method inline documentation before overriding to avoid any unexpected behavior. |
| -------------------------------------------------------------------------------------------------------- |

The list of methods that can be overridden are as follows:

| Method Name                      | Description                                                                                                |
| -------------------------------- | ---------------------------------------------------------------------------------------------------------- |
| `serializer`                     | Returns the serializer class.                                                                              |
| `attributes`                     | Returns the attributes that are auto generated from the model.                                             |
| `relationships`                  | Returns the relationships in the format of { belongs_to: {}, has_many: {} }.                               |
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
| `nested_relationships`           | Returns the relationships to be further expanded in the response schema.                                   |
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

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/schemable. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/schemable/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Schemable project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/schemable/blob/master/CODE_OF_CONDUCT.md).
