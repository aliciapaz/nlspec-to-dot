# frozen_string_literal: true

module NlspecToDot
  module Planner
    class PromptBuilder
      def initialize(document:)
        @document = document
      end

      def scaffold_prompt
        constraints = format_constraints
        deps = extract_dependencies

        build_prompt(
          "Generate a new Rails application named #{@document.app_name}.",
          "Set up the project with these dependencies: #{deps}.",
          constraints,
          TelosContext.general
        )
      end

      def model_prompt(model)
        fields = model.fields.map { |f| "#{f[:name]}:#{f[:type]}" }.join(", ")
        assocs = model.associations.map { |a| "#{a[:kind]} :#{a[:target].downcase}" }.join(", ")
        valids = model.validations.join("; ")

        parts = ["Generate the model #{model.name} with migration."]
        parts << "Fields: #{fields}." unless fields.empty?
        parts << "Associations: #{assocs}." unless assocs.empty?
        parts << "Validations: #{valids}." unless valids.empty?

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

      def controllers_prompt
        model_names = @document.models.map(&:name)
        build_prompt(
          "Generate controllers for: #{model_names.join(", ")}.",
          "Include ActionPolicy authorization and strong parameters.",
          "Generate corresponding policy classes.",
          TelosContext.for_controllers,
          TelosContext.for_authorization
        )
      end

      def services_prompt
        feature_descriptions = @document.features.map { |f|
          "#{f.name}: #{f.description}"
        }.join("\\n")

        build_prompt(
          "Generate service objects for the following features:\\n#{feature_descriptions}",
          TelosContext.for_services
        )
      end

      def views_prompt
        model_names = @document.models.map(&:name)
        build_prompt(
          "Generate views for: #{model_names.join(", ")}.",
          "Include index, show, new, edit, and form partials.",
          "Use Turbo Frames and Stimulus controllers where appropriate.",
          TelosContext.for_views
        )
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

      def extract_dependencies
        deps = ["rails"]
        @document.constraints.each do |c|
          case c.key.downcase
          when "authentication"
            deps << "bcrypt" if c.value.include?("has_secure_password")
          when "authorization"
            deps << "action_policy" if c.value.include?("ActionPolicy")
          when "testing"
            deps << "rspec-rails" << "factory_bot_rails" if c.value.include?("RSpec")
          when "frontend"
            deps << "turbo-rails" << "stimulus-rails" if c.value.include?("Hotwire")
          end
        end
        deps.uniq.join(", ")
      end
    end
  end
end
