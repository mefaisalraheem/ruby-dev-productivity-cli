# frozen_string_literal: true

require "json"
require "fileutils"

module DevP
  class Storage
    def initialize(path)
      @path = path
    end

    attr_reader :path

    def read
      return [] unless File.exist?(@path)

      content = File.read(@path)
      return [] if content.strip.empty?

      JSON.parse(content)
    rescue JSON::ParserError
      []
    end

    def write(data)
      FileUtils.mkdir_p(File.dirname(@path))
      File.write(@path, JSON.pretty_generate(data))
    end

    def append(record)
      data = read
      data << record
      write(data)
      record
    end

    def clear
      write([])
    end

    def exist?
      File.exist?(@path)
    end
  end
end