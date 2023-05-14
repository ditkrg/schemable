module Schemable
  class InstallGenerator < Rails::Generators::Base

    source_root File.expand_path('../../templates', __dir__)
    class_option :model_name, type: :string, default: 'Model', desc: 'Name of the model'

    def initialize(*)
      super(*)
    end

    def copy_initializer
      target_path = 'spec/swagger/common_definitions.rb'

      if Rails.root.join(target_path).exist?
        say_status('skipped', 'Common definitions already exists')
      else
        copy_file('common_definitions.rb', target_path)
      end

      target_path = 'app/helpers/serializers_helper.rb'

      if Rails.root.join(target_path).exist?
        say_status('skipped', 'Serializers helper already exists')
      else
        copy_file('serializers_helper.rb', target_path)
      end
    end
  end
end
