# frozen_string_literal: true

module NlspecToDot
  module Planner
    class TopologicalSorter
      class CycleError < NlspecToDot::Error; end

      def self.sort(models)
        new(models).sort
      end

      def initialize(models)
        @models = models
        @by_name = models.each_with_object({}) { |m, h| h[m.name] = m }
      end

      def sort
        in_degree = Hash.new(0)
        @models.each { |m| in_degree[m.name] ||= 0 }

        @models.each do |model|
          model.depends_on.each do |dep|
            next unless @by_name.key?(dep)
            in_degree[model.name] += 1
          end
        end

        queue = @models.select { |m| in_degree[m.name] == 0 }
        sorted = []

        until queue.empty?
          node = queue.shift
          sorted << node

          @models.each do |m|
            next unless m.depends_on.include?(node.name)
            in_degree[m.name] -= 1
            queue << m if in_degree[m.name] == 0
          end
        end

        if sorted.size != @models.size
          raise CycleError, "Cyclic dependency detected among models"
        end

        sorted
      end
    end
  end
end
