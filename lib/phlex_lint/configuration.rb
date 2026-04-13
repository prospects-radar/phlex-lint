# frozen_string_literal: true

require "yaml"

module PhlexLint
  # Loads .phlex-lint.yml and answers per-rule questions:
  #   - Is this rule enabled?
  #   - Should this rule run on this file? (Include / Exclude)
  #
  # Config keys can be:
  #   - "AllRules"                    — global settings for every rule
  #   - "Style"                       — category-level settings
  #   - "Style/NoInlineStyles"        — specific rule (qualified name)
  #
  # Per-rule/category options:
  #   Enabled: true/false
  #   Include: [glob, ...]
  #   Exclude: [glob, ...]
  #
  # Resolution order (most specific wins):
  #   1. AllRules Exclude (global gate)
  #   2. Category Enabled / Include / Exclude
  #   3. Qualified rule Enabled / Include / Exclude
  #
  class Configuration
    CONFIG_FILE = ".phlex-lint.yml"

    attr_reader :rules_config

    # Load config from the given directory (defaults to cwd).
    # Returns an empty config if the file doesn't exist.
    def self.load(dir = Dir.pwd)
      path = File.join(dir, CONFIG_FILE)
      if File.exist?(path)
        new(YAML.safe_load_file(path) || {})
      else
        new({})
      end
    end

    def initialize(hash)
      @rules_config = hash
    end

    # Should this rule run on this file?
    # Accepts a qualified name ("Style/NoInlineStyles") and checks all levels.
    def applies_to_file?(qualified_name, file_path)
      return false unless passes_global_exclude?(file_path)

      category, short_name = split_qualified(qualified_name)

      # Check category-level config (e.g., "Style:")
      if category
        return false unless passes_config_level?(category, file_path)
      end

      # Check qualified-name config (e.g., "Style/NoInlineStyles:")
      return false unless passes_config_level?(qualified_name, file_path)

      # Backward compat: also check short name (e.g., "NoInlineStyles:")
      if category && short_name != qualified_name
        return false unless passes_config_level?(short_name, file_path)
      end

      true
    end

    # Is there any configuration at all?
    def empty?
      @rules_config.empty?
    end

    # Returns the list of component names this rule is restricted to,
    # or nil if no component filtering is configured.
    # Checks qualified name, category, and short name levels.
    def components_for_rule(qualified_name)
      category, short_name = split_qualified(qualified_name)

      # Most specific wins: qualified name > short name > category > AllRules
      components_from_key(qualified_name) ||
        (short_name != qualified_name && components_from_key(short_name)) ||
        (category && components_from_key(category)) ||
        components_from_key("AllRules")
    end

    private

    # Split "Style/NoInlineStyles" into ["Style", "NoInlineStyles"].
    # Returns [nil, name] if no category prefix.
    def split_qualified(name)
      if name.include?("/")
        name.split("/", 2)
      else
        [nil, name]
      end
    end

    # Check Enabled, Include, Exclude for a single config key.
    # Returns true if the key is not configured or if the file passes all gates.
    def passes_config_level?(key, file_path)
      cfg = @rules_config[key]
      return true unless cfg.is_a?(Hash)

      # Enabled gate
      return false if cfg.key?("Enabled") && !cfg["Enabled"]

      # Include gate: file must match at least one pattern
      includes = cfg["Include"]
      if includes.is_a?(Array) && !includes.empty?
        return false unless includes.any? { |pattern| match_glob?(pattern, file_path) }
      end

      # Exclude gate: file must not match any pattern
      excludes = cfg["Exclude"]
      if excludes.is_a?(Array) && !excludes.empty?
        return false if excludes.any? { |pattern| match_glob?(pattern, file_path) }
      end

      true
    end

    def passes_global_exclude?(file_path)
      all_cfg = @rules_config["AllRules"]
      return true unless all_cfg.is_a?(Hash)

      excludes = all_cfg["Exclude"]
      return true unless excludes.is_a?(Array) && !excludes.empty?

      !excludes.any? { |pattern| match_glob?(pattern, file_path) }
    end

    def components_from_key(key)
      cfg = @rules_config[key]
      return nil unless cfg.is_a?(Hash)

      components = cfg["Components"]
      return nil unless components.is_a?(Array) && !components.empty?

      components.map(&:to_sym)
    end

    def match_glob?(pattern, file_path)
      flags = File::FNM_PATHNAME | File::FNM_DOTMATCH
      # Match against the path as-is (works for relative paths from project root)
      return true if File.fnmatch(pattern, file_path, flags)

      # Also try matching with **/pattern to handle absolute paths
      # (e.g., pattern "app/components/**/*.rb" matches "/full/path/app/components/foo.rb")
      File.fnmatch("**/#{pattern}", file_path, flags)
    end
  end
end
