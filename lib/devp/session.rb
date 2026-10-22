# frozen_string_literal: true

require "securerandom"
require "time"

module DevP
  class Session
    attr_reader :id, :project, :description, :started_at, :ended_at, :duration_seconds

    def initialize(project:, description: "", started_at: nil, ended_at: nil,
                   duration_seconds: nil, id: nil)
      @id               = id || SecureRandom.hex(6)
      @project          = project
      @description      = description.to_s
      @started_at       = parse_time(started_at) || Time.now
      @ended_at         = parse_time(ended_at)
      @duration_seconds = duration_seconds
    end

    def finish!(end_time: Time.now)
      @ended_at = end_time
      @duration_seconds = (@ended_at - @started_at).to_i
      self
    end

    def finished?
      !@ended_at.nil?
    end

    def duration_human
      return "running" unless duration_seconds

      format_seconds(duration_seconds)
    end

    def to_h
      {
        "id"               => id,
        "project"          => project,
        "description"      => description,
        "started_at"       => started_at.iso8601,
        "ended_at"         => ended_at&.iso8601,
        "duration_seconds" => duration_seconds
      }
    end

    def self.from_h(hash)
      new(
        id:               hash["id"],
        project:          hash["project"],
        description:      hash["description"],
        started_at:       hash["started_at"],
        ended_at:         hash["ended_at"],
        duration_seconds: hash["duration_seconds"]
      )
    end

    private

    def parse_time(value)
      return nil if value.nil?
      return value if value.is_a?(Time)

      Time.parse(value)
    rescue ArgumentError
      nil
    end

    def format_seconds(total)
      hours   = total / 3600
      minutes = (total % 3600) / 60
      seconds = total % 60
      parts = []
      parts << "#{hours}h"   if hours.positive?
      parts << "#{minutes}m" if minutes.positive?
      parts << "#{seconds}s" if parts.empty? || seconds.positive?
      parts.join(" ")
    end
  end
end