# frozen_string_literal: true

require_relative "nlspec_to_dot/version"

module NlspecToDot
  class Error < StandardError; end
end

require_relative "nlspec_to_dot/parser/constraint_definition"
require_relative "nlspec_to_dot/parser/feature_definition"
require_relative "nlspec_to_dot/parser/model_definition"
require_relative "nlspec_to_dot/parser/document"
require_relative "nlspec_to_dot/parser/spec_parser"

require_relative "nlspec_to_dot/planner/stage"
require_relative "nlspec_to_dot/planner/telos_context"
require_relative "nlspec_to_dot/planner/topological_sorter"
require_relative "nlspec_to_dot/planner/prompt_builder"
require_relative "nlspec_to_dot/planner/scaffold_command_builder"
require_relative "nlspec_to_dot/planner/stage_planner"

require_relative "nlspec_to_dot/emitter/node_emitter"
require_relative "nlspec_to_dot/emitter/edge_emitter"
require_relative "nlspec_to_dot/emitter/dot_emitter"

require_relative "nlspec_to_dot/compiler"
