require "yaml"

module Garmin
  module FitEncoder
    module ExerciseMapping
      MAPPING_FILE = File.expand_path("../../../../config/garmin_exercises.yml", __FILE__)

      # Lookup returns [category, name]. Falls back to [unknown_category, 0].
      def self.lookup(exercise_name)
        normalized = exercise_name.to_s.downcase
        table.each do |keyword, (category, name)|
          return [category, name] if normalized.include?(keyword)
        end
        [Garmin::FitEncoder::EXERCISE_CATEGORY_UNKNOWN, 0]
      end

      # Loaded once; ordered hash so file order determines match precedence.
      def self.table
        @table ||= YAML.safe_load_file(MAPPING_FILE).each_with_object({}) do |(k, v), acc|
          acc[k.to_s.downcase] = v
        end.freeze
      end

      def self.reload!
        @table = nil
        table
      end
    end
  end
end
