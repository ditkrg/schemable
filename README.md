# Schemable

The Schemable gem provides a simple way to define a schema for a Rails model in [JSONAPI](https://jsonapi.org/) format. It can automatically generate a schema for a model based on the model's attributes. It is also highly customizable, allowing you to modify the schema to your liking by overriding configuration options and methods.

This gem is preferably to be used with [RSwag](https://github.com/rswag/rswag) gem to generate the swagger documentation for your API.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'schemable'
```

And then execute:

    bundle install

Or install it yourself as:

    gem install schemable

## Usage

The installation command above will install the Schemable gem and its dependencies. However, in order for Schemable to work, you must also implement your own logic to use the generated schemas to feed it to RSwag.

The below command is to initialize the gem and generate the configuration file.

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

The Schemable gem provides a number of configuration options that can be used to customize the behavior of the gem. The following is a list of the configuration options that are available.

Please note that the configurations options below are defined in the `Schemable` module of the gem. To configure the gem, simply override the default values in the `config/initializers/schemable.rb` file. Also the changes will affect all the definition classes globally.

---

| Option Name                                  | Description                                                                                                                                                                                                                                                                                                | Default Value |
| -------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------- |
| `orm`                                        | The ORM that is used in the application. The options are `:active_record` and `:mongoid`.                                                                                                                                                                                                                  | `true`        |
| `float_as_string`                            | Whether or not to convert the `float` type to a `string` type in the schema.                                                                                                                                                                                                                               | `false`       |
| `decimal_as_string`                          | Whether or not to convert the `decimal` type to a `string` type in the schema.                                                                                                                                                                                                                             | `false`       |
| `custom_type_mappers`                        | A hash of custom type mappers that can be used to override the default type mappers. A specific method should be used, see [Annex 1.0 - Add custom type mapper](#annex-10---add-custom-type-mapper) for more information.                                                                                  | `{}`          |
| `use_serialized_instance`                    | Whether or not to use the serialized instance in the process of schema generation as type fallback for virtual attributes. See [Annex 1.1 - Use serialized instance](#annex-11---use-serialized-instance) for more information.                                                                            | `false`       |
| `custom_defined_enum_method`                 | The name of the method that is used to get the enum keys and values. This allows applications with the orm `mongoid` define a method that mimicks what `defined_enums` does in `activerecord`. Please see [Annex 1.2 - Custom defined enum method](#annex-12---custom-defined-enum-method) for an example. | `nil`         |
| `enum_prefix_for_simple_enum`                | The prefix to be used for the enum values when `mongoid` is used.                                                                                                                                                                                                                                          | `nil`         |
| `enum_suffix_for_simple_enum`                | The suffix to be used for the enum values when `mongoid` is used.                                                                                                                                                                                                                                          | `nil`         |
| `infer_attributes_from_custom_method`        | The name of the custom method that is used to get the attributes to be generated in the schema. See [Annex 1.3 - Infer attributes from custom method](#annex-13---infer-attributes-from-custom-method) for more information.                                                                               | `nil`         |
| `infer_attributes_from_jsonapi_serializable` | Whether or not to infer the attributes from the `JSONAPI::Serializable::Resource` class. See the previous example [Annex 1.1 - Use serialized instance](#annex-11---use-serialized-instance) for more information.                                                                                         | `false`       |
| `custom_meta_response_schema`                | A hash of custom meta response schema that can be used to override the default meta response schema. See [Annex 1.4 - Custom meta response schema](#annex-14---custom-meta-response-schema) for more information.                                                                                          | `nil`         |
| `pagination_enabled`                         | Enable pagination schema generation in the `meta` section of the response schema.                                                                                                                                                                                                                          | `true`        |

---

### Customizing the Schema

The Schemable gem provides a number of methods that can be used to customize the schema. These methods are defined in the `Schemable::Definition` class of the gem. To customize the schema for a specific model, simply override the default methods in the `Schemable::Definition` class for the model.

Please read the method inline documentation before overriding to avoid any unexpected behavior.

The following is a list of the methods that can be overridden. (See the example in [Annex 1.5 - Highly Customized Definition](#annex-15---highly-customized-definition) for a highly customized definition file.)

---

| Method Name                            | Description                                                                                                                                            |
| -------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `serializer`                           | Returns the serializer of the model for the definition.                                                                                                |
| `attributes`                           | Returns the attributes for the definition based on the configuration.                                                                                  |
| `relationships`                        | Returns the relationships defined in the model.                                                                                                        |
| `array_types`                          | Returns a hash of all the arrays defined for the model.                                                                                                |
| `optional_create_request_attributes`   | Returns the attributes that are not required in the create request.                                                                                    |
| `optional_update_request_attributes`   | Returns the attributes that are not required in the update request.                                                                                    |
| `nullable_attributes`                  | Returns the attributes that are nullable in the request/response body.                                                                                 |
| `nullable_relationships`               | Returns the relationships that are nullable in the response body.                                                                                      |
| `additional_create_request_attributes` | Returns the additional create request attributes that are not automatically generated.                                                                 |
| `additional_update_request_attributes` | Returns the additional update request attributes that are not automatically generated.                                                                 |
| `additional_response_attributes`       | Returns the additional response attributes that are not automatically generated.                                                                       |
| `additional_response_relations`        | Returns the additional response relations that are not automatically generated.                                                                        |
| `additional_response_included`         | Returns the additional response included that are not automatically generated.                                                                         |
| `excluded_create_request_attributes`   | Returns the attributes that are excluded from the create request schema.                                                                               |
| `excluded_update_request_attributes`   | Returns the attributes that are excluded from the update request schema.                                                                               |
| `default_value_for_enum_attributes`    | Returns the default value for the enum attributes. Used when you want a custom value for the default enum. By default the first key is used as default |
| `excluded_response_attributes`         | Returns the attributes that are excluded from the response schema.                                                                                     |
| `excluded_response_relations`          | Returns the relationships that are excluded from the response schema.                                                                                  |
| `excluded_response_included`           | Returns the included that are excluded from the response schema.                                                                                       |
| `serialized_instance`                  | Returns an instance of the model class that is already serialized into jsonapi format.                                                                 |
| `model`                                | Returns the model class (Constantized from the definition class name).                                                                                 |
| `model_name`                           | Returns the model name. Used for schema type naming.                                                                                                   |
| `camelize_keys`                        | Given a hash, it returns a new hash with all the keys camelized.                                                                                       |
| `generate`                             | Returns the schema for the create request body, update request body, and response body.                                                                |

---

## Examples

The followings are some examples of configuration of the gem to have different behaviors based on the application needs. In the above section, we have already seen how to generate the definition files for the models. The following examples will show how to customize the schema for the models. Also, we will see how to use the generated schema in RSwag to generate the swagger documentation for the API.

### Annex 1.0 - Add custom type mapper

```ruby
# config/initializers/schemable.rb

Schemable.configure do |config|
  config.add_custom_type_mapper(
    :string,
    { type: :text }
  )
end

```

### Annex 1.1 - Use serialized instance

```ruby
# config/initializers/schemable.rb

Schemable.configure do |config|
  config.use_serialized_instance = true
end
```

Then in the definition file, you can override the `serialized_instance` method to return the serialized instance of the model. Let's also assume that we want to use the `JSONAPI::Serializable::Resource` class to serialize the instance.

```ruby
# lib/swagger/definitions/user_application.rb

module Swagger
  module Definitions
    class User < Schemable::Definition
      attr_accessor :instance

      def serializer
        V1::UserSerializer
      end

      def serialized_instance
        @instance ||= JSONAPI::Serializable::Renderer.new.render(
          FactoryBot.create(:user),
          class: { User: serializer },
          include: []
        )
      end
    end
  end
end
```

### Annex 1.2 - Custom defined enum method

Let's assume that we also want to use mongoid in our application. In this case, we need to define a method that mimicks what `defined_enums` does in `activerecord`. Let's assume that we have a model called `User` that has an enum field called `status`. The following is an example of how to define the method:

```ruby
# app/models/user.rb

class User < ApplicationModel
  include Mongoid::Document
  include SimpleEnum::Mongoid

  as_enum :status, active: 0, inactive: 1
end
```

Then in the `ApplicationModel` class, we can define the method as follows:

```ruby
# app/models/application_model.rb

def self.custom_defined_enum(suffix: '_cd', prefix: nil)
  defined_enums = {}
  enum_fields = if prefix
                  fields.select { |k, v| k.to_s.start_with?(prefix) }
                else
                  fields.select { |k, v| k.to_s.end_with?(suffix) }
                end

  enum_fields.each do |k, v|
    enum_name = k.to_s.gsub(prefix || suffix, '')
    enum = send(enum_name.pluralize)

    defined_enums[enum_name] = enum.hash
  end

  defined_enums
end
```

This method will work for all the models that have enum fields. Since Simple Enum gem defines enum fields with the suffix `_cd`, we can use the `suffix` option to get the enum fields. However, if the enum fields are defined with a different suffix, we can use the `prefix` option to get the enum fields.

Now, we need to specify theses options in the configuration file:

```ruby
# config/initializers/schemable.rb

Schemable.configure do |config|
  config.custom_defined_enum_method = :custom_defined_enum
  config.enum_suffix_for_simple_enum = '_cd'
end
```

This will generate the schema for the enum fields in the model as follows:

```ruby
{
  # ...
    status: {
      type: string,
      enum: ['active', 'inactive']
    }
  # ...
}
```

### Annex 1.3 - Infer attributes from custom method

Sometimes, we may want to infer the attributes from a custom method. For example, let's assume that we have a model called `User` that has a method called `base_attributes` that returns an array of attributes. The following is an example of how to define the method:

```ruby
# app/models/user.rb

class User < ApplicationModel
  def self.base_attributes
    %i[
      id
      name
      email
      status
      roles
      created_at
      updated_at
    ]
  end
end
```

Then in the configuration file, we can override the `infer_attributes_from_custom_method` method to return the attributes from the custom method:

```ruby
# config/initializers/schemable.rb

Schemable.configure do |config|
  config.infer_attributes_from_custom_method = :base_attributes
end
```

if we want to use the `base_attributes` method for only the User model, we can override the `attributes` method in the `Schemable::Definition` class as follows:

```ruby
# lib/swagger/definitions/user.rb

module Swagger
  module Definitions
    class User < Schemable::Definition
      def attributes
        model.base_attributes
      end
    end
  end
end
```

### Annex 1.4 - Custom meta response schema

Sometimes, we may want to customize the meta response schema. For example, let's assume that we want to add a `total` attribute to the meta response schema. The following is an example of how to do that:

```ruby
# config/initializers/schemable.rb

Schemable.configure do |config|
  config.custom_meta_response_schema = {
    type: :object,
    properties: {
      total: { type: :integer }
    }
  }
end
```

### Annex 1.5 - Highly Customized Definition

The below is a definition file for a model that has been customized in a way that many of the methods have been overridden. This is just an example of how to customize the schema. You can customize the schema to your liking. The below hypothetical model's logic does not matter. The only thing that matters is the schema customization and being familiar with the methods that can be overridden.

<Summary>
  <Details>
    <Summary>Click to expand</Summary>

```ruby
module Swagger
  module Definitions
    class Order < Schemable::Definition
      def relationships
        @relationships ||= {
          belongs_to: {
            address: Swagger::Definitions::Address.new
          },
          has_many: {
            items: Swagger::Definitions::Item.new
          },
          addition_to_included: {
            store: Swagger::Definitions::Store.new,
            attachments: Swagger::Definitions::Upload.new
          }
        }
      end

      def excluded_create_request_attributes
        create_params = model.create_params.select { |item| item.is_a?(Symbol) }
        model.base_attributes + %i[comment applicable_transitions] - create_params
      end

      def excluded_update_request_attributes
        update_params = model.update_params.select { |item| item.is_a?(Symbol) }
        model.base_attributes + %i[comment applicable_transitions] - update_params
      end

      def additional_create_request_attributes
        @additional_create_request_attributes ||= {
          items_attributes:
            {
              type: :array,
              items: {
                anyOf: [
                  {
                    type: :object,
                    properties: Schemable::RequestSchemaGenerator.new(Swagger::Definitions::Item.new).generate_for_create.as_json['properties']['data']['properties']
                  }
                ]
              }
            }
        }
      end

      def additional_update_request_attributes
        @additional_update_request_attributes ||={
          items_attributes:
            {
              type: :array,
              items: {
                anyOf: [
                  {
                    type: :object,
                    properties:Schemable::RequestSchemaGenerator.new(Swagger::Definitions::Item.new).generate_for_update.as_json['properties']['data']['properties']
                  }
                ]
              }
            }
        }
      end

      def additional_response_attributes
        {
          comment: { type: :object, properties: {}, nullable: true },
          item_status: { type: :string, nullable: true },
          applicable_transitions: {
            type: :array,
            items:
              {
                type: :object, nullable: true,
                properties:
                  {
                    name: { type: :string, nullable: true },
                    metadata: { type: :object, nullable: true }
                  }
              },
            nullable: true
          }
        }
      end

      def nullable_attributes
        %i[contact_number email]
      end

      def optional_create_request_attributes
        %i[contact_number email]
      end

      def optional_update_request_attributes
        %i[contact_number email]
      end

      def self.generate
        schema_instance = new

        [
          "#{schema_instance.model}CreateRequest": schema_instance.camelize_keys(Schemable::RequestSchemaGenerator.new(schema_instance).generate_for_create),
          "#{schema_instance.model}UpdateRequest": schema_instance.camelize_keys(Schemable::RequestSchemaGenerator.new(schema_instance).generate_for_update),
          "#{schema_instance.model}Response": schema_instance.camelize_keys(Schemable::ResponseSchemaGenerator.new(schema_instance).generate(expand: true, collection: true, relationships_to_exclude_from_expansion: %w[addresses stores attachments])),
          "#{schema_instance.model}ResponseExpanded": schema_instance.camelize_keys(Schemable::ResponseSchemaGenerator.new(schema_instance).generate(expand: true))
        ]
      end
    end
  end
end
```

  </Details>
</Summary>

## Contributing

Bug reports and pull requests are welcome on GitHub at <https://github.com/[USERNAME]/schemable>. This project is intended to be a safe, welcoming space for collaboration, and contributors. Please go to issues page to report any bugs or feature requests. If you would like to contribute, please fork the repository and submit a pull request.

To, use the gem locally, clone the repository and run `bundle install` to install dependencies. Then, run `bundle exec rspec` to run the tests.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
