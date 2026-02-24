# frozen_string_literal: true

require "spec_helper"

RSpec.describe "End-to-end compilation", :integration do
  let(:fixture_path) { File.expand_path("../fixtures/simple_blog.md", __dir__) }
  let(:source) { File.read(fixture_path) }
  let(:dot) { NlspecToDot::Compiler.new(source: source).call }

  it "produces valid DOT output" do
    expect(dot).to start_with("digraph")
    expect(dot.strip).to end_with("}")
  end

  it "has exactly one start node (Mdiamond)" do
    matches = dot.scan('shape="Mdiamond"')
    expect(matches.size).to eq(1)
  end

  it "has exactly one exit node (Msquare)" do
    matches = dot.scan('shape="Msquare"')
    expect(matches.size).to eq(1)
  end

  it "has no edges targeting start" do
    expect(dot).not_to match(/-> start[\s\[}]/)
  end

  it "has no edges leaving exit" do
    expect(dot).not_to match(/exit ->/)
  end

  it "uses only valid condition syntax" do
    conditions = dot.scan(/condition="([^"]*)"/).flatten
    conditions.each do |c|
      expect(c).to match(/^\w+(!?=)\w+$/)
    end
  end

  it "all named box nodes have prompts" do
    dot.each_line do |line|
      next unless line.match?(/^\s+\w+ \[.*shape="box"/)
      next if line.strip.start_with?("node ")
      expect(line).to include("prompt="), "Box node missing prompt: #{line.strip}"
    end
  end

  it "model stages have goal_gate and retry_target" do
    model_nodes = dot.scan(/^\s+model_\w+ \[.*\]$/)
    model_nodes.each do |node|
      expect(node).to include("goal_gate=true"), "Model node missing goal_gate: #{node}"
      expect(node).to include("retry_target="), "Model node missing retry_target: #{node}"
    end
  end

  it "includes a test retry loop" do
    expect(dot).to include('condition="outcome!=success"')
    expect(dot).to include('condition="outcome=success"')
  end

  it "includes human review gate" do
    expect(dot).to include('shape="hexagon"')
    expect(dot).to include("[A] Approve")
    expect(dot).to include("[F] Request Fixes")
  end

  it "does not hardcode backend or provider metadata" do
    expect(dot).not_to include("llm_provider")
    expect(dot).not_to include("backend=")
  end

  it "includes template clone and customize stages" do
    expect(dot).to include("template_clone")
    expect(dot).to include("template_customize")
  end

  it "includes verification stages" do
    expect(dot).to include("migrate_verify")
    expect(dot).to include("routes_verify")
  end

  context "with ecommerce fixture" do
    let(:fixture_path) { File.expand_path("../fixtures/ecommerce.md", __dir__) }

    it "produces valid DOT with complex model dependencies" do
      expect(dot).to include("digraph ShopApp")
      expect(dot).to include("model_organization")
      expect(dot).to include("model_user")
      expect(dot).to include("model_order")
    end

    it "orders Organization before User" do
      org_pos = dot.index("model_organization")
      user_pos = dot.index("model_user")
      expect(org_pos).to be < user_pos
    end

    it "creates parallel model batches for independent models" do
      # Organization is independent, so at least one batch should have fan-out
      expect(dot).to include("models_batch")
    end

    it "creates parallel controller stages" do
      expect(dot).to include("controllers_fan_out")
      expect(dot).to include("controllers_fan_in")
    end

    it "creates parallel view stages" do
      expect(dot).to include("views_fan_out")
      expect(dot).to include("views_fan_in")
    end
  end
end
