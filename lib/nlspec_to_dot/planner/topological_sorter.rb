# frozen_string_literal: true

module NlspecToDot
  module Planner
    class TopologicalSorter
      class CycleError < NlspecToDot::Error; end

      def self.sort(models)
        new(models).sort
      end

      def self.batch(models)
        new(models).batch
      end

      def initialize(models)
        @models = models
        @by_name = models.each_with_object({}) { |m, h| h[m.name] = m }
      end

      def sort
        batch.flatten
      end

      def batch
        in_degree = compute_in_degrees
        remaining = @models.dup
        batches = []

        until remaining.empty?
          ready = remaining.select { |m| in_degree[m.name] == 0 }
          raise CycleError, "Cyclic dependency detected among models" if ready.empty?

          batches << ready
          remaining -= ready

          ready.each do |done|
            remaining.each do |m|
              in_degree[m.name] -= 1 if m.depends_on.include?(done.name)
            end
          end
        end

        batches
      end

      private

      def compute_in_degrees
        in_degree = Hash.new(0)
        @models.each { |m| in_degree[m.name] ||= 0 }

        @models.each do |model|
          model.depends_on.each do |dep|
            next unless @by_name.key?(dep)
            in_degree[model.name] += 1
          end
        end

        in_degree
      end
    end
  end
end
