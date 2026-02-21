# frozen_string_literal: true

module NlspecToDot
  module Emitter
    class DotEmitter
      def initialize(app_name:, stages:, edges:, goal:)
        @app_name = app_name
        @stages = stages
        @edges = edges
        @goal = goal
      end

      def call
        lines = []
        lines << "digraph #{sanitize_name(@app_name)} {"
        lines << graph_attrs
        lines << node_defaults
        lines << ""
        @stages.each { |s| lines << NodeEmitter.emit(s) }
        lines << ""
        @edges.each { |e| lines << EdgeEmitter.emit(e) }
        lines << "}"
        lines.join("\n") + "\n"
      end

      private

      def graph_attrs
        goal_escaped = @goal.gsub('"', '\\"')
        "    graph [goal=\"#{goal_escaped}\", rankdir=\"LR\"]"
      end

      def node_defaults
        '    node [shape="box"]'
      end

      def sanitize_name(name)
        name.gsub(/[^a-zA-Z0-9_]/, "_")
      end
    end
  end
end
