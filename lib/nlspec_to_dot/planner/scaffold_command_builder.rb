# frozen_string_literal: true

module NlspecToDot
  module Planner
    class ScaffoldCommandBuilder
      def initialize(document:)
        @document = document
      end

      def call
        [
          rails_new_command,
          *gem_add_commands,
          "bundle install",
          *generator_commands
        ].join(" && ")
      end

      private

      def rails_new_command
        "rails new . --name=#{@document.app_name} #{scaffold_flags.join(' ')}"
      end

      def scaffold_flags
        flags = %w[--force --skip-test]
        @document.constraints.each { |c| flags.concat(flags_for(c)) }
        flags
      end

      def flags_for(constraint)
        case constraint.key.downcase
        when "database" then database_flag(constraint.value)
        when "frontend" then frontend_flag(constraint.value)
        when "rails" then framework_flags(constraint.value)
        else []
        end
      end

      def database_flag(value)
        db = case value
        when /postgres/i then "postgresql"
        when /mysql/i then "mysql"
        when /sqlite/i then "sqlite3"
        when /trilogy/i then "trilogy"
        end
        db ? ["--database=#{db}"] : []
      end

      def frontend_flag(value)
        value.include?("Tailwind") ? ["--css=tailwind"] : []
      end

      def framework_flags(value)
        flags = []
        flags << "--asset-pipeline=propshaft" if value.include?("Propshaft")
        flags << "--javascript=importmap" if value.include?("Importmap")
        flags
      end

      def gem_add_commands
        scaffold_gems.map do |name, group|
          cmd = "bundle add #{name} --skip-install"
          cmd += " --group=#{group}" if group
          cmd
        end
      end

      def scaffold_gems
        gems = []
        @document.constraints.each { |c| gems.concat(gems_for(c)) }
        gems
      end

      def gems_for(constraint)
        case constraint.key.downcase
        when "authentication" then match_gem(constraint.value, "Devise", "devise")
        when "authorization" then match_gem(constraint.value, "ActionPolicy", "action_policy")
        when "state machine" then match_gem(constraint.value, "AASM", "aasm")
        when "soft delete" then match_gem(constraint.value, "Discard", "discard")
        when /pdf/ then match_gem(constraint.value, "Ferrum", "ferrum")
        when "testing" then test_gems(constraint.value)
        else []
        end
      end

      def match_gem(value, keyword, gem_name, group: nil)
        value.include?(keyword) ? [[gem_name, group]] : []
      end

      def test_gems(value)
        gems = []
        gems << ["rspec-rails", "development,test"] if value.include?("RSpec")
        gems << ["factory_bot_rails", "development,test"] if value.include?("FactoryBot")
        gems << ["shoulda-matchers", "test"] if value.include?("shoulda")
        gems
      end

      def generator_commands
        cmds = []
        cmds << "bundle exec rails generate rspec:install" if constraint_includes?("testing", "RSpec")
        cmds << "bundle exec rails generate devise:install" if constraint_includes?("authentication", "Devise")
        cmds
      end

      def constraint_includes?(key, keyword)
        @document.constraints
          .find { |c| c.key.downcase == key.downcase }
          &.value&.include?(keyword)
      end
    end
  end
end
