# frozen_string_literal: true

require "thor"
require_relative "cli/compile_command"

module NlspecToDot
  class CLI < Thor
    desc "compile SPECFILE", "Compile an NLSpec markdown file into a DOT pipeline"
    option :output, aliases: "-o", desc: "Output file path (default: stdout)"
    option :app_name, desc: "Override the app name from the spec"

    def compile(specfile)
      result = NlspecToDot::CompileCommand.new(
        specfile: specfile,
        output: options[:output],
        app_name: options[:app_name]
      ).call

      if options[:output]
        $stdout.puts "Wrote #{result}"
      else
        $stdout.puts result
      end
    rescue Errno::ENOENT => e
      warn "Error: #{e.message}"
      exit 1
    rescue NlspecToDot::Error => e
      warn "Error: #{e.message}"
      exit 1
    end
  end
end
