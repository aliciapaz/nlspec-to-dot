# frozen_string_literal: true

module NlspecToDot
  module Planner
    class TemplateCommandBuilder
      TEMPLATE_URL = "https://github.com/telos-app/telos-rails-template.git"
      TEMPLATE_BRANCH = "main"

      def initialize(document:)
        @document = document
      end

      def clone_command
        [
          "git clone --depth 1 --branch #{TEMPLATE_BRANCH} #{TEMPLATE_URL} .",
          "rm -rf .git",
          "git init"
        ].join(" && ")
      end

      def db_setup_command
        "bundle install && bundle exec rails db:create"
      end

      def install_assets_command
        return nil unless assets.any?

        commands = assets.map { |asset| install_asset_command(asset) }
        commands.compact.join(" && ")
      end

      def migrate_verify_command
        "bundle exec rails db:migrate && bundle exec rails db:migrate:status"
      end

      def routes_verify_command
        "bundle exec rails routes | head -50"
      end

      private

      def assets
        @document.assets
      end

      SAFE_PATTERN = /\A[\w@.\/-]+\z/

      def install_asset_command(asset)
        source = asset[:source]
        destination = asset[:destination]

        return nil unless source&.start_with?("npm:")

        package = source.sub("npm:", "")
        pkg_name = package.split("@").first
        filename = File.basename(destination)
        dest_dir = File.dirname(destination)

        validate_shell_safe!(package, pkg_name, filename, dest_dir, destination)

        "mkdir -p #{dest_dir} && " \
          "npm pack #{package} --pack-destination /tmp && " \
          "tar -xzf /tmp/#{pkg_name}-*.tgz -C /tmp && " \
          "cp /tmp/package/dist/#{filename} #{destination} && " \
          "rm -rf /tmp/package /tmp/#{pkg_name}-*.tgz"
      end

      def validate_shell_safe!(*values)
        values.each do |val|
          unless val.match?(SAFE_PATTERN)
            raise ArgumentError, "Unsafe shell value: #{val.inspect}"
          end
        end
      end
    end
  end
end
