# frozen_string_literal: true

require "securerandom"
require "time"

module DevP
  class LogEntry
    attr_reader :id, :date, :category, :message, :created_at

    CATEGORIES = %w[note blocker win todo idea].freeze

    def initialize(message:, category: "note", date: nil, created_at: nil, id: nil)
      @id         = id || SecureRandom.hex(6)
      @message    = message
      @category   = category
      @date       = date || Time.now.strftime("%Y-%m-%d")
      @created_at = parse_time(created_at) || Time.now

      unless CATEGORIES.include?(@category)
        raise DevP::Error, "Unknown category: #{@category}. Valid: #{CATEGORIES.join(', ')}"
      end
    end

    def to_h
      {
        "id"         => id,
        "date"       => date,
        "category"   => category,
        "message"    => message,
        "created_at" => created_at.iso8601
      }
    end

    def self.from_h(hash)
      new(
        id:         hash["id"],
        date:       hash["date"],
        category:   hash["category"],
        message:    hash["message"],
        created_at: hash["created_at"]
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
  end
end