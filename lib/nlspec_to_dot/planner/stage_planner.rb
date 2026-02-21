# frozen_string_literal: true

module NlspecToDot
  module Planner
    class StagePlanner
      attr_reader :stages, :edges

      def initialize(document:)
        @document = document
        @prompt_builder = PromptBuilder.new(document: document)
        @stages = []
        @edges = []
      end

      def call
        build_start
        build_scaffold
        build_models
        build_routes
        build_controllers
        build_services
        build_views
        build_tests
        build_run_tests
        build_test_gate
        build_human_review
        build_exit

        {stages: @stages, edges: @edges}
      end

      private

      def build_start
        add_stage(id: "start", label: "Start", shape: "Mdiamond")
      end

      def build_scaffold
        add_stage(
          id: "scaffold",
          label: "Scaffold App",
          shape: "box",
          prompt: @prompt_builder.scaffold_prompt
        )
        add_edge("start", "scaffold")
      end

      def build_models
        sorted = TopologicalSorter.sort(@document.models)
        prev_id = "scaffold"

        sorted.each_with_index do |model, idx|
          stage_id = "model_#{model.name.downcase}"
          retry_target = (idx == 0) ? "scaffold" : "model_#{sorted[idx - 1].name.downcase}"

          add_stage(
            id: stage_id,
            label: "Model: #{model.name}",
            shape: "box",
            prompt: @prompt_builder.model_prompt(model),
            attrs: {goal_gate: true, retry_target: retry_target}
          )
          add_edge(prev_id, stage_id)
          prev_id = stage_id
        end

        @last_model_id = prev_id
      end

      def build_routes
        add_stage(
          id: "routes",
          label: "Routes",
          shape: "box",
          prompt: @prompt_builder.routes_prompt
        )
        add_edge(@last_model_id, "routes")
      end

      def build_controllers
        add_stage(
          id: "controllers",
          label: "Controllers & Policies",
          shape: "box",
          prompt: @prompt_builder.controllers_prompt
        )
        add_edge("routes", "controllers")
      end

      def build_services
        add_stage(
          id: "services",
          label: "Service Objects",
          shape: "box",
          prompt: @prompt_builder.services_prompt
        )
        add_edge("controllers", "services")
      end

      def build_views
        add_stage(
          id: "views",
          label: "Views & Frontend",
          shape: "box",
          prompt: @prompt_builder.views_prompt
        )
        add_edge("services", "views")
      end

      def build_tests
        add_stage(
          id: "tests",
          label: "Write Tests",
          shape: "box",
          prompt: @prompt_builder.tests_prompt
        )
        add_edge("views", "tests")
      end

      def build_run_tests
        add_stage(
          id: "run_tests",
          label: "Run Tests",
          shape: "parallelogram",
          prompt: "bundle exec rspec"
        )
        add_edge("tests", "run_tests")
      end

      def build_test_gate
        add_stage(
          id: "test_gate",
          label: "Tests Passing?",
          shape: "diamond"
        )
        add_edge("run_tests", "test_gate")
        add_edge("test_gate", "tests", label: "Retry", condition: "outcome!=success")
        add_edge("test_gate", "human_review", label: "Pass", condition: "outcome=success")
      end

      def build_human_review
        add_stage(
          id: "human_review",
          label: "Human Review",
          shape: "hexagon"
        )
        add_edge("human_review", "exit", label: "[A] Approve")
        add_edge("human_review", "tests", label: "[F] Request Fixes")
      end

      def build_exit
        add_stage(id: "exit", label: "Exit", shape: "Msquare")
      end

      def add_stage(id:, label:, shape:, prompt: nil, attrs: {})
        @stages << Stage.new(id: id, label: label, shape: shape, prompt: prompt, attrs: attrs)
      end

      def add_edge(from, to, label: nil, condition: nil)
        edge = {from: from, to: to}
        edge[:label] = label if label
        edge[:condition] = condition if condition
        @edges << edge
      end
    end
  end
end
