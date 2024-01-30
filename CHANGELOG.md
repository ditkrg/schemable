# Changelog
This file is used to list changes made in each version of the Schemable gem.

## Schemable 1.0.3 (2024-01-30)

* Added configuration for preventing expansion for nested relationships. This can be done by setting the `expand_nested` to `true` when  invoking `ResponseSchemaGenerator`'s `generate` instance method (e.g. `ResponseSchemaGenerator.new(instance).generate(expand: true, expand_nested: true)`. Additionally, you could globally set the value of `expand_nested` to the same value as `expand` by setting the configuration `infer_expand_nested_from_expand` to `true` in the `/config/initializers/schemable.rb`.

## Schemable 1.0.2 (2024-01-30)

* Added configuration for making certain associations nullable in the response's relationship. This can be done by adding the name of the relation in the `nullable_relationships` method's array of strings.

## Schemable 1.0.1 (2024-01-29)

* Added configuration for changing the default value of enums. By default first key is used, or alternatively default can be set manually by the method `default_value_for_enum_attributes` from the definition.

## Schemable 1.0.0 (2023-11-17)

* Initial release
