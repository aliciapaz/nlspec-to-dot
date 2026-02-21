# frozen_string_literal: true

require "spec_helper"

RSpec.describe NlspecToDot::Planner::PromptBuilder do
  let(:document) { build(:document, :full) }
  let(:builder) { described_class.new(document: document) }

  describe "#scaffold_prompt" do
    subject(:prompt) { builder.scaffold_prompt }

    it "includes the app name" do
      expect(prompt).to include("TestApp")
    end

    it "includes dependency list" do
      expect(prompt).to include("rails")
    end

    it "includes Telos context" do
      expect(prompt).to include("lines per method")
    end
  end

  describe "#model_prompt" do
    let(:model) { build(:model_definition, :post) }
    subject(:prompt) { builder.model_prompt(model) }

    it "includes the model name" do
      expect(prompt).to include("Post")
    end

    it "includes field definitions" do
      expect(prompt).to include("title:string")
    end

    it "includes associations" do
      expect(prompt).to include("belongs_to")
    end

    it "includes Telos model conventions" do
      expect(prompt).to include("persistence")
    end
  end

  describe "#routes_prompt" do
    it "includes model names" do
      prompt = builder.routes_prompt
      expect(prompt).to include("User")
      expect(prompt).to include("Post")
    end
  end

  describe "#controllers_prompt" do
    it "includes ActionPolicy reference" do
      expect(builder.controllers_prompt).to include("ActionPolicy")
    end
  end

  describe "#services_prompt" do
    it "includes feature descriptions" do
      expect(builder.services_prompt).to include("Publishing")
    end
  end

  describe "#views_prompt" do
    it "includes Turbo reference" do
      expect(builder.views_prompt).to include("Turbo")
    end
  end

  describe "#tests_prompt" do
    it "includes RSpec reference" do
      expect(builder.tests_prompt).to include("RSpec")
    end

    it "includes FactoryBot reference" do
      expect(builder.tests_prompt).to include("FactoryBot")
    end
  end
end
