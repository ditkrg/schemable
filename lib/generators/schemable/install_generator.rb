module Schemable
  class InstallGenerator < Rails::Generators::Base
    source_root File.expand_path('../../templates', __dir__)

    def initialize(*args)
      super(*args)
    end

    def copy_initializer
      target_path = 'config/initializers/schemable.rb'

      if Rails.root.join(target_path).exist?
        say_status('skipped', 'Schemable initializer already exists')
      else
        copy_file('schemable.rb', target_path)
      end
    end
  end
end
