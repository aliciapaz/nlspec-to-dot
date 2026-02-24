# frozen_string_literal: true

module NlspecToDot
  module Parser
    class ModelDefinition
      attr_reader :name, :fields, :associations, :validations, :enums, :attachments

      def initialize(name:, fields: [], associations: [], validations: [], enums: [], attachments: [])
        @name = name.freeze
        @fields = fields.freeze
        @associations = associations.freeze
        @validations = validations.freeze
        @enums = enums.freeze
        @attachments = attachments.freeze
      end

      def depends_on
        associations
          .select { |a| a[:kind] == :belongs_to }
          .map { |a| a[:target] }
      end

      def ==(other)
        name == other.name &&
          fields == other.fields &&
          associations == other.associations &&
          validations == other.validations &&
          enums == other.enums &&
          attachments == other.attachments
      end
    end
  end
end
