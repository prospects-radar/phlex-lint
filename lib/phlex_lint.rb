# frozen_string_literal: true

require_relative "phlex_lint/version"
require_relative "phlex_lint/phlex_node"
require_relative "phlex_lint/parser"
require_relative "phlex_lint/violation"
require_relative "phlex_lint/correction"
require_relative "phlex_lint/rule"
require_relative "phlex_lint/configuration"

# Auto-load all rules (Rule base class is already loaded above)
Dir[File.join(__dir__, "phlex_lint", "rules", "**", "*.rb")].sort.each do |f|
  require f
end

require_relative "phlex_lint/rule_engine"
require_relative "phlex_lint/runner"
