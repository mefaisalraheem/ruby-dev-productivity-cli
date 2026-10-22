# frozen_string_literal: true

require "spec_helper"

RSpec.describe DevP::Timer do
  let(:timer_storage)   { DevP::Storage.new(File.join(@tmpdir, "timer.json")) }
  let(:session_storage) { DevP::Storage.new(File.join(@tmpdir, "sessions.json")) }
  let(:timer)           { described_class.new(timer_storage, session_storage) }

  describe "#start" do
    it "stores timer state" do
      timer.start(project: "api", description: "coding")
      expect(timer.running?).to be true
      expect(timer.current["project"]).to eq("api")
    end

    it "raises if already running" do
      timer.start(project: "api")
      expect { timer.start(project: "api") }.to raise_error(DevP::Error, /already running/)
    end
  end

  describe "#stop" do
    it "raises when no timer" do
      expect { timer.stop }.to raise_error(DevP::Error, /No timer running/)
    end

    it "creates a session and clears timer" do
      timer.start(project: "api", description: "coding")
      session = timer.stop
      expect(session.project).to eq("api")
      expect(session.finished?).to be true
      expect(timer.running?).to be false
      expect(session_storage.read.size).to eq(1)
    end
  end

  describe "#elapsed_seconds" do
    it "returns 0 when not running" do
      expect(timer.elapsed_seconds).to eq(0)
    end

    it "returns positive value after start" do
      timer.start(project: "api")
      expect(timer.elapsed_seconds).to be >= 0
    end
  end
end