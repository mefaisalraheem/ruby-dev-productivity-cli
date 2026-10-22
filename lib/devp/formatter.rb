# frozen_string_literal: true

module DevP
  module Formatter
    module_function

    def format_duration(seconds)
      return "0s" if seconds.nil? || seconds.zero?

      hours   = seconds / 3600
      minutes = (seconds % 3600) / 60
      secs    = seconds % 60
      parts = []
      parts << "#{hours}h"   if hours.positive?
      parts << "#{minutes}m" if minutes.positive?
      parts << "#{secs}s"    if parts.empty? || secs.positive?
      parts.join(" ")
    end

    def format_table(rows, headers)
      return "" if rows.empty?

      all_rows = [headers] + rows
      widths = headers.each_index.map do |i|
        all_rows.map { |row| row[i].to_s.length }.max
      end

      separator = widths.map { |w| "-" * w }.join("-+-")
      lines = []
      lines << format_row(headers, widths)
      lines << separator
      rows.each { |row| lines << format_row(row, widths) }
      lines.join("\n")
    end

    def format_row(row, widths)
      row.each_with_index.map { |cell, i| cell.to_s.ljust(widths[i]) }.join(" | ")
    end

    def truncate(string, max)
      return string if string.to_s.length <= max

      "#{string[0, max - 3]}..."
    end
  end
end