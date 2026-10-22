# frozen_string_literal: true

require "yaml"
require "fileutils"

module DevP
  class Config
    DEFAULT_DIR = File.expand_path("~/.devp")

    attr_reader :data_dir

    def initialize(data_dir: nil)
      @data_dir = data_dir || ENV["DEVP_HOME"] || DEFAULT_DIR
      FileUtils.mkdir_p(@data_dir)
    end

    def sessions_file
      File.join(@data_dir, "sessions.json")
    end

    def logs_file
      File.join(@data_dir, "logs.json")
    end

    def timer_file
      File.join(@data_dir, "timer.json")
    end

    def config_file
      File.join(@data_dir, "config.yml")
    end

    def load_settings
      return {} unless File.exist?(config_file)

      YAML.safe_load(File.read(config_file)) || {}
    rescue Psych::SyntaxError
      {}
    end

    def save_settings(settings)
      File.write(config_file, settings.to_yaml)
    end

    def default_project
      load_settings["default_project"] || "general"
    end

    def default_project=(value)
      settings = load_settings
      settings["default_project"] = value
      save_settings(settings)
    end
  end
end