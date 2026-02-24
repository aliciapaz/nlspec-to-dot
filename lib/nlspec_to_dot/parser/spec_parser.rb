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
          constraints: parse_constraints(sections["Constraints"]),
          assets: parse_assets(sections["Assets"]),
          seeds: parse_seeds(sections["Seeds"])
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
        enums = []
        attachments = []

        body.each_line do |line|
          line = line.strip
          next unless line.start_with?("- ")
          content = line.sub(/^-\s+/, "")

          case content
          when /^(belongs_to|has_many|has_one)\s+:(\w+)/
            associations << parse_association($1, $2, content)
          when /^has_one_attached\s+:(\w+)/
            attachments << {name: $1}
          when /^enum\s+(\w+):\s*\{([^}]+)\}/
            enums << parse_enum($1, $2)
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
          validations: validations,
          enums: enums,
          attachments: attachments
        )
      end

      def parse_association(kind, target_name, content)
        assoc = {kind: kind.to_sym, target: classify(target_name)}
        if content.match(/through:\s*:(\w+)/)
          assoc[:through] = $1
        end
        if content.match(/dependent:\s*:(\w+)/)
          assoc[:dependent] = $1.to_sym
        end
        assoc
      end

      def parse_enum(name, values_str)
        values = values_str.split(",").each_with_object({}) do |pair, hash|
          key, val = pair.strip.split(/:\s*/, 2)
          hash[key.strip] = val.strip.to_i
        end
        {name: name, values: values}
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

      def parse_assets(text)
        return [] unless text

        text.each_line.filter_map { |line|
          line = line.strip
          next unless line.start_with?("- ")
          content = line.sub(/^-\s+/, "")
          if content.match(/^(.+?):\s*(.+?)\s*->\s*(.+)$/)
            {name: $1.strip, source: $2.strip, destination: $3.strip}
          end
        }
      end

      def parse_seeds(text)
        return [] unless text

        text.each_line.filter_map { |line|
          line = line.strip
          next unless line.start_with?("- ")
          content = line.sub(/^-\s+/, "")
          if content.include?(":")
            label, attrs_str = content.split(":", 2).map(&:strip)
            attributes = attrs_str.split(",").each_with_object({}) do |pair, hash|
              key, val = pair.strip.split("=", 2)
              hash[key.strip] = val.strip
            end
            {label: label, attributes: attributes}
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
