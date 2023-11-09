module Schemable
  class SchemaModifier
    def parse_path(path)
      path.split('.').map(&:to_sym)
    end

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

    def deep_merge_hashes(destination, new_data)
      if destination.is_a?(Array) && new_data.is_a?(Array)
        destination.concat(new_data)
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
