# frozen_string_literal: true

require "spec_helper"

RSpec.describe DevP::Storage do
  let(:path)    { File.join(@tmpdir, "data.json") }
  let(:storage) { described_class.new(path) }

  describe "#read" do
    it "returns empty array when file is missing" do
      expect(storage.read).to eq([])
    end

    it "returns empty array when file is blank" do
      File.write(path, "")
      expect(storage.read).to eq([])
    end

    it "returns empty array on invalid JSON" do
      File.write(path, "{not json")
      expect(storage.read).to eq([])
    end

    it "parses valid JSON" do
      File.write(path, '[{"a":1}]')
      expect(storage.read).to eq([{ "a" => 1 }])
    end
  end

  describe "#write / #append" do
    it "writes data and creates directories" do
      nested = File.join(@tmpdir, "a", "b", "data.json")
      s = described_class.new(nested)
      s.write([{ "x" => 1 }])
      expect(File.exist?(nested)).to be true
      expect(s.read).to eq([{ "x" => 1 }])
    end

    it "appends records" do
      storage.append({ "id" => 1 })
      storage.append({ "id" => 2 })
      expect(storage.read).to eq([{ "id" => 1 }, { "id" => 2 }])
    end
  end

  describe "#clear" do
    it "empties the file" do
      storage.append({ "id" => 1 })
      storage.clear
      expect(storage.read).to eq([])
    end
  end

  describe "#exist?" do
    it "reflects presence of file" do
      expect(storage.exist?).to be false
      storage.write([])
      expect(storage.exist?).to be true
    end
  end
end