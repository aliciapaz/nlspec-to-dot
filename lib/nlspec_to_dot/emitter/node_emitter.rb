# frozen_string_literal: true

module NlspecToDot
  module Emitter
    class NodeEmitter
      def self.emit(stage)
        new(stage).emit
      end

      def initialize(stage)
        @stage = stage
      end

      def emit
        attrs = base_attrs.merge(extra_attrs)
        attr_str = attrs.map { |k, v| format_attr(k, v) }.join(", ")
        "    #{@stage.id} [#{attr_str}]"
      end

      private

      def base_attrs
        attrs = {label: @stage.label, shape: @stage.shape}
        attrs[:prompt] = @stage.prompt if @stage.prompt
        attrs
      end

      def extra_attrs
        @stage.attrs.transform_keys(&:to_sym)
      end

      def format_attr(key, value)
        case value
        when true then "#{key}=true"
        when false then "#{key}=false"
        when Integer then "#{key}=#{value}"
        else
          "#{key}=#{quote(value.to_s)}"
        end
      end

      def quote(str)
        escaped = str.gsub("\\", "\\\\\\\\").gsub('"', '\\"')
        "\"#{escaped}\""
      end
    end
  end
end
