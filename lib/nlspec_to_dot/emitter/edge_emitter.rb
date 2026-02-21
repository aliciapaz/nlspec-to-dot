# frozen_string_literal: true

module NlspecToDot
  module Emitter
    class EdgeEmitter
      def self.emit(edge)
        new(edge).emit
      end

      def initialize(edge)
        @edge = edge
      end

      def emit
        attrs = build_attrs
        if attrs.empty?
          "    #{@edge[:from]} -> #{@edge[:to]}"
        else
          attr_str = attrs.map { |k, v| "#{k}=\"#{v}\"" }.join(", ")
          "    #{@edge[:from]} -> #{@edge[:to]} [#{attr_str}]"
        end
      end

      private

      def build_attrs
        attrs = {}
        attrs[:label] = @edge[:label] if @edge[:label]
        attrs[:condition] = @edge[:condition] if @edge[:condition]
        attrs
      end
    end
  end
end
