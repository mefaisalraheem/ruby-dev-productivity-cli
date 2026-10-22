# frozen_string_literal: true

require "json"
require "time"

module DevP
  class Timer
    def initialize(storage, session_storage)
      @storage         = storage
      @session_storage = session_storage
    end

    def start(project:, description: "")
      raise DevP::Error, "Timer already running. Stop it first." if running?

      data = {
        "project"     => project,
        "description" => description,
        "started_at"  => Time.now.iso8601
      }
      @storage.write(data)
      data
    end

    def stop
      raise DevP::Error, "No timer running." unless running?

      data    = @storage.read
      session = Session.new(
        project:     data["project"],
        description: data["description"],
        started_at:  data["started_at"]
      )
      session.finish!
      @session_storage.append(session.to_h)
      @storage.write({})
      session
    end

    def running?
      data = @storage.read
      return false unless data.is_a?(Hash) && data["started_at"]

      true
    end

    def current
      return nil unless running?

      @storage.read
    end

    def elapsed_seconds
      return 0 unless running?

      started = Time.parse(@storage.read["started_at"])
      (Time.now - started).to_i
    end
  end
end