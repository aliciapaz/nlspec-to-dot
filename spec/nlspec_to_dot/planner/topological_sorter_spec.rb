# frozen_string_literal: true

require "spec_helper"

RSpec.describe NlspecToDot::Planner::TopologicalSorter do
  describe ".sort" do
    it "places independent models first" do
      user = build(:model_definition, :user)
      post = build(:model_definition, :post)

      sorted = described_class.sort([post, user])
      names = sorted.map(&:name)

      expect(names.index("User")).to be < names.index("Post")
    end

    it "handles already-sorted input" do
      user = build(:model_definition, :user)
      post = build(:model_definition, :post)

      sorted = described_class.sort([user, post])
      expect(sorted.map(&:name)).to eq(["User", "Post"])
    end

    it "handles independent models" do
      tag = build(:model_definition, :independent)
      user = build(:model_definition, :user)

      sorted = described_class.sort([tag, user])
      expect(sorted.size).to eq(2)
    end

    it "raises on cyclic dependencies" do
      a = NlspecToDot::Parser::ModelDefinition.new(
        name: "A",
        associations: [{kind: :belongs_to, target: "B"}]
      )
      b = NlspecToDot::Parser::ModelDefinition.new(
        name: "B",
        associations: [{kind: :belongs_to, target: "A"}]
      )

      expect { described_class.sort([a, b]) }
        .to raise_error(NlspecToDot::Planner::TopologicalSorter::CycleError)
    end

    it "handles a deep dependency chain" do
      org = NlspecToDot::Parser::ModelDefinition.new(name: "Organization")
      user = NlspecToDot::Parser::ModelDefinition.new(
        name: "User",
        associations: [{kind: :belongs_to, target: "Organization"}]
      )
      post = NlspecToDot::Parser::ModelDefinition.new(
        name: "Post",
        associations: [{kind: :belongs_to, target: "User"}]
      )

      sorted = described_class.sort([post, user, org])
      names = sorted.map(&:name)

      expect(names.index("Organization")).to be < names.index("User")
      expect(names.index("User")).to be < names.index("Post")
    end
  end
end
