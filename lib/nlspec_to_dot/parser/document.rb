# frozen_string_literal: true

module NlspecToDot
  module Parser
    class Document
      attr_reader :app_name, :description, :models, :features, :constraints

      def initialize(app_name:, description: "", models: [], features: [], constraints: [])
        @app_name = app_name.freeze
        @description = description.freeze
        @models = models.freeze
        @features = features.freeze
        @constraints = constraints.freeze
      end
    end
  end
end
