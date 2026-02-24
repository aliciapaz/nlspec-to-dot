# frozen_string_literal: true

require "spec_helper"

RSpec.describe NlspecToDot::Parser::SpecParser do
  let(:fixture_path) { File.expand_path("../../fixtures/simple_blog.md", __dir__) }
  let(:source) { File.read(fixture_path) }

  describe ".parse" do
    subject(:document) { described_class.parse(source) }

    it "extracts the app name from the top-level heading" do
      expect(document.app_name).to eq("SimpleBlog")
    end

    it "extracts the description" do
      expect(document.description).to include("simple blog application")
    end

    it "parses all models" do
      expect(document.models.map(&:name)).to eq(["User", "Post"])
    end

    it "parses model fields" do
      user = document.models.first
      expect(user.fields).to include({name: "email", type: "string"})
    end

    it "parses model associations" do
      post = document.models.last
      expect(post.associations).to include({kind: :belongs_to, target: "User"})
    end

    it "parses model validations" do
      user = document.models.first
      expect(user.validations.first).to include("validates :email")
    end

    it "parses features" do
      expect(document.features.map(&:name)).to eq(["Publishing Posts", "User Registration"])
    end

    it "parses feature descriptions" do
      feature = document.features.first
      expect(feature.description).to include("create draft posts")
    end

    it "parses feature related models" do
      feature = document.features.first
      expect(feature.related_models).to eq(["Post", "User"])
    end

    it "parses constraints" do
      keys = document.constraints.map(&:key)
      expect(keys).to include("Authentication", "Authorization", "Frontend", "Testing")
    end

    it "parses constraint values" do
      auth = document.constraints.find { |c| c.key == "Authentication" }
      expect(auth.value).to eq("has_secure_password")
    end
  end

  describe "enum parsing" do
    let(:source) do
      <<~MD
        # EnumApp

        Test app.

        ## Models

        ### Task
        - title:string
        - enum state: { draft: 0, completed: 1 }
      MD
    end

    it "parses enum definitions" do
      doc = described_class.parse(source)
      task = doc.models.first
      expect(task.enums).to eq([{name: "state", values: {"draft" => 0, "completed" => 1}}])
    end
  end

  describe "has_many :through parsing" do
    let(:source) do
      <<~MD
        # HMTApp

        Test app.

        ## Models

        ### Team
        - name:string
        - has_many :memberships
        - has_many :users, through: :memberships
      MD
    end

    it "captures the through option" do
      doc = described_class.parse(source)
      team = doc.models.first
      through_assoc = team.associations.find { |a| a[:through] }
      expect(through_assoc).to eq({kind: :has_many, target: "Users", through: "memberships"})
    end

    it "parses regular has_many without through" do
      doc = described_class.parse(source)
      team = doc.models.first
      regular = team.associations.find { |a| a[:target] == "Memberships" }
      expect(regular).to eq({kind: :has_many, target: "Memberships"})
    end
  end

  describe "dependent option parsing" do
    let(:source) do
      <<~MD
        # DepApp

        Test app.

        ## Models

        ### Project
        - name:string
        - has_many :forms, dependent: :destroy
      MD
    end

    it "captures the dependent option" do
      doc = described_class.parse(source)
      project = doc.models.first
      expect(project.associations.first).to eq({kind: :has_many, target: "Forms", dependent: :destroy})
    end
  end

  describe "has_one_attached parsing" do
    let(:source) do
      <<~MD
        # AttachApp

        Test app.

        ## Models

        ### Report
        - title:string
        - has_one_attached :pdf
      MD
    end

    it "parses has_one_attached as an attachment" do
      doc = described_class.parse(source)
      report = doc.models.first
      expect(report.attachments).to eq([{name: "pdf"}])
    end

    it "does not add attachment to associations" do
      doc = described_class.parse(source)
      report = doc.models.first
      expect(report.associations).to be_empty
    end
  end

  describe "Assets section parsing" do
    let(:source) do
      <<~MD
        # AssetApp

        Test app.

        ## Assets
        - chart.js: npm:chart.js@4.4.4 -> vendor/javascript/chart.umd.js
        - dexie.js: npm:dexie@4.0.4 -> vendor/javascript/dexie.min.js
      MD
    end

    it "parses asset definitions" do
      doc = described_class.parse(source)
      expect(doc.assets.size).to eq(2)
    end

    it "extracts asset name, source, and destination" do
      doc = described_class.parse(source)
      expect(doc.assets.first).to eq({
        name: "chart.js",
        source: "npm:chart.js@4.4.4",
        destination: "vendor/javascript/chart.umd.js"
      })
    end
  end

  describe "Seeds section parsing" do
    let(:source) do
      <<~MD
        # SeedApp

        Test app.

        ## Seeds
        - Admin user: email=admin@example.com, platform_role=super_admin
        - Demo org: name=Demo Organization
      MD
    end

    it "parses seed definitions" do
      doc = described_class.parse(source)
      expect(doc.seeds.size).to eq(2)
    end

    it "extracts seed label and attributes" do
      doc = described_class.parse(source)
      expect(doc.seeds.first).to eq({
        label: "Admin user",
        attributes: {"email" => "admin@example.com", "platform_role" => "super_admin"}
      })
    end

    it "handles single-attribute seeds" do
      doc = described_class.parse(source)
      expect(doc.seeds.last).to eq({
        label: "Demo org",
        attributes: {"name" => "Demo Organization"}
      })
    end
  end

  describe "with minimal spec" do
    let(:source) do
      <<~MD
        # MinApp

        Short description.

        ## Models

        ### Item
        - name:string
      MD
    end

    it "handles specs with no features or constraints" do
      doc = described_class.parse(source)
      expect(doc.app_name).to eq("MinApp")
      expect(doc.models.size).to eq(1)
      expect(doc.features).to be_empty
      expect(doc.constraints).to be_empty
    end
  end
end
