# frozen_string_literal: true

module PhlexLint
  # CLI runner — globs files, parses each into a PhlexNode tree, runs rules,
  # reports violations, and exits non-zero if any are found.
  class Runner
    # Run phlex-lint against all files matching `glob_pattern`.
    # Returns true when clean, false when violations are found.
    def self.run(glob_pattern, output: $stdout, config_dir: Dir.pwd)
      new(glob_pattern, output:, config_dir:).run
    end

    def initialize(glob_pattern, output: $stdout, config_dir: Dir.pwd)
      @glob_pattern = glob_pattern
      @output = output
      @config = Configuration.load(config_dir)
    end

    def run
      files = Dir.glob(@glob_pattern).sort
      all_violations = []

      files.each do |file_path|
        parser = Parser.new(File.read(file_path), file_path)
        tree = parser.parse
        next unless tree

        violations = RuleEngine.check(tree, file_path: file_path, parser: parser, config: @config)
        all_violations.concat(violations)
      rescue Errno::ENOENT
        next
      end

      # Filter out violations disabled by # phlex-lint:disable comments
      active_violations = all_violations.reject(&:disabled?)

      if active_violations.empty?
        @output.puts "phlex-lint: No violations found in #{files.size} file(s)."
        return true
      end

      active_violations.each { |v| @output.puts v.to_s }
      @output.puts "\nphlex-lint: #{active_violations.size} violation(s) found in #{files.size} file(s)."
      false
    end
  end
end
