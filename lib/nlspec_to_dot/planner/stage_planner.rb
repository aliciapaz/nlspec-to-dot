# frozen_string_literal: true

module NlspecToDot
  module Planner
    class StagePlanner
      attr_reader :stages, :edges

      def initialize(document:)
        @document = document
        @prompt_builder = PromptBuilder.new(document: document)
        @template_builder = TemplateCommandBuilder.new(document: document)
        @stages = []
        @edges = []
      end

      def call
        build_start
        build_template_clone
        build_template_customize
        build_db_setup
        build_install_assets
        build_parallel_models
        build_migrate_verify
        build_routes
        build_routes_verify
        build_parallel_controllers
        build_parallel_services
        build_seeds
        build_parallel_views
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

      def build_template_clone
        add_stage(
          id: "template_clone",
          label: "Clone Template",
          shape: "parallelogram",
          attrs: {tool_command: @template_builder.clone_command, timeout: "5m"}
        )
        add_edge("start", "template_clone")
      end

      def build_template_customize
        add_stage(
          id: "template_customize",
          label: "Customize Template",
          shape: "box",
          prompt: @prompt_builder.template_customize_prompt
        )
        add_edge("template_clone", "template_customize")
      end

      def build_db_setup
        add_stage(
          id: "db_setup",
          label: "Database Setup",
          shape: "parallelogram",
          attrs: {tool_command: @template_builder.db_setup_command, timeout: "5m"}
        )
        add_edge("template_customize", "db_setup")
      end

      def build_install_assets
        command = @template_builder.install_assets_command
        return unless command

        add_stage(
          id: "install_assets",
          label: "Install Assets",
          shape: "parallelogram",
          attrs: {tool_command: command, timeout: "5m"}
        )
        add_edge("db_setup", "install_assets")
        @last_setup_id = "install_assets"
      end

      def build_parallel_models
        prev_id = @last_setup_id || "db_setup"
        batches = TopologicalSorter.batch(@document.models)

        batches.each_with_index do |batch, batch_idx|
          prev_id = build_model_batch(batch, batch_idx, prev_id)
        end

        @last_model_id = prev_id
      end

      def build_migrate_verify
        add_stage(
          id: "migrate_verify",
          label: "Verify Migrations",
          shape: "parallelogram",
          attrs: {tool_command: @template_builder.migrate_verify_command, timeout: "3m"}
        )
        add_edge(@last_model_id, "migrate_verify")
      end

      def build_routes
        add_stage(
          id: "routes",
          label: "Routes",
          shape: "box",
          prompt: @prompt_builder.routes_prompt
        )
        add_edge("migrate_verify", "routes")
      end

      def build_routes_verify
        add_stage(
          id: "routes_verify",
          label: "Verify Routes",
          shape: "parallelogram",
          attrs: {tool_command: @template_builder.routes_verify_command, timeout: "1m"}
        )
        add_edge("routes", "routes_verify")
      end

      def build_parallel_controllers
        models = @document.models
        prev_id = "routes_verify"

        if models.size > 1
          prev_id = build_parallel_group(
            items: models,
            group_id: "controllers",
            label_prefix: "Controller",
            prompt_method: :controllers_prompt_for,
            prev_id: prev_id
          )
        else
          models.each do |model|
            stage_id = "controller_#{model.name.downcase}"
            add_stage(
              id: stage_id,
              label: "Controller: #{model.name}",
              shape: "box",
              prompt: @prompt_builder.controllers_prompt_for(model)
            )
            add_edge(prev_id, stage_id)
            prev_id = stage_id
          end
        end

        @last_controller_id = prev_id
      end

      def build_parallel_services
        groups = @prompt_builder.group_features_for_services(@document.features)
        prev_id = @last_controller_id

        if groups.size > 1
          fan_out_id = "services_fan_out"
          fan_in_id = "services_fan_in"

          add_stage(id: fan_out_id, label: "Services Fan Out", shape: "component",
            attrs: {max_parallel: [groups.size, 4].min})
          add_edge(prev_id, fan_out_id)

          groups.each_with_index do |group, idx|
            stage_id = "services_group_#{idx}"
            names = group.map(&:name).join(", ")
            add_stage(
              id: stage_id,
              label: "Services: #{names}",
              shape: "box",
              prompt: @prompt_builder.services_prompt_for(group)
            )
            add_edge(fan_out_id, stage_id)
            add_edge(stage_id, fan_in_id)
          end

          add_stage(id: fan_in_id, label: "Services Fan In", shape: "tripleoctagon")
          prev_id = fan_in_id
        else
          stage_id = "services"
          features = groups.first || @document.features
          add_stage(
            id: stage_id,
            label: "Service Objects",
            shape: "box",
            prompt: @prompt_builder.services_prompt_for(features)
          )
          add_edge(prev_id, stage_id)
          prev_id = stage_id
        end

        @last_services_id = prev_id
      end

      def build_seeds
        return unless has_seeds?

        add_stage(
          id: "seeds",
          label: "Seeds",
          shape: "box",
          prompt: @prompt_builder.seeds_prompt
        )
        add_edge(@last_services_id, "seeds")
        @last_services_id = "seeds"
      end

      def build_parallel_views
        models = @document.models
        prev_id = @last_services_id

        if models.size > 1
          prev_id = build_parallel_group(
            items: models,
            group_id: "views",
            label_prefix: "Views",
            prompt_method: :views_prompt_for,
            prev_id: prev_id
          )
        else
          models.each do |model|
            stage_id = "views_#{model.name.downcase}"
            add_stage(
              id: stage_id,
              label: "Views: #{model.name}",
              shape: "box",
              prompt: @prompt_builder.views_prompt_for(model)
            )
            add_edge(prev_id, stage_id)
            prev_id = stage_id
          end
        end

        @last_views_id = prev_id
      end

      def build_tests
        add_stage(
          id: "tests",
          label: "Write Tests",
          shape: "box",
          prompt: @prompt_builder.tests_prompt
        )
        add_edge(@last_views_id, "tests")
      end

      def build_run_tests
        add_stage(
          id: "run_tests",
          label: "Run Tests",
          shape: "parallelogram",
          attrs: {tool_command: "bundle exec rspec", timeout: "5m"}
        )
        add_edge("tests", "run_tests")
      end

      def build_test_gate
        add_stage(id: "test_gate", label: "Tests Passing?", shape: "diamond")
        add_edge("run_tests", "test_gate")
        add_edge("test_gate", "tests", label: "Retry", condition: "outcome!=success")
        add_edge("test_gate", "human_review", label: "Pass", condition: "outcome=success")
      end

      def build_human_review
        add_stage(id: "human_review", label: "Human Review", shape: "hexagon")
        add_edge("human_review", "exit", label: "[A] Approve")
        add_edge("human_review", "tests", label: "[F] Request Fixes")
      end

      def build_exit
        add_stage(id: "exit", label: "Exit", shape: "Msquare")
      end

      # --- Parallel helpers ---

      def build_model_batch(batch, batch_idx, prev_id)
        if batch.size == 1
          build_single_model(batch.first, prev_id, batch_idx)
        else
          build_parallel_model_batch(batch, batch_idx, prev_id)
        end
      end

      def build_single_model(model, prev_id, _batch_idx)
        stage_id = "model_#{model.name.downcase}"
        add_stage(
          id: stage_id,
          label: "Model: #{model.name}",
          shape: "box",
          prompt: @prompt_builder.model_prompt(model),
          attrs: {goal_gate: true, retry_target: prev_id}
        )
        add_edge(prev_id, stage_id)
        stage_id
      end

      def build_parallel_model_batch(batch, batch_idx, prev_id)
        fan_out_id = "models_batch_#{batch_idx}_fan_out"
        fan_in_id = "models_batch_#{batch_idx}_fan_in"

        add_stage(id: fan_out_id, label: "Models Batch #{batch_idx + 1}", shape: "component",
          attrs: {max_parallel: [batch.size, 4].min})
        add_edge(prev_id, fan_out_id)

        batch.each do |model|
          stage_id = "model_#{model.name.downcase}"
          add_stage(
            id: stage_id,
            label: "Model: #{model.name}",
            shape: "box",
            prompt: @prompt_builder.model_prompt(model),
            attrs: {goal_gate: true, retry_target: fan_out_id}
          )
          add_edge(fan_out_id, stage_id)
          add_edge(stage_id, fan_in_id)
        end

        add_stage(id: fan_in_id, label: "Models Batch #{batch_idx + 1} Done", shape: "tripleoctagon")
        fan_in_id
      end

      def build_parallel_group(items:, group_id:, label_prefix:, prompt_method:, prev_id:)
        fan_out_id = "#{group_id}_fan_out"
        fan_in_id = "#{group_id}_fan_in"

        add_stage(id: fan_out_id, label: "#{label_prefix} Fan Out", shape: "component",
          attrs: {max_parallel: [items.size, 4].min})
        add_edge(prev_id, fan_out_id)

        items.each do |item|
          stage_id = "#{group_id}_#{item.name.downcase}"
          add_stage(
            id: stage_id,
            label: "#{label_prefix}: #{item.name}",
            shape: "box",
            prompt: @prompt_builder.send(prompt_method, item)
          )
          add_edge(fan_out_id, stage_id)
          add_edge(stage_id, fan_in_id)
        end

        add_stage(id: fan_in_id, label: "#{label_prefix} Fan In", shape: "tripleoctagon")
        fan_in_id
      end

      def has_seeds?
        @document.seeds.any?
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
