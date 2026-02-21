# frozen_string_literal: true

require "spec_helper"

RSpec.describe NlspecToDot::Emitter::EdgeEmitter do
  describe ".emit" do
    it "emits a simple edge" do
      result = described_class.emit({from: "a", to: "b"})
      expect(result.strip).to eq("a -> b")
    end

    it "emits an edge with label" do
      result = described_class.emit({from: "a", to: "b", label: "Yes"})
      expect(result).to include('label="Yes"')
    end

    it "emits an edge with condition" do
      result = described_class.emit({from: "gate", to: "retry", condition: "outcome!=success"})
      expect(result).to include('condition="outcome!=success"')
    end

    it "emits an edge with both label and condition" do
      result = described_class.emit({from: "gate", to: "next", label: "Pass", condition: "outcome=success"})
      expect(result).to include('label="Pass"')
      expect(result).to include('condition="outcome=success"')
    end
  end
end
