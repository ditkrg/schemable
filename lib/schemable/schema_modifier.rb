module Schemable
  # The SchemaModifier class provides methods for modifying a given schema.
  # It includes methods for parsing paths, checking if a path exists in a schema,
  # deeply merging hashes, adding properties to a schema, and deleting properties from a schema.
  #
  # @see Schemable
  class SchemaModifier

    # Parses a given path into an array of symbols.
    #
    # @note This method accepts paths in the following formats:
    # - 'path.to.property'
    # - 'path.to.array.[0].property'
    #
    # @example
    #  parse_path('path.to.property') #=> [:path, :to, :property]
    #  parse_path('path.to.array.[0].property') #=> [:path, :to, :array, :[0], :property]
    #
    # @param path [String] The path to parse.
    # @return [Array<Symbol>] The parsed path.
    def parse_path(path)
      path.split('.').map(&:to_sym)
    end

    # Checks if a given path exists in a schema.
    #
    # @example
    #   schema = {
    #    path: {
    #        type: :object,
    #        properties: {
    #          to: {
    #            type: :object,
    #            properties: {
    #              property: {
    #                type: :string
    #              }
    #            }
    #          }
    #        }
    #     }
    #   }
    #
    #  path = 'path.properties.to.properties.property'
    #  incorrect_path = 'path.properties.to.properties.invalid'
    #  path_exists?(schema, path) #=> true
    #  path_exists?(schema, incorrect_path) #=> false
    #
    # @param schema [Hash, Array] The schema to check.
    # @param path [String] The path to check for.
    # @return [Boolean] True if the path exists in the schema, false otherwise.
    def path_exists?(schema, path)
      path_segments = parse_path(path)

      path_segments.reduce(schema) do |current_segment, next_segment|
        if current_segment.is_a?(Array)
          # The regex pattern '/\[(\d+)\]|\d+/' matches square brackets containing one or more digits,
          # or standalone digits. Used for parsing array indices in a path.
          index = next_segment.to_s.match(/\[(\d+)\]|\d+/)[1]
          # The regex pattern '/\A\d+\z/' matches a sequence of one or more digits from the start ('\A')
          # to the end ('\z') of a string. It checks if a string consists of only digits.
          return false if index.nil? || !index.match?(/\A\d+\z/) || index.to_i >= current_segment.length

          current_segment[index.to_i]
        else
          return false unless current_segment.is_a?(Hash) && current_segment.key?(next_segment)

          current_segment[next_segment]
        end
      end

      true
    end

    # Deeply merges two hashes.
    #
    # @example
    #   destination = { level1: { level2: { level3: 'value' } } }
    #   new_data = { level1_again: 'value' }
    #   deep_merge_hashes(destination, new_data)
    #   #=> { level1: { level2: { level3: 'value' } }, level1_again: 'value' }
    #
    #   new_destination = [{ object1: 'value' }, { object2: 'value' }]
    #   new_new_data = { object3: 'value' }
    #   deep_merge_hashes(new_destination, new_new_data)
    #   #=> [{ object1: 'value' }, { object2: 'value' }, { object3: 'value' }]
    #
    #   new_destination = { object1: 'value' }
    #   new_new_data = [{ object2: 'value' }, { object3: 'value' }]
    #   deep_merge_hashes(new_destination, new_new_data)
    #   #=> { object1: 'value', object2: 'value', object3: 'value' }
    #
    # @param destination [Hash] The hash to merge into.
    # @param new_data [Hash] The hash to merge from.
    # @return [Hash] The merged hashes.
    def deep_merge_hashes(destination, new_data)
      if destination.is_a?(Hash) && new_data.is_a?(Array)
        destination.merge(new_data)
      elsif destination.is_a?(Array) && new_data.is_a?(Hash)
        destination.push(new_data)
      elsif destination.is_a?(Hash) && new_data.is_a?(Hash)
        new_data.each do |key, value|
          if destination[key].is_a?(Hash) && value.is_a?(Hash)
            destination[key] = deep_merge_hashes(destination[key], value)
          elsif destination[key].is_a?(Array) && value.is_a?(Array)
            destination[key].concat(value)
          elsif destination[key].is_a?(Array) && value.is_a?(Hash)
            destination[key].push(value)
          else
            destination[key] = value
          end
        end
      end

      destination
    end

    # Adds properties to a schema at a given path.
    #
    # @example
    #   original_schema = { level1: { level2: { level3: 'value' } } }
    #   new_data = { L3: 'value' }
    #   path = 'level1.level2'
    #   add_properties(original_schema, new_schema, path)
    #   #=> { level1: { level2: { level3: 'value', L3: 'value' } } }
    #
    #   new_original_schema = { test: [{ object1: 'value' }, { object2: 'value' }] }
    #   new_new_schema = { object2_again: 'value' }
    #   path = 'test.[1]'
    #   add_properties(new_original_schema, new_new_schema, path)
    #   #=> { test: [{ object1: 'value' }, { object2: 'value', object2_again: 'value' }] }
    #
    # @param original_schema [Hash] The original schema.
    # @param new_schema [Hash] The new schema to add.
    # @param path [String] The path at which to add the new schema.
    # @note This method accepts paths in the following formats:
    # - 'path.to.property'
    # - 'path.to.array.[0].property'
    # - '.'
    #
    # @return [Hash] The modified schema.
    def add_properties(original_schema, new_schema, path)
      return deep_merge_hashes(original_schema, new_schema) if path == '.'

      unless path_exists?(original_schema, path)
        puts "Error: Path '#{path}' does not exist in the original schema"
        return original_schema
      end

      path_segments = parse_path(path)
      current_segment = original_schema
      last_segment = path_segments.pop

      # Navigate to the specified location in the schema
      path_segments.each do |segment|
        if current_segment.is_a?(Array)
          index = segment.to_s.match(/\[(\d+)\]|\d+/)[1]
          if index&.match?(/\A\d+\z/) && index.to_i < current_segment.length
            current_segment = current_segment[index.to_i]
          else
            puts "Error: Invalid index in path '#{path}'"
            return original_schema
          end
        elsif current_segment.is_a?(Hash) && current_segment.key?(segment)
          current_segment = current_segment[segment]
        else
          puts "Error: Expected a Hash but found #{current_segment.class} in path '#{path}'"
          return original_schema
        end
      end

      # Merge the new schema into the specified location
      if current_segment.is_a?(Array)
        index = last_segment.to_s.match(/\[(\d+)\]|\d+/)[1]
        if index&.match?(/\A\d+\z/) && index.to_i < current_segment.length
          current_segment[index.to_i] = deep_merge_hashes(current_segment[index.to_i], new_schema)
        else
          puts "Error: Invalid index in path '#{path}'"
        end
      else
        current_segment[last_segment] = deep_merge_hashes(current_segment[last_segment], new_schema)
      end

      original_schema
    end

    # Deletes properties from a schema at a given path.
    #
    # @example
    #   original_schema = { level1: { level2: { level3: 'value' } } }
    #   path = 'level1.level2'
    #   delete_properties(original_schema, path)
    #   #=> { level1: {} }
    #
    #   new_original_schema = { test: [{ object1: 'value' }, { object2: 'value' }] }
    #   path = 'test.[1]'
    #   delete_properties(new_original_schema, path)
    #   #=> { test: [{ object1: 'value' }] }
    #
    # @param original_schema [Hash] The original schema.
    # @param path [String] The path at which to delete properties.
    # @return [Hash] The modified schema.
    def delete_properties(original_schema, path)
      return original_schema if path == '.'

      unless path_exists?(original_schema, path)
        puts "Error: Path '#{path}' does not exist in the original schema"
        return original_schema
      end

      path_segments = parse_path(path)
      current_segment = original_schema
      last_segment = path_segments.pop

      # Navigate to the parent of the last segment in the path
      path_segments.each do |segment|
        if current_segment.is_a?(Array)
          index = segment.to_s.match(/\[(\d+)\]|\d+/)[1]
          if index&.match?(/\A\d+\z/) && index.to_i < current_segment.length
            current_segment = current_segment[index.to_i]
          else
            puts "Error: Invalid index in path '#{path}'"
            return original_schema
          end
        elsif current_segment.is_a?(Hash) && current_segment.key?(segment)
          current_segment = current_segment[segment]
        else
          puts "Error: Expected a Hash but found #{current_segment.class} in path '#{path}'"
          return original_schema
        end
      end

      # Delete the last segment in the path
      if current_segment.is_a?(Array)
        index = last_segment.to_s.match(/\[(\d+)\]|\d+/)[1]
        if index&.match?(/\A\d+\z/) && index.to_i < current_segment.length
          current_segment.delete_at(index.to_i)
        else
          puts "Error: Invalid index in path '#{path}'"
        end
      else
        current_segment.delete(last_segment)
      end

      original_schema
    end
  end
end
