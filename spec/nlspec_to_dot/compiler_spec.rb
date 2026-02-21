# frozen_string_literal: true

require "spec_helper"

RSpec.describe NlspecToDot::Compiler do
  let(:source) { File.read(File.expand_path("../fixtures/simple_blog.md", __dir__)) }

  describe "#call" do
    subject(:dot) { described_class.new(source: source).call }

    it "returns a DOT string" do
      expect(dot).to include("digraph SimpleBlog {")
    end

    it "includes start and exit nodes" do
      expect(dot).to include('shape="Mdiamond"')
      expect(dot).to include('shape="Msquare"')
    end

    it "includes model stages" do
      expect(dot).to include("model_user")
      expect(dot).to include("model_post")
    end

    it "includes edges" do
      expect(dot).to include("->")
    end

    it "respects app_name_override" do
      dot = described_class.new(source: source, app_name_override: "MyBlog").call
      expect(dot).to include("digraph MyBlog {")
    end
  end
end
