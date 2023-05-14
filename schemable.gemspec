# frozen_string_literal: true

require_relative "lib/schemable/version"

Gem::Specification.new do |spec|
  spec.name = "schemable"
  spec.version = Schemable::VERSION
  spec.authors = ["Muhammad Nawzad"]
  spec.email = ["hama127n@gmail.com"]

  spec.summary = "An opiniated Gem for Rails applications to auto generate schema in JSONAPI format."
  spec.description = "The schemable gem is an opiniated Gem for Rails applications to auto generate schema for models in JSONAPI format. It is designed to work with rswag's swagger documentation since it can generate the schemas for it."
  spec.homepage = "https://github.com/muhammadnawzad/schemable"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.2"

  spec.metadata["allowed_push_host"] = 'https://rubygems.org'

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = 'https://github.com/muhammadnawzad/schemable'
  spec.metadata["changelog_uri"] = 'https://github.com/muhammadnawzad/schemable/blob/main/CHANGELOG.md'


  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) || f.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "jsonapi-rails", ">= 0.4.1"
  spec.add_dependency "factory_bot_rails", ">= 6.2.0"

  spec.metadata['rubygems_mfa_required'] = 'true'
end
