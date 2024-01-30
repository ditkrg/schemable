module Schemable
  class ModelGenerator < Rails::Generators::Base

    source_root File.expand_path('../../templates', __dir__)
    class_option :model_name, type: :string, default: 'Model', desc: 'Name of the model'

    def initialize(*args)
      super(*args)

      @model_name = options[:model_name]
      @model_name != 'Model' || raise('Model name is required')
    end

    def copy_initializer
      target_path = "lib/swagger/definitions/#{@model_name.underscore.downcase.singularize}.rb"

      if Rails.root.join(target_path).exist?
        say_status('skipped', 'Model definition already exists')
      else

        create_file(target_path, <<-FILE
module Swagger
  module Definitions
    class #{@model_name.classify} < Schemable::Definition
      def excluded_create_request_attributes
        %i[updated_at created_at]
      end

      def excluded_update_request_attributes
        %i[updated_at created_at]
      end
    end
  end
end
FILE
        )
      end
    end
  end
end
