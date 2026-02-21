# frozen_string_literal: true

require "spec_helper"

RSpec.describe NlspecToDot::Emitter::DotEmitter do
  let(:stages) do
    [
      build(:stage, :start),
      build(:stage, id: "task", label: "Task", shape: "box", prompt: "Do it"),
      build(:stage, :exit)
    ]
  end
  let(:edges) do
    [
      {from: "start", to: "task"},
      {from: "task", to: "exit"}
    ]
  end

  subject(:dot) do
    described_class.new(
      app_name: "TestApp",
      stages: stages,
      edges: edges,
      goal: "Build something"
    ).call
  end

  it "starts with digraph declaration" do
    expect(dot).to start_with("digraph TestApp {")
  end

  it "includes goal in graph attributes" do
    expect(dot).to include('goal="Build something"')
  end

  it "includes rankdir" do
    expect(dot).to include('rankdir="LR"')
  end

  it "includes node defaults" do
    expect(dot).to include('node [shape="box"]')
  end

  it "includes all node declarations" do
    expect(dot).to include("start [")
    expect(dot).to include("task [")
    expect(dot).to include("exit [")
  end

  it "includes all edges" do
    expect(dot).to include("start -> task")
    expect(dot).to include("task -> exit")
  end

  it "ends with closing brace" do
    expect(dot.strip).to end_with("}")
  end

  it "sanitizes app name with special characters" do
    result = described_class.new(
      app_name: "My App!",
      stages: stages,
      edges: edges,
      goal: "test"
    ).call

    expect(result).to start_with("digraph My_App_ {")
  end
end
