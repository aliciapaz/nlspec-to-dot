# frozen_string_literal: true

module NlspecToDot
  class Compiler
    def initialize(source:, app_name_override: nil)
      @source = source
      @app_name_override = app_name_override
    end

    def call
      document = Parser::SpecParser.parse(@source)
      plan = Planner::StagePlanner.new(document: document).call
      app_name = @app_name_override || document.app_name

      Emitter::DotEmitter.new(
        app_name: app_name,
        stages: plan[:stages],
        edges: plan[:edges],
        goal: document.description
      ).call
    end
  end
end
