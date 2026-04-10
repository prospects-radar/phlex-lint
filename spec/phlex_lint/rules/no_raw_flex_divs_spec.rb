# frozen_string_literal: true

require "spec_helper"

RSpec.describe PhlexLint::Rules::NoRawFlexDivs do
  def violations_for(source)
    tree = PhlexLint::Parser.parse_source(source)
    return [] unless tree

    rule = described_class.new(file_path: "test.rb")
    rule.check(tree)
    rule.violations
  end

  it "flags a div with d-flex class" do
    violations = violations_for(<<~RUBY)
      def view_template
        div(class: "d-flex align-items-center") do
          Icon(name: "check")
        end
      end
    RUBY

    expect(violations).not_to be_empty
    expect(violations.first.message).to include("FlexRow")
  end

  it "flags a span with d-flex class" do
    violations = violations_for(<<~RUBY)
      def view_template
        span(class: "d-flex gap-2") { "text" }
      end
    RUBY

    expect(violations).not_to be_empty
  end

  it "flags a div with d-flex among other classes" do
    violations = violations_for(<<~RUBY)
      def view_template
        div(class: "mb-3 d-flex justify-content-between") do
          Text(content: "left")
        end
      end
    RUBY

    expect(violations).not_to be_empty
  end

  it "does not flag a div without d-flex class" do
    violations = violations_for(<<~RUBY)
      def view_template
        div(class: "mb-3 container") do
          Text(content: "content")
        end
      end
    RUBY

    expect(violations).to be_empty
  end

  it "does not flag a div with a dynamic class" do
    violations = violations_for(<<~RUBY)
      def view_template
        div(class: computed_class) do
          Text(content: "content")
        end
      end
    RUBY

    expect(violations).to be_empty
  end

  it "does not flag a div with no class kwarg" do
    violations = violations_for(<<~RUBY)
      def view_template
        div { Text(content: "content") }
      end
    RUBY

    expect(violations).to be_empty
  end
end
