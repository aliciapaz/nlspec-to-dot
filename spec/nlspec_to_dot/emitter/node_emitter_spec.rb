# frozen_string_literal: true

require "spec_helper"

RSpec.describe NlspecToDot::Emitter::NodeEmitter do
  describe ".emit" do
    it "emits a start node" do
      stage = build(:stage, :start)
      result = described_class.emit(stage)

      expect(result).to include("start")
      expect(result).to include('shape="Mdiamond"')
    end

    it "emits a box node with prompt" do
      stage = build(:stage, id: "scaffold", label: "Scaffold", shape: "box", prompt: "Do stuff")
      result = described_class.emit(stage)

      expect(result).to include("scaffold")
      expect(result).to include('prompt="Do stuff"')
    end

    it "escapes quotes in prompts" do
      stage = build(:stage, prompt: 'Say "hello"')
      result = described_class.emit(stage)

      expect(result).to include('Say \\"hello\\"')
    end

    it "includes extra attrs" do
      stage = build(:stage, attrs: {goal_gate: true, retry_target: "prev"})
      result = described_class.emit(stage)

      expect(result).to include("goal_gate=true")
      expect(result).to include('retry_target="prev"')
    end

    it "emits a conditional node without prompt" do
      stage = build(:stage, :conditional)
      result = described_class.emit(stage)

      expect(result).to include('shape="diamond"')
      expect(result).not_to include("prompt=")
    end
  end
end
