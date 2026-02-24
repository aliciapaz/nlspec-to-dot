# frozen_string_literal: true

module NlspecToDot
  module Planner
    class PromptBuilder
      def initialize(document:)
        @document = document
      end

      def template_customize_prompt
        constraints = format_constraints
        extra_gems = extract_extra_gems

        parts = [
          "Customize the Rails template for #{@document.app_name}.",
          "Update config/database.yml: set database names to #{@document.app_name.downcase}_development, #{@document.app_name.downcase}_test, #{@document.app_name.downcase}_production."
        ]

        if extra_gems.any?
          gem_list = extra_gems.map { |name, group|
            group ? "#{name} (group: #{group})" : name
          }.join(", ")
          parts << "Add these gems to the Gemfile: #{gem_list}. Then run: bundle install."
        end

        parts << "App constraints: #{constraints}." unless constraints.empty?
        parts << "Update config/application.rb: set the module name to #{classify(@document.app_name)}."
        parts << TelosContext.general

        build_prompt(*parts)
      end

      def model_prompt(model)
        fields = model.fields.map { |f| "#{f[:name]}:#{f[:type]}" }.join(", ")
        assocs = format_associations(model.associations)
        valids = model.validations.join("; ")

        parts = ["Generate the model #{model.name} with migration."]
        parts << "Fields: #{fields}." unless fields.empty?
        parts << "Associations: #{assocs}." unless assocs.empty?
        parts << "Validations: #{valids}." unless valids.empty?
        parts << format_enums(model) if model.enums.any?
        parts << format_attachments(model) if model.attachments.any?

        build_prompt(*parts, TelosContext.for_models)
      end

      def routes_prompt
        model_names = @document.models.map(&:name)
        build_prompt(
          "Generate config/routes.rb with RESTful resources for: #{model_names.join(", ")}.",
          "Use standard Rails resource routing conventions.",
          TelosContext.general
        )
      end

      def controllers_prompt_for(model)
        fields = model.fields.map { |f| f[:name] }
        assocs = model.associations.map { |a| "#{a[:kind]} :#{a[:target].downcase}" }

        parts = [
          "Generate the controller for #{model.name}.",
          "Permitted params: #{fields.join(", ")}.",
          ("Model associations: #{assocs.join(", ")}." unless assocs.empty?),
          "Include ActionPolicy authorization: authorize! @#{model.name.downcase}.",
          "Generate the corresponding #{model.name}Policy class.",
          TelosContext.for_controllers,
          TelosContext.for_authorization
        ].compact

        build_prompt(*parts)
      end

      def services_prompt_for(features)
        feature_descriptions = features.map { |f|
          desc = "#{f.name}: #{f.description}"
          desc += " (Related models: #{f.related_models.join(", ")})" if f.related_models.any?
          desc
        }.join("\\n")

        build_prompt(
          "Generate service objects for these features:\\n#{feature_descriptions}",
          "Create focused service classes following Telos patterns (call/save).",
          TelosContext.for_services
        )
      end

      def group_features_for_services(features)
        return [features] if features.size <= 3

        complex, simple = features.partition { |f| complex_feature?(f) }
        groups = complex.map { |f| [f] }
        groups.concat(group_by_model_overlap(simple))
        groups
      end

      def seeds_prompt
        seed_entries = if @document.seeds.any?
          @document.seeds.map { |s|
            attrs = s[:attributes].map { |k, v| "#{k}: #{v}" }.join(", ")
            "#{s[:label]}: #{attrs}"
          }.join("\\n")
        else
          model_names = @document.models.map(&:name)
          "Create seed data for: #{model_names.join(", ")}."
        end

        build_prompt(
          "Generate db/seeds.rb with the following seed data:\\n#{seed_entries}",
          "Use find_or_create_by to make seeds idempotent.",
          "Reference existing model validations and associations.",
          TelosContext.general
        )
      end

      def views_prompt_for(model)
        fields = model.fields.map { |f| "#{f[:name]} (#{f[:type]})" }
        assocs = model.associations.map { |a| "#{a[:kind]} :#{a[:target].downcase}" }

        parts = [
          "Generate views for #{model.name}: index, show, new, edit, and _form partial.",
          "Display fields: #{fields.join(", ")}."
        ]
        parts << "Show associated data: #{assocs.join(", ")}." if assocs.any?
        parts << "Use Tailwind CSS for styling."
        parts << TelosContext.for_views

        build_prompt(*parts)
      end

      def tests_prompt
        model_names = @document.models.map(&:name)
        feature_names = @document.features.map(&:name)
        build_prompt(
          "Generate RSpec tests for models: #{model_names.join(", ")}.",
          "Generate request specs for controllers.",
          "Generate FactoryBot factories.",
          "Cover features: #{feature_names.join(", ")}.",
          TelosContext.for_tests
        )
      end

      private

      def build_prompt(*parts)
        parts.map { |p| p.to_s.strip }.reject(&:empty?).join("\\n\\n")
      end

      def format_constraints
        @document.constraints.map { |c| "#{c.key}: #{c.value}" }.join(", ")
      end

      def extract_extra_gems
        gems = []
        @document.constraints.each do |c|
          case c.key.downcase
          when "state machine"
            gems << ["aasm", nil] if c.value.include?("AASM")
          when "soft delete"
            gems << ["discard", nil] if c.value.include?("Discard")
          when /pdf/
            gems << ["ferrum", nil] if c.value.include?("Ferrum")
          end
        end
        gems
      end

      def format_associations(associations)
        associations.map { |a|
          parts = ["#{a[:kind]} :#{a[:target].downcase}"]
          parts << "through: :#{a[:through]}" if a[:through]
          parts << "dependent: :#{a[:dependent]}" if a[:dependent]
          parts.join(", ")
        }.join("; ")
      end

      def format_enums(model)
        model.enums.map { |e|
          values = e[:values].map { |k, v| "#{k}: #{v}" }.join(", ")
          "Enum: #{e[:name]} { #{values} }"
        }.join(". ")
      end

      def format_attachments(model)
        names = model.attachments.map { |a| a[:name] }
        "Active Storage attachments: #{names.join(", ")}"
      end

      def complex_feature?(feature)
        feature.description.length > 200 || feature.related_models.size >= 3
      end

      def group_by_model_overlap(features)
        return [features] if features.size <= 3

        groups = []
        remaining = features.dup

        while remaining.any?
          seed = remaining.shift
          group = [seed]

          remaining.reject! do |f|
            if group.size < 3 && models_overlap?(seed, f)
              group << f
              true
            end
          end

          groups << group
        end

        groups
      end

      def models_overlap?(a, b)
        (a.related_models & b.related_models).any?
      end

      def classify(name)
        name.to_s.split(/[-_ ]/).map(&:capitalize).join
      end
    end
  end
end
