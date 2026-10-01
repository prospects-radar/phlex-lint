# frozen_string_literal: true

$LOAD_PATH.unshift File.join(__dir__, "../lib")
require "phlex_lint"

RSpec.configure do |config|
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
