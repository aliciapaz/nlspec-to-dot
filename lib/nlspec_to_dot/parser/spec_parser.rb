# frozen_string_literal: true

module NlspecToDot
  module Parser
    class SpecParser
      def self.parse(source)
        new(source).parse
      end

      def initialize(source)
        @source = source
      end

      def parse
        app_name = extract_app_name
        description = extract_description
        sections = split_sections

        Document.new(
          app_name: app_name,
          description: description,
          models: parse_models(sections["Models"]),
          features: parse_features(sections["Features"]),
          constraints: parse_constraints(sections["Constraints"])
        )
      end

      private

      def extract_app_name
        match = @source.match(/^#\s+(.+)$/)
        match ? match[1].strip : "App"
      end

      def extract_description
        lines = @source.lines
        past_title = false
        desc_lines = []

        lines.each do |line|
          if !past_title && line.match?(/^#\s+/)
            past_title = true
            next
          end
          break if past_title && line.match?(/^##\s+/)
          desc_lines << line if past_title
        end

        desc_lines.join.strip
      end

      def split_sections
        sections = {}
        current_name = nil
        current_lines = []

        @source.each_line do |line|
          if line.match?(/^##\s+/)
            sections[current_name] = current_lines.join if current_name
            current_name = line.sub(/^##\s+/, "").strip
            current_lines = []
          elsif current_name
            current_lines << line
          end
        end

        sections[current_name] = current_lines.join if current_name
        sections
      end

      def parse_models(text)
        return [] unless text

        split_subsections(text).map { |name, body| parse_model(name, body) }
      end

      def parse_model(name, body)
        fields = []
        associations = []
        validations = []

        body.each_line do |line|
          line = line.strip
          next unless line.start_with?("- ")
          content = line.sub(/^-\s+/, "")

          case content
          when /^(belongs_to|has_many|has_one)\s+:(\w+)/
            associations << {kind: $1.to_sym, target: classify($2)}
          when /^validates\s+/
            validations << content
          when /^(\w+):(\w+)/
            fields << {name: $1, type: $2}
          end
        end

        ModelDefinition.new(
          name: name,
          fields: fields,
          associations: associations,
          validations: validations
        )
      end

      def parse_features(text)
        return [] unless text

        split_subsections(text).map { |name, body| parse_feature(name, body) }
      end

      def parse_feature(name, body)
        lines = body.lines.map(&:strip).reject(&:empty?)
        related_line = lines.find { |l| l.match?(/^Related models:/i) }
        related = if related_line
          related_line.sub(/^Related models:\s*/i, "").split(",").map(&:strip)
        else
          []
        end

        desc_lines = lines.reject { |l| l.match?(/^Related models:/i) }

        FeatureDefinition.new(
          name: name,
          description: desc_lines.join(" "),
          related_models: related
        )
      end

      def parse_constraints(text)
        return [] unless text

        text.each_line.filter_map { |line|
          line = line.strip
          next unless line.start_with?("- ")
          content = line.sub(/^-\s+/, "")
          if content.include?(":")
            key, value = content.split(":", 2).map(&:strip)
            ConstraintDefinition.new(key: key, value: value)
          end
        }
      end

      def split_subsections(text)
        result = []
        current_name = nil
        current_lines = []

        text.each_line do |line|
          if line.match?(/^###\s+/)
            result << [current_name, current_lines.join] if current_name
            current_name = line.sub(/^###\s+/, "").strip
            current_lines = []
          elsif current_name
            current_lines << line
          end
        end

        result << [current_name, current_lines.join] if current_name
        result
      end

      def classify(name)
        name.to_s.split("_").map(&:capitalize).join
      end
    end
  end
end
