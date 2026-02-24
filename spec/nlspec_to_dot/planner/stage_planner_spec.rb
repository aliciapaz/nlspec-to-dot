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

    it "creates template, routes, and test stages" do
      ids = stages.map(&:id)
      %w[template_clone template_customize db_setup routes tests].each do |expected|
        expect(ids).to include(expected)
      end
    end

    it "creates verification stages" do
      ids = stages.map(&:id)
      expect(ids).to include("migrate_verify")
      expect(ids).to include("routes_verify")
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

    context "with parallel model batches" do
      let(:org) do
        NlspecToDot::Parser::ModelDefinition.new(name: "Organization")
      end
      let(:user) do
        NlspecToDot::Parser::ModelDefinition.new(
          name: "User",
          associations: [{kind: :belongs_to, target: "Organization"}]
        )
      end
      let(:post) do
        NlspecToDot::Parser::ModelDefinition.new(
          name: "Post",
          associations: [{kind: :belongs_to, target: "User"}]
        )
      end
      let(:comment) do
        NlspecToDot::Parser::ModelDefinition.new(
          name: "Comment",
          associations: [{kind: :belongs_to, target: "Post"}]
        )
      end
      let(:tag) do
        NlspecToDot::Parser::ModelDefinition.new(name: "Tag")
      end
      let(:document) do
        build(:document, :full, models: [org, user, post, comment, tag])
      end

      it "creates parallel fan-out/fan-in for batches with multiple models" do
        ids = stages.map(&:id)
        # Org and Tag are independent — should be in batch 0 with fan-out/fan-in
        expect(ids).to include("models_batch_0_fan_out")
        expect(ids).to include("models_batch_0_fan_in")
      end

      it "uses component shape for fan-out" do
        fan_out = stages.find { |s| s.id == "models_batch_0_fan_out" }
        expect(fan_out.shape).to eq("component")
      end

      it "uses tripleoctagon shape for fan-in" do
        fan_in = stages.find { |s| s.id == "models_batch_0_fan_in" }
        expect(fan_in.shape).to eq("tripleoctagon")
      end

      it "creates edges from fan-out to each model in the batch" do
        batch_0_models = stages.select { |s|
          s.id.start_with?("model_") && %w[model_organization model_tag].include?(s.id)
        }
        batch_0_models.each do |m|
          edge = edges.find { |e| e[:from] == "models_batch_0_fan_out" && e[:to] == m.id }
          expect(edge).not_to be_nil, "Missing edge from fan-out to #{m.id}"
        end
      end
    end

    context "with parallel controllers" do
      it "creates controller fan-out/fan-in for multiple models" do
        ids = stages.map(&:id)
        expect(ids).to include("controllers_fan_out")
        expect(ids).to include("controllers_fan_in")
      end

      it "creates per-resource controller stages" do
        controller_stages = stages.select { |s| s.id.start_with?("controllers_") && !s.id.end_with?("fan_out") && !s.id.end_with?("fan_in") }
        expect(controller_stages.size).to eq(2) # User and Post
      end
    end

    context "with parallel views" do
      it "creates views fan-out/fan-in for multiple models" do
        ids = stages.map(&:id)
        expect(ids).to include("views_fan_out")
        expect(ids).to include("views_fan_in")
      end

      it "creates per-resource view stages" do
        view_stages = stages.select { |s| s.id.start_with?("views_") && !s.id.end_with?("fan_out") && !s.id.end_with?("fan_in") }
        expect(view_stages.size).to eq(2) # User and Post
      end
    end

    context "template setup stages" do
      it "creates template_clone as a tool node" do
        clone = stages.find { |s| s.id == "template_clone" }
        expect(clone.shape).to eq("parallelogram")
        expect(clone.attrs[:tool_command]).to include("git clone")
      end

      it "creates template_customize as a codergen node" do
        customize = stages.find { |s| s.id == "template_customize" }
        expect(customize.shape).to eq("box")
        expect(customize.prompt).to include("Customize")
      end

      it "creates db_setup as a tool node" do
        db = stages.find { |s| s.id == "db_setup" }
        expect(db.shape).to eq("parallelogram")
        expect(db.attrs[:tool_command]).to include("db:create")
      end

      it "creates migrate_verify as a tool node" do
        migrate = stages.find { |s| s.id == "migrate_verify" }
        expect(migrate.shape).to eq("parallelogram")
        expect(migrate.attrs[:tool_command]).to include("db:migrate")
      end

      it "creates routes_verify as a tool node" do
        routes = stages.find { |s| s.id == "routes_verify" }
        expect(routes.shape).to eq("parallelogram")
        expect(routes.attrs[:tool_command]).to include("rails routes")
      end
    end

    context "with service groups" do
      let(:features) do
        (1..6).map { |i|
          NlspecToDot::Parser::FeatureDefinition.new(
            name: "Feature #{i}",
            description: "Description for feature #{i}" * (i > 3 ? 20 : 1),
            related_models: i > 3 ? %w[User Post Comment] : ["User"]
          )
        }
      end
      let(:document) { build(:document, :full, features: features) }

      it "creates service fan-out/fan-in when features are grouped" do
        ids = stages.map(&:id)
        expect(ids).to include("services_fan_out")
        expect(ids).to include("services_fan_in")
      end
    end
  end
end
