# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Skip Annotations" do
  def parse_with_parser(source)
    parser = PhlexLint::Parser.new(source, "test.rb")
    tree = parser.parse
    [tree, parser]
  end

  def run_rules(tree, file_path: "test.rb", parser: nil)
    violations = PhlexLint::RuleEngine.check(tree, file_path: file_path, parser: parser)
    # Filter disabled violations, same as Runner does
    violations.reject(&:disabled?)
  end

  it "disables rule with phlex-lint:disable RuleName" do
    source = <<~RUBY
      def view_template
        # phlex-lint:disable NoCustomClasses
        div(class: "my-widget") { "content" }
        # phlex-lint:enable NoCustomClasses
        div(class: "my-widget") { "content" }
      end
    RUBY

    tree, parser = parse_with_parser(source)
    violations = run_rules(tree, parser: parser)

    no_custom = violations.select { |v| v.rule_class == PhlexLint::Rules::NoCustomClasses }
    expect(no_custom.count).to eq(1)
    expect(no_custom.first.line).to eq(5)
  end

  it "disables all rules with phlex-lint:disable" do
    source = <<~RUBY
      def view_template
        # phlex-lint:disable
        div(class: "my-widget") { "content" }
        # phlex-lint:enable
        div(class: "my-widget") { "content" }
      end
    RUBY

    tree, parser = parse_with_parser(source)
    violations = run_rules(tree, parser: parser)

    # Line 3 should have no violations (all disabled); line 5 should have violations
    line3_violations = violations.select { |v| v.line == 3 }
    expect(line3_violations).to be_empty
    expect(violations.any? { |v| v.line == 5 }).to be true
  end

  it "disables multiple rules with comma-separated list" do
    source = <<~RUBY
      def view_template
        # phlex-lint:disable NoCustomClasses,ClassNamingConvention
        div(class: "my_widget") { "content" }
        # phlex-lint:enable
        div(class: "my_widget") { "content" }
      end
    RUBY

    tree, parser = parse_with_parser(source)
    violations = run_rules(tree, parser: parser)

    # Line 3 should have neither NoCustomClasses nor ClassNamingConvention
    line3 = violations.select { |v| v.line == 3 }
    line3_rules = line3.map { |v| v.rule_class.name.split("::").last }
    expect(line3_rules).not_to include("NoCustomClasses")
    expect(line3_rules).not_to include("ClassNamingConvention")

    # Line 5 should have both
    line5_rules = violations.select { |v| v.line == 5 }.map { |v| v.rule_class.name.split("::").last }
    expect(line5_rules).to include("NoCustomClasses")
    expect(line5_rules).to include("ClassNamingConvention")
  end

  it "enable only specific rules keeps other rules disabled" do
    source = <<~RUBY
      def view_template
        # phlex-lint:disable NoCustomClasses,ClassNamingConvention
        div(class: "my_widget custom") { "content" }
        # phlex-lint:enable NoCustomClasses
        div(class: "my_widget custom") { "content" }
      end
    RUBY

    tree, parser = parse_with_parser(source)
    violations = run_rules(tree, parser: parser)

    # Line 3: both rules disabled — neither should appear
    line3_rules = violations.select { |v| v.line == 3 }.map { |v| v.rule_class.name.split("::").last }
    expect(line3_rules).not_to include("NoCustomClasses")
    expect(line3_rules).not_to include("ClassNamingConvention")

    # Line 5: NoCustomClasses re-enabled, ClassNamingConvention still disabled
    line5_rules = violations.select { |v| v.line == 5 }.map { |v| v.rule_class.name.split("::").last }
    expect(line5_rules).to include("NoCustomClasses")
    expect(line5_rules).not_to include("ClassNamingConvention")
  end
end
