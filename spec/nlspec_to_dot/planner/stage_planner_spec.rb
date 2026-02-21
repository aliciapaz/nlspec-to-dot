# frozen_string_literal: true

require "spec_helper"

RSpec.describe NlspecToDot::Planner::StagePlanner do
  let(:document) { build(:document, :full) }
  let(:planner) { described_class.new(document: document) }
  let(:result) { planner.call }
  let(:stages) { result[:stages] }
  let(:edges) { result[:edges] }

  describe "#call" do
    it "returns stages and edges" do
      expect(result).to have_key(:stages)
      expect(result).to have_key(:edges)
    end

    it "starts with an Mdiamond start node" do
      expect(stages.first.shape).to eq("Mdiamond")
      expect(stages.first.id).to eq("start")
    end

    it "ends with an Msquare exit node" do
      expect(stages.last.shape).to eq("Msquare")
      expect(stages.last.id).to eq("exit")
    end

    it "creates model stages in topological order" do
      model_ids = stages.select { |s| s.id.start_with?("model_") }.map(&:id)
      expect(model_ids.index("model_user")).to be < model_ids.index("model_post")
    end

    it "creates scaffold, routes, controllers, services, views, tests stages" do
      ids = stages.map(&:id)
      %w[scaffold routes controllers services views tests].each do |expected|
        expect(ids).to include(expected)
      end
    end

    it "creates run_tests as a parallelogram (tool)" do
      run_tests = stages.find { |s| s.id == "run_tests" }
      expect(run_tests.shape).to eq("parallelogram")
    end

    it "creates test_gate as a diamond (conditional)" do
      gate = stages.find { |s| s.id == "test_gate" }
      expect(gate.shape).to eq("diamond")
    end

    it "creates human_review as a hexagon (wait.human)" do
      review = stages.find { |s| s.id == "human_review" }
      expect(review.shape).to eq("hexagon")
    end

    it "includes a retry edge from test_gate to tests" do
      retry_edge = edges.find { |e|
        e[:from] == "test_gate" && e[:to] == "tests"
      }
      expect(retry_edge).not_to be_nil
      expect(retry_edge[:condition]).to eq("outcome!=success")
    end

    it "includes a pass edge from test_gate to human_review" do
      pass_edge = edges.find { |e|
        e[:from] == "test_gate" && e[:to] == "human_review"
      }
      expect(pass_edge).not_to be_nil
      expect(pass_edge[:condition]).to eq("outcome=success")
    end

    it "includes human review approve edge to exit" do
      approve = edges.find { |e|
        e[:from] == "human_review" && e[:to] == "exit"
      }
      expect(approve).not_to be_nil
      expect(approve[:label]).to eq("[A] Approve")
    end

    it "includes human review fix edge to tests" do
      fix = edges.find { |e|
        e[:from] == "human_review" && e[:to] == "tests"
      }
      expect(fix).not_to be_nil
      expect(fix[:label]).to eq("[F] Request Fixes")
    end

    it "sets goal_gate and retry_target on model stages" do
      model_stages = stages.select { |s| s.id.start_with?("model_") }
      model_stages.each do |s|
        expect(s.attrs[:goal_gate]).to be(true)
        expect(s.attrs[:retry_target]).not_to be_nil
      end
    end

    it "all box stages have prompts" do
      box_stages = stages.select { |s| s.shape == "box" }
      box_stages.each do |s|
        expect(s.prompt).not_to be_nil, "Stage #{s.id} is missing a prompt"
      end
    end
  end
end
