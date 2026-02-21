# frozen_string_literal: true

module NlspecToDot
  module Parser
    class ConstraintDefinition
      attr_reader :key, :value

      def initialize(key:, value:)
        @key = key.freeze
        @value = value.freeze
      end

      def ==(other)
        key == other.key && value == other.value
      end
    end
  end
end
