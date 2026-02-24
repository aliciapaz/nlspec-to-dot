# frozen_string_literal: true

require "spec_helper"

RSpec.describe NlspecToDot::Parser::Document do
  subject(:document) { build(:document, :full) }

  it "stores the app name" do
    expect(document.app_name).to eq("TestApp")
  end

  it "stores the description" do
    expect(document.description).to eq("A test application")
  end

  it "stores models" do
    expect(document.models.size).to eq(2)
  end

  it "stores features" do
    expect(document.features.size).to eq(1)
  end

  it "stores constraints" do
    expect(document.constraints.size).to eq(2)
  end

  it "freezes collections" do
    expect(document.models).to be_frozen
    expect(document.features).to be_frozen
    expect(document.constraints).to be_frozen
  end

  it "defaults assets to empty array" do
    expect(document.assets).to eq([])
  end

  it "defaults seeds to empty array" do
    expect(document.seeds).to eq([])
  end

  context "with assets and seeds" do
    subject(:document) do
      build(
        :document,
        assets: [{name: "chart.js", source: "npm:chart.js@4.4.4", destination: "vendor/javascript/chart.umd.js"}],
        seeds: [{label: "Admin", attributes: {"email" => "admin@test.com"}}]
      )
    end

    it "stores assets" do
      expect(document.assets.size).to eq(1)
    end

    it "stores seeds" do
      expect(document.seeds.size).to eq(1)
    end

    it "freezes assets" do
      expect(document.assets).to be_frozen
    end

    it "freezes seeds" do
      expect(document.seeds).to be_frozen
    end
  end
end
