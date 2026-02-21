# frozen_string_literal: true

module NlspecToDot
  class CompileCommand
    def initialize(specfile:, output:, app_name:)
      @specfile = specfile
      @output = output
      @app_name = app_name
    end

    def call
      source = File.read(@specfile)
      dot = Compiler.new(source: source, app_name_override: @app_name).call

      if @output
        File.write(@output, dot)
        @output
      else
        dot
      end
    end
  end
end
