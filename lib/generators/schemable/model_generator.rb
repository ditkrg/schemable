module Schemable
  class ModelGenerator < Rails::Generators::Base

    source_root File.expand_path('../../templates', __dir__)
    class_option :model_name, type: :string, default: 'Model', desc: 'Name of the model'

    def initialize(*)
      super(*)

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
    class #{@model_name.classify}

      include Schemable
      include SerializersHelper # This is a helper module that contains a method "serializers_map" that maps models to serializers

      attr_accessor :instance

      def initialize
        @instance ||=  JSONAPI::Serializable::Renderer.new.render(FactoryBot.create(:#{@model_name.underscore.downcase.singularize}), class: serializers_map, include: [])
      end

      def serializer
        V1::#{@model_name.classify}Serializer
      end

      def excluded_request_attributes
        %i[id updatedAt createdAt]
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
