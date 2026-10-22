# frozen_string_literal: true

require "spec_helper"

RSpec.describe DevP::Config do
  subject(:config) { described_class.new(data_dir: @tmpdir) }

  it "uses the provided data directory" do
    expect(config.data_dir).to eq(@tmpdir)
  end

  it "creates the data directory if missing" do
    nested = File.join(@tmpdir, "nested", "dir")
    described_class.new(data_dir: nested)
    expect(Dir.exist?(nested)).to be true
  end

  it "exposes file paths under the data directory" do
    expect(config.sessions_file).to eq(File.join(@tmpdir, "sessions.json"))
    expect(config.logs_file).to eq(File.join(@tmpdir, "logs.json"))
    expect(config.timer_file).to eq(File.join(@tmpdir, "timer.json"))
    expect(config.config_file).to eq(File.join(@tmpdir, "config.yml"))
  end

  it "defaults project to 'general'" do
    expect(config.default_project).to eq("general")
  end

  it "persists default_project" do
    config.default_project = "backend"
    expect(config.default_project).to eq("backend")
  end

  it "returns empty settings hash when no config file exists" do
    expect(config.load_settings).to eq({})
  end

  it "returns empty hash for invalid YAML" do
    File.write(config.config_file, "::: invalid yaml :::")
    expect(config.load_settings).to eq({})
  end
end