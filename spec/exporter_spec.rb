# frozen_string_literal: true

require "spec_helper"
require "json"

RSpec.describe DevP::Exporter do
  let(:session_storage) { DevP::Storage.new(File.join(@tmpdir, "sessions.json")) }
  let(:log_storage)     { DevP::Storage.new(File.join(@tmpdir, "logs.json")) }
  let(:exporter)        { described_class.new(session_storage, log_storage) }

  before do
    s = DevP::Session.new(project: "api", description: "fix, \"bug\"",
                          started_at: Time.now - 60)
    s.finish!
    session_storage.append(s.to_h)
    log_storage.append(DevP::LogEntry.new(message: "shipped").to_h)
  end

  describe "#export_json" do
    it "returns valid JSON containing sessions and logs" do
      output = exporter.export_json
      data   = JSON.parse(output)
      expect(data["sessions"].size).to eq(1)
      expect(data["logs"].size).to eq(1)
    end

    it "writes to a file when path given" do
      path = File.join(@tmpdir, "out.json")
      result = exporter.export_json(path: path)
      expect(result).to eq(path)
      expect(File.exist?(path)).to be true
    end
  end

  describe "#export_csv" do
    it "produces CSV with header and data" do
      output = exporter.export_csv
      expect(output.lines.first.strip).to eq("id,project,description,started_at,ended_at,duration_seconds")
      expect(output).to include("api")
      expect(output).to include("\"fix, \"\"bug\"\"\"")
    end
  end

  describe "#export_markdown" do
    it "produces a markdown report" do
      output = exporter.export_markdown
      expect(output).to include("# Developer Productivity Report")
      expect(output).to include("## Sessions (1)")
      expect(output).to include("## Daily Log (1)")
      expect(output).to include("shipped")
    end

    it "handles empty data" do
      session_storage.clear
      log_storage.clear
      output = exporter.export_markdown
      expect(output).to include("_No sessions recorded._")
      expect(output).to include("_No logs recorded._")
    end
  end
end