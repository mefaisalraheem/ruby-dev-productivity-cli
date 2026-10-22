# frozen_string_literal: true

require "spec_helper"

RSpec.describe DevP::Session do
  describe "#initialize" do
    it "generates an id" do
      s = described_class.new(project: "api")
      expect(s.id).to match(/\A[a-f0-9]{12}\z/)
    end

    it "defaults started_at to now" do
      before = Time.now
      s = described_class.new(project: "api")
      expect(s.started_at).to be >= before - 1
      expect(s.started_at).to be <= Time.now + 1
    end

    it "does not allow non-string descriptions to leak through" do
      s = described_class.new(project: "api", description: nil)
      expect(s.description).to eq("")
    end
  end

  describe "#finish!" do
    it "sets ended_at and duration" do
      started = Time.now - 120
      s = described_class.new(project: "api", started_at: started)
      s.finish!(end_time: Time.now)
      expect(s.finished?).to be true
      expect(s.duration_seconds).to be_within(3).of(120)
    end
  end

  describe "#duration_human" do
    it "returns 'running' when not finished" do
      s = described_class.new(project: "api")
      expect(s.duration_human).to eq("running")
    end

    it "formats hours, minutes, seconds" do
      s = described_class.new(project: "api")
      s.instance_variable_set(:@duration_seconds, 3661)
      expect(s.duration_human).to eq("1h 1m 1s")
    end
  end

  describe "serialization" do
    it "round-trips through to_h/from_h" do
      s = described_class.new(project: "web", description: "fix bug",
                              started_at: Time.now - 60)
      s.finish!(end_time: Time.now)
      restored = described_class.from_h(s.to_h)
      expect(restored.id).to eq(s.id)
      expect(restored.project).to eq("web")
      expect(restored.duration_seconds).to eq(s.duration_seconds)
    end
  end
end