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
