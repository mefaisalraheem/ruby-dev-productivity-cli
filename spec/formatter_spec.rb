# frozen_string_literal: true

require "spec_helper"

RSpec.describe DevP::Formatter do
  describe ".format_duration" do
    it "handles zero"        { expect(described_class.format_duration(0)).to eq("0s") }
    it "handles nil"         { expect(described_class.format_duration(nil)).to eq("0s") }
    it "formats seconds"     { expect(described_class.format_duration(45)).to eq("45s") }
    it "formats minutes"     { expect(described_class.format_duration(120)).to eq("2m") }
    it "formats hours"       { expect(described_class.format_duration(3600)).to eq("1h") }
    it "formats full string" { expect(described_class.format_duration(3661)).to eq("1h 1m 1s") }
  end

  describe ".format_table" do
    it "returns empty string for empty rows" do
      expect(described_class.format_table([], ["A"])).to eq("")
    end

    it "produces a formatted table" do
      rows   = [["1", "api", "1h"]]
      output = described_class.format_table(rows, ["ID", "Project", "Time"])
      expect(output).to include("ID")
      expect(output).to include("api")
      expect(output).to include("---")
    end
  end

  describe ".truncate" do
    it "keeps short strings" do
      expect(described_class.truncate("hello", 10)).to eq("hello")
    end

    it "truncates long strings" do
      expect(described_class.truncate("hello world", 8)).to eq("hello...")
    end
  end
end