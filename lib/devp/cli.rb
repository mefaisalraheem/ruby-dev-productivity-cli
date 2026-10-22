# frozen_string_literal: true

module DevP
  class CLI
    def initialize(argv, config: nil, out: $stdout, err: $stderr)
      @argv   = argv.dup
      @config = config || Config.new
      @out    = out
      @err    = err

      @session_storage = Storage.new(@config.sessions_file)
      @log_storage     = Storage.new(@config.logs_file)
      @timer_storage   = Storage.new(@config.timer_file)
      @timer           = Timer.new(@timer_storage, @session_storage)
      @exporter        = Exporter.new(@session_storage, @log_storage)
    end

    def run
      command = @argv.shift

      case command
      when "start"      then cmd_start
      when "stop"       then cmd_stop
      when "status"     then cmd_status
      when "sessions"   then cmd_sessions
      when "log"        then cmd_log
      when "logs"       then cmd_logs
      when "today"      then cmd_today
      when "summary"    then cmd_summary
      when "export"     then cmd_export
      when "clear"      then cmd_clear
      when "version", "-v", "--version" then cmd_version
      when nil, "help", "-h", "--help"  then cmd_help
      else
        @err.puts "Unknown command: #{command}"
        @err.puts "Run 'devp help' for usage."
        1
      end
    rescue DevP::Error => e
      @err.puts "Error: #{e.message}"
      1
    end

    private

    # --- Commands ----------------------------------------------------------

    def cmd_start
      project     = extract_option("--project", "-p") || @config.default_project
      description = extract_option("--description", "-d") || ""

      if @timer.running?
        current = @timer.current
        @err.puts "Timer already running for '#{current['project']}'. Stop it first."
        return 1
      end

      @timer.start(project: project, description: description)
      @out.puts "▶ Timer started for project '#{project}'"
      @out.puts "  Description: #{description}" unless description.empty?
      0
    end

    def cmd_stop
      session = @timer.stop
      @out.puts "■ Timer stopped."
      @out.puts "  Project:  #{session.project}"
      @out.puts "  Duration: #{session.duration_human}"
      @out.puts "  Session ID: #{session.id}"
      0
    rescue DevP::Error => e
      @err.puts "Error: #{e.message}"
      1
    end

    def cmd_status
      unless @timer.running?
        @out.puts "No timer running."
        return 0
      end
      current = @timer.current
      @out.puts "▶ Running: #{current['project']}"
      @out.puts "  Description: #{current['description']}" unless current["description"].to_s.empty?
      @out.puts "  Elapsed: #{Formatter.format_duration(@timer.elapsed_seconds)}"
      0
    end

    def cmd_sessions
      project = extract_option("--project", "-p")
      limit   = (extract_option("--limit", "-n") || "10").to_i

      sessions = @session_storage.read
      sessions = sessions.select { |s| s["project"] == project } if project
      sessions = sessions.last(limit)

      if sessions.empty?
        @out.puts "No sessions recorded."
        return 0
      end

      rows = sessions.map do |s|
        [
          s["id"],
          s["project"],
          Formatter.truncate(s["description"], 30),
          Formatter.format_duration(s["duration_seconds"].to_i),
          s["started_at"]
        ]
      end

      @out.puts Formatter.format_table(rows, ["ID", "Project", "Description", "Duration", "Started"])
      @out.puts ""
      total = sessions.sum { |s| s["duration_seconds"].to_i }
      @out.puts "Total: #{Formatter.format_duration(total)} (#{sessions.size} sessions)"
      0
    end

    def cmd_log
      message  = @argv.shift
      if message.nil? || message.empty?
        @err.puts "Usage: devp log <message> [--category note|blocker|win|todo|idea] [--date YYYY-MM-DD]"
        return 1
      end
      category = extract_option("--category", "-c") || "note"
      date     = extract_option("--date") || Time.now.strftime("%Y-%m-%d")

      entry = LogEntry.new(message: message, category: category, date: date)
      @log_storage.append(entry.to_h)
      @out.puts "✓ Logged [#{entry.category}] #{entry.message}"
      0
    end

    def cmd_logs
      date = extract_option("--date") || Time.now.strftime("%Y-%m-%d")
      logs = @log_storage.read.select { |l| l["date"] == date }

      if logs.empty?
        @out.puts "No logs for #{date}."
        return 0
      end

      @out.puts "Logs for #{date}:"
      logs.each do |l|
        @out.puts "  [#{l['category'].upcase}] #{l['message']}"
      end
      0
    end

    def cmd_today
      today = Time.now.strftime("%Y-%m-%d")
      sessions = @session_storage.read.select do |s|
        s["started_at"].to_s.start_with?(today)
      end
      logs = @log_storage.read.select { |l| l["date"] == today }

      total = sessions.sum { |s| s["duration_seconds"].to_i }

      @out.puts "📅 #{today}"
      @out.puts "─" * 40
      @out.puts "Sessions: #{sessions.size} (#{Formatter.format_duration(total)})"
      sessions.each do |s|
        @out.puts "  • #{s['project']} — #{Formatter.format_duration(s['duration_seconds'].to_i)}"
        @out.puts "    #{s['description']}" unless s["description"].to_s.empty?
      end
      @out.puts ""

      if logs.any?
        @out.puts "Logs:"
        logs.each { |l| @out.puts "  [#{l['category'].upcase}] #{l['message']}" }
      else
        @out.puts "No logs today."
      end
      0
    end

    def cmd_summary
      sessions = @session_storage.read
      logs     = @log_storage.read

      by_project = Hash.new(0)
      sessions.each { |s| by_project[s["project"]] += s["duration_seconds"].to_i }
      total = by_project.values.sum

      @out.puts "📊 Productivity Summary"
      @out.puts "─" * 40
      @out.puts "Total sessions: #{sessions.size}"
      @out.puts "Total time:     #{Formatter.format_duration(total)}"
      @out.puts "Log entries:    #{logs.size}"
      @out.puts ""
      @out.puts "By project:"
      if by_project.empty?
        @out.puts "  (none)"
      else
        by_project.sort_by { |_, v| -v }.each do |project, seconds|
          pct = total.positive? ? ((seconds * 100.0) / total).round(1) : 0
          @out.puts "  #{project.ljust(20)} #{Formatter.format_duration(seconds).rjust(10)} (#{pct}%)"
        end
      end
      0
    end

    def cmd_export
      format = @argv.shift || "json"
      path   = extract_option("--output", "-o")

      content = case format
                when "json"     then @exporter.export_json(path: path)
                when "csv"      then @exporter.export_csv(path: path)
                when "markdown", "md" then @exporter.export_markdown(path: path)
                else
                  @err.puts "Unknown export format: #{format} (use json, csv, or markdown)"
                  return 1
                end

      if path
        @out.puts "✓ Exported #{format} to #{path}"
      else
        @out.puts content
      end
      0
    end

    def cmd_clear
      target = @argv.shift || "all"
      case target
      when "sessions"
        @session_storage.clear
        @out.puts "✓ Sessions cleared."
      when "logs"
        @log_storage.clear
        @out.puts "✓ Logs cleared."
      when "all"
        @session_storage.clear
        @log_storage.clear
        @timer_storage.write({})
        @out.puts "✓ All data cleared."
      else
        @err.puts "Unknown target: #{target} (use sessions, logs, or all)"
        return 1
      end
      0
    end

    def cmd_version
      @out.puts "devp #{DevP::VERSION}"
      0
    end

    def cmd_help
      @out.puts <<~HELP
        devp — Developer Productivity CLI (v#{DevP::VERSION})

        USAGE:
          devp <command> [options]

        TIMER COMMANDS:
          start [-p project] [-d description]   Start a work session
          stop                                  Stop the running session
          status                                Show elapsed time

        LOG COMMANDS:
          log <message> [-c category] [--date]  Add a daily log entry
                                                categories: note, blocker, win, todo, idea
          logs [--date YYYY-MM-DD]              Show logs for a date
          today                                 Show today's sessions and logs

        REPORTING:
          sessions [-p project] [-n limit]      List recent sessions
          summary                               Show productivity summary
          export <json|csv|markdown> [-o path]  Export data

        DATA:
          clear <sessions|logs|all>             Clear stored data
          version                               Show version
          help                                  Show this help

        ENVIRONMENT:
          DEVP_HOME    Data directory (default: ~/.devp)
      HELP
      0
    end

    # --- Helpers -----------------------------------------------------------

    def extract_option(*names)
      names.each do |name|
        idx = @argv.index(name)
        next unless idx

        @argv.delete_at(idx)
        value = @argv.delete_at(idx)
        return value
      end
      nil
    end
  end
end