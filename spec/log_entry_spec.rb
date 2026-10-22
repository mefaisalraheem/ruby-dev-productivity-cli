# frozen_string_literal: true

require "spec_helper"

RSpec.describe DevP::LogEntry do
  it "requires a message" do
    entry = described_class.new(message: "Wrote tests")
    expect(entry.message).to eq("Wrote tests")
  end

  it "defaults category to 'note'" do
    expect(described_class.new(message: "x").category).to eq("note")
  end

  it "defaults date to today" do
    expect(described_class.new(message: "x").date).to eq(Time.now.strftime("%Y-%m-%d"))
  end

  it "accepts known categories" do
    %w[note blocker win todo idea].each do |cat|
      expect { described_class.new(message: "x", category: cat) }.not_to raise_error
    end
  end

  it "rejects unknown categories" do
    expect {
      described_class.new(message: "x", category: "rant")
    }.to raise_error(DevP::Error, /Unknown category/)
  end

  it "round-trips through to_h/from_h" do
    entry = described_class.new(message: "shipped v1", category: "win",
                                date: "2024-01-15")
    restored = described_class.from_h(entry.to_h)
    expect(restored.message).to eq("shipped v1")
    expect(restored.category).to eq("win")
    expect(restored.date).to eq("2024-01-15")
  end
end