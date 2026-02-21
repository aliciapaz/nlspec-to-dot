# frozen_string_literal: true

module NlspecToDot
  module Planner
    class Stage
      attr_reader :id, :label, :shape, :prompt, :attrs

      def initialize(id:, label:, shape:, prompt: nil, attrs: {})
        @id = id.freeze
        @label = label.freeze
        @shape = shape.freeze
        @prompt = prompt&.freeze
        @attrs = attrs.freeze
      end

      def ==(other)
        id == other.id && shape == other.shape
      end
    end
  end
end
