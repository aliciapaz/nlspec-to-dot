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

  describe "#template_customize_prompt" do
    subject(:prompt) { builder.template_customize_prompt }

    it "includes the app name" do
      expect(prompt).to include("TestApp")
    end

    it "references database configuration" do
      expect(prompt).to include("database.yml")
    end

    it "includes database name pattern" do
      expect(prompt).to include("testapp_development")
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

  describe "#controllers_prompt_for" do
    let(:model) { build(:model_definition, :post) }
    subject(:prompt) { builder.controllers_prompt_for(model) }

    it "includes the model name" do
      expect(prompt).to include("Post")
    end

    it "includes permitted params" do
      expect(prompt).to include("title")
    end

    it "includes ActionPolicy reference" do
      expect(prompt).to include("ActionPolicy")
    end

    it "includes authorization instruction" do
      expect(prompt).to include("authorize!")
    end
  end

  describe "#services_prompt" do
    it "includes feature descriptions" do
      expect(builder.services_prompt).to include("Publishing")
    end
  end

  describe "#services_prompt_for" do
    let(:features) do
      [
        NlspecToDot::Parser::FeatureDefinition.new(
          name: "Auth",
          description: "User authentication",
          related_models: ["User"]
        )
      ]
    end

    subject(:prompt) { builder.services_prompt_for(features) }

    it "includes the feature name" do
      expect(prompt).to include("Auth")
    end

    it "includes related models" do
      expect(prompt).to include("User")
    end

    it "includes Telos service conventions" do
      expect(prompt).to include("call")
    end
  end

  describe "#group_features_for_services" do
    context "with few features" do
      let(:features) do
        [
          NlspecToDot::Parser::FeatureDefinition.new(name: "A", description: "x", related_models: []),
          NlspecToDot::Parser::FeatureDefinition.new(name: "B", description: "y", related_models: [])
        ]
      end

      it "returns a single group" do
        groups = builder.group_features_for_services(features)
        expect(groups.size).to eq(1)
        expect(groups.first.size).to eq(2)
      end
    end

    context "with complex features" do
      let(:features) do
        [
          NlspecToDot::Parser::FeatureDefinition.new(
            name: "Complex",
            description: "x" * 250,
            related_models: %w[A B C D]
          ),
          NlspecToDot::Parser::FeatureDefinition.new(name: "Simple1", description: "a", related_models: ["A"]),
          NlspecToDot::Parser::FeatureDefinition.new(name: "Simple2", description: "b", related_models: ["A"]),
          NlspecToDot::Parser::FeatureDefinition.new(name: "Simple3", description: "c", related_models: ["B"])
        ]
      end

      it "isolates complex features into solo groups" do
        groups = builder.group_features_for_services(features)
        complex_group = groups.find { |g| g.any? { |f| f.name == "Complex" } }
        expect(complex_group.size).to eq(1)
      end

      it "groups simple features together" do
        groups = builder.group_features_for_services(features)
        expect(groups.size).to be >= 2
      end
    end
  end

  describe "#seeds_prompt" do
    subject(:prompt) { builder.seeds_prompt }

    it "includes seed data reference" do
      expect(prompt).to include("seeds.rb")
    end

    it "references idempotent creation" do
      expect(prompt).to include("find_or_create_by")
    end
  end

  describe "#views_prompt" do
    it "includes Turbo reference" do
      expect(builder.views_prompt).to include("Turbo")
    end
  end

  describe "#views_prompt_for" do
    let(:model) { build(:model_definition, :post) }
    subject(:prompt) { builder.views_prompt_for(model) }

    it "includes the model name" do
      expect(prompt).to include("Post")
    end

    it "includes field information" do
      expect(prompt).to include("title")
    end

    it "includes view types" do
      expect(prompt).to include("index")
      expect(prompt).to include("show")
    end

    it "includes Tailwind reference" do
      expect(prompt).to include("Tailwind")
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
