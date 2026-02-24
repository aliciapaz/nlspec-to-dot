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

  describe ".batch" do
    it "groups independent models into the same batch" do
      org = NlspecToDot::Parser::ModelDefinition.new(name: "Organization")
      tag = NlspecToDot::Parser::ModelDefinition.new(name: "Tag")
      user = NlspecToDot::Parser::ModelDefinition.new(
        name: "User",
        associations: [{kind: :belongs_to, target: "Organization"}]
      )

      batches = described_class.batch([user, org, tag])
      expect(batches.first.map(&:name)).to contain_exactly("Organization", "Tag")
      expect(batches.last.map(&:name)).to eq(["User"])
    end

    it "returns single-element batches for chain dependencies" do
      a = NlspecToDot::Parser::ModelDefinition.new(name: "A")
      b = NlspecToDot::Parser::ModelDefinition.new(
        name: "B",
        associations: [{kind: :belongs_to, target: "A"}]
      )
      c = NlspecToDot::Parser::ModelDefinition.new(
        name: "C",
        associations: [{kind: :belongs_to, target: "B"}]
      )

      batches = described_class.batch([c, b, a])
      expect(batches.map { |b| b.map(&:name) }).to eq([["A"], ["B"], ["C"]])
    end

    it "groups models with different dependencies in the same batch" do
      org = NlspecToDot::Parser::ModelDefinition.new(name: "Organization")
      user = NlspecToDot::Parser::ModelDefinition.new(
        name: "User",
        associations: [{kind: :belongs_to, target: "Organization"}]
      )
      product = NlspecToDot::Parser::ModelDefinition.new(
        name: "Product",
        associations: [{kind: :belongs_to, target: "Organization"}]
      )

      batches = described_class.batch([product, user, org])
      expect(batches[0].map(&:name)).to eq(["Organization"])
      expect(batches[1].map(&:name)).to contain_exactly("User", "Product")
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

      expect { described_class.batch([a, b]) }
        .to raise_error(NlspecToDot::Planner::TopologicalSorter::CycleError)
    end

    it "returns flat sort when flattened" do
      org = NlspecToDot::Parser::ModelDefinition.new(name: "Organization")
      user = NlspecToDot::Parser::ModelDefinition.new(
        name: "User",
        associations: [{kind: :belongs_to, target: "Organization"}]
      )

      batches = described_class.batch([user, org])
      sorted = described_class.sort([user, org])
      expect(batches.flatten.map(&:name)).to eq(sorted.map(&:name))
    end
  end
end
