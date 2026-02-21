# frozen_string_literal: true

module NlspecToDot
  module Planner
    module TelosContext
      module_function

      def for_models
        <<~TELOS
          Follow Telos model conventions:
          - Focus on persistence, associations, and data integrity only
          - Validations for database constraints
          - Callbacks only for persistence concerns (e.g., before_validation :set_defaults)
          - Use store_accessor for JSONB column accessors
          - Query scopes for common filters
          - NO business logic — move to services
          - Max 100 lines per class
        TELOS
      end

      def for_controllers
        <<~TELOS
          Follow Telos controller conventions:
          - Maximum 30-50 lines — if longer, extract to service objects
          - Instantiate services, never put business logic directly in controllers
          - Use strong parameters with params.expect() pattern
          - Include concerns for cross-cutting behavior (authentication, tracking)
          - Handle service errors and provide user feedback
          - Delegate authorization to policies (ActionPolicy): authorize! @resource
        TELOS
      end

      def for_services
        <<~TELOS
          Follow Telos service object conventions:
          - Name with action + "Service" or "Creator"
          - Pattern A: call method for operations that return data
          - Pattern B: save method for operations that persist data (returns true/false)
          - Include ActiveModel::Model for validations when needed
          - Define custom error classes: class Error < StandardError; end
          - Use attr_accessor for dependencies passed in initialize
          - Wrap database changes in ActiveRecord::Base.transaction blocks
          - Let exceptions bubble up with meaningful error messages
        TELOS
      end

      def for_views
        <<~TELOS
          Follow Telos frontend conventions (Hotwire):
          - Default to server-side rendering — let Rails handle the HTML
          - Use Turbo Frames for isolated page sections (modals, inline editing, lazy-loaded content)
          - Use Turbo Streams for real-time updates (append, prepend, replace, update, remove)
          - Stimulus controllers: small, focused, single responsibility
          - Use data attributes for configuration, not hardcoded values
          - No jQuery, React, Vue — stick to Stimulus for interactions
          - Progressive enhancement: site works without JS, better with it
        TELOS
      end

      def for_tests
        <<~TELOS
          Follow Telos testing conventions:
          - RSpec with FactoryBot
          - Prefer request specs over system specs (faster, more reliable)
          - Only use system specs when testing complex JS interactions
          - Use let and before blocks, avoid fixtures
          - Test critical paths and edge cases
        TELOS
      end

      def general
        <<~TELOS
          Follow Telos code quality thresholds:
          - Target 5-7 lines per method (hard limit: 10)
          - Cyclomatic complexity max 7, perceived complexity max 8
          - ABC size max 17
          - Max 100 lines per class
          - Favor many small methods over few large ones
          - Method names should describe what they return or do
          - One level of abstraction per method
        TELOS
      end

      def for_authorization
        <<~TELOS
          Follow Telos authorization conventions:
          - Use ActionPolicy (not Pundit or CanCanCan)
          - Policy naming: ResourcePolicy (e.g., ListingPolicy, UserPolicy)
          - Define methods matching controller actions: create?, update?, destroy?
          - Controller usage: authorize! @resource
          - Rescue unauthorized: rescue_from ActionPolicy::Unauthorized
          - Check ownership and feature flags in policies
        TELOS
      end
    end
  end
end
