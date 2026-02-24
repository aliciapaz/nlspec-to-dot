# frozen_string_literal: true

require "spec_helper"

RSpec.describe NlspecToDot::Parser::ModelDefinition do
  subject(:model) { build(:model_definition) }

  it "stores the name" do
    expect(model.name).to eq("Thing")
  end

  it "stores fields" do
    expect(model.fields).to eq([{name: "name", type: "string"}])
  end

  it "defaults enums to empty array" do
    expect(model.enums).to eq([])
  end

  it "defaults attachments to empty array" do
    expect(model.attachments).to eq([])
  end

  it "freezes enums" do
    expect(model.enums).to be_frozen
  end

  it "freezes attachments" do
    expect(model.attachments).to be_frozen
  end

  context "with enums and attachments" do
    subject(:model) do
      build(
        :model_definition,
        enums: [{name: "state", values: {"draft" => 0, "published" => 1}}],
        attachments: [{name: "pdf"}]
      )
    end

    it "stores enums" do
      expect(model.enums).to eq([{name: "state", values: {"draft" => 0, "published" => 1}}])
    end

    it "stores attachments" do
      expect(model.attachments).to eq([{name: "pdf"}])
    end
  end

  describe "#==" do
    it "considers enums and attachments in equality" do
      a = build(:model_definition, enums: [{name: "status", values: {"active" => 0}}])
      b = build(:model_definition, enums: [])
      expect(a).not_to eq(b)
    end
  end
end
