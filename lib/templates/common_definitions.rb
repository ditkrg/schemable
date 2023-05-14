module SwaggerDefinitions
  module CommonDefinitions
    def self.aggregate
      [
        # Import definitions like this:
        # Swagger::Definitions::Model.definitions

        # Make sure in swagger_helper.rb's components section you have:
        # schemas: SwaggerDefinitions::CommonDefinitions.aggregate
      ].flatten.reduce({}, :merge)
    end
  end
end
