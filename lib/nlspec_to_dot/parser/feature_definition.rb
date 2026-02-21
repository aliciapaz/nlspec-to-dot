# frozen_string_literal: true

module NlspecToDot
  module Parser
    class FeatureDefinition
      attr_reader :name, :description, :related_models

      def initialize(name:, description:, related_models: [])
        @name = name.freeze
        @description = description.freeze
        @related_models = related_models.freeze
      end

      def ==(other)
        name == other.name &&
          description == other.description &&
          related_models == other.related_models
      end
    end
  end
end
