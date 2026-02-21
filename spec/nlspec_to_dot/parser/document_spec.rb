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
end
