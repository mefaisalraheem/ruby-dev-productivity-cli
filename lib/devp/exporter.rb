# frozen_string_literal: true

require "json"

module DevP
  class Exporter
    def initialize(session_storage, log_storage)
      @session_storage = session_storage
      @log_storage     = log_storage
    end

    def export_json(path: nil)
      payload = {
        "exported_at" => Time.now.iso8601,
        "sessions"    => @session_storage.read,
        "logs"        => @log_storage.read
      }
      json = JSON.pretty_generate(payload)
      write_or_return(json, path)
    end

    def export_csv(path: nil)
      lines = ["id,project,description,started_at,ended_at,duration_seconds"]
      @session_storage.read.each do |s|
        lines << [
          s["id"],
          csv_escape(s["project"]),
          csv_escape(s["description"]),
          s["started_at"],
          s["ended_at"],
          s["duration_seconds"]
        ].join(",")
      end
      write_or_return(lines.join("\n"), path)
    end

    def export_markdown(path: nil)
      sessions = @session_storage.read
      logs     = @log_storage.read
      md = []
      md << "# Developer Productivity Report"
      md << ""
      md << "Generated: #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}"
      md << ""
      md << "## Sessions (#{sessions.size})"
      md << ""
      total = sessions.sum { |s| s["duration_seconds"].to_i }
      md << "**Total tracked:** #{Formatter.format_duration(total)}"
      md << ""
      if sessions.empty?
        md << "_No sessions recorded._"
      else
        md << "| Project | Description | Duration | Started |"
        md << "|---------|-------------|----------|---------|"
        sessions.each do |s|
          md << "| #{s['project']} | #{s['description']} | " \
                "#{Formatter.format_duration(s['duration_seconds'].to_i)} | " \
                "#{s['started_at']} |"
        end
      end
      md << ""
      md << "## Daily Log (#{logs.size})"
      md << ""
      if logs.empty?
        md << "_No logs recorded._"
      else
        logs.sort_by { |l| l["created_at"] }.each do |l|
          md << "- **[#{l['category']}]** #{l['date']} — #{l['message']}"
        end
      end
      write_or_return(md.join("\n"), path)
    end

    private

    def write_or_return(content, path)
      if path
        File.write(path, content)
        path
      else
        content
      end
    end

    def csv_escape(value)
      s = value.to_s
      return s unless s.include?(",") || s.include?('"') || s.include?("\n")

      "\"#{s.gsub('"', '""')}\""
    end
  end
end