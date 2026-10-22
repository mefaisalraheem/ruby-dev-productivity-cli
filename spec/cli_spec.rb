# frozen_string_literal: true

require "spec_helper"
require "stringio"

RSpec.describe DevP::CLI do
  let(:config) { DevP::Config.new(data_dir: @tmpdir) }

  def run(*args)
    out = StringIO.new
    err = StringIO.new
    code = described_class.new(args, config: config, out: out, err: err).run
    [code, out.string, err.string]
  end

  describe "help / version" do
    it "prints help with no args" do
      code, out, _ = run
      expect(code).to eq(0)
      expect(out).to include("USAGE:")
      expect(out).to include("devp")
    end

    it "prints version" do
      code, out, _ = run("version")
      expect(code).to eq(0)
      expect(out).to include(DevP::VERSION)
    end
  end

  describe "start/stop/status" do
    it "starts a timer, reports status, stops it" do
      code, out, _ = run("start", "-p", "api", "-d", "coding")
      expect(code).to eq(0)
      expect(out).to include("Timer started")
      expect(out).to include("api")

      code, out, _ = run("status")
      expect(code).to eq(0)
      expect(out).to include("Running: api")

      code, out, _ = run("stop")
      expect(code).to eq(0)
      expect(out).to include("Timer stopped")
      expect(out).to include("Project:  api")
    end

    it "errors when starting while running" do
      run("start", "-p", "api")
      code, _, err = run("start", "-p", "api")
      expect(code).to eq(1)
      expect(err).to include("already running")
    end

    it "errors stopping when no timer" do
      code, _, err = run("stop")
      expect(code).to eq(1)
      expect(err).to include("No timer running")
    end

    it "reports no timer" do
      code, out, _ = run("status")
      expect(code).to eq(0)
      expect(out).to include("No timer running")
    end
  end

  describe "logs" do
    it "logs an entry and shows it" do
      code, out, _ = run("log", "Shipped feature", "-c", "win")
      expect(code).to eq(0)
      expect(out).to include("Logged [win]")

      code, out, _ = run("logs")
      expect(code).to eq(0)
      expect(out).to include("Shipped feature")
    end

    it "requires a message" do
      code, _, err = run("log")
      expect(code).to eq(1)
      expect(err).to include("Usage:")
    end

    it "reports no logs for a date" do
      code, out, _ = run("logs", "--date", "1999-01-01")
      expect(code).to eq(0)
      expect(out).to include("No logs for 1999-01-01")
    end
  end

  describe "sessions" do
    it "reports when empty" do
      code, out, _ = run("sessions")
      expect(code).to eq(0)
      expect(out).to include("No sessions recorded")
    end

    it "lists a recorded session" do
      run("start", "-p", "api")
      run("stop")
      code, out, _ = run("sessions")
      expect(code).to eq(0)
      expect(out).to include("api")
      expect(out).to include("Total:")
    end
  end

  describe "today" do
    it "shows today's summary" do
      run("start", "-p", "api")
      run("stop")
      run("log", "wrote tests")
      code, out, _ = run("today")
      expect(code).to eq(0)
      expect(out).to include("Sessions: 1")
      expect(out).to include("wrote tests")
    end
  end

  describe "summary" do
    it "aggregates sessions by project" do
      run("start", "-p", "api")
      run("stop")
      code, out, _ = run("summary")
      expect(code).to eq(0)
      expect(out).to include("Total sessions: 1")
      expect(out).to include("api")
    end
  end

  describe "export" do
    it "prints JSON by default" do
      run("start", "-p", "api")
      run("stop")
      code, out, _ = run("export", "json")
      expect(code).to eq(0)
      expect(out).to include("\"sessions\"")
    end

    it "writes markdown to a path" do
      path = File.join(@tmpdir, "report.md")
      code, out, _ = run("export", "markdown", "-o", path)
      expect(code).to eq(0)
      expect(File.exist?(path)).to be true
      expect(out).to include("Exported markdown")
    end

    it "rejects unknown formats" do
      code, _, err = run("export", "xml")
      expect(code).to eq(1)
      expect(err).to include("Unknown export format")
    end
  end

  describe "clear" do
    it "clears all data" do
      run("start", "-p", "api")
      run("stop")
      run("log", "hello")
      run("clear", "all")
      code, out, _ = run("sessions")
      expect(out).to include("No sessions recorded")
    end

    it "rejects unknown target" do
      code, _, err = run("clear", "whatever")
      expect(code).to eq(1)
      expect(err).to include("Unknown target")
    end
  end

  describe "unknown command" do
    it "reports an error" do
      code, _, err = run("frobnicate")
      expect(code).to eq(1)
      expect(err).to include("Unknown command: frobnicate")
    end
  end
end