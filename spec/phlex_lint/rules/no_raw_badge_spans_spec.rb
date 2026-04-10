# frozen_string_literal: true

require "spec_helper"

RSpec.describe PhlexLint::Rules::NoRawBadgeSpans do
  def violations_for(source)
    tree = PhlexLint::Parser.parse_source(source)
    return [] unless tree

    rule = described_class.new(file_path: "test.rb")
    rule.check(tree)
    rule.violations
  end

  it "flags a span with badge class" do
    violations = violations_for(<<~RUBY)
      def view_template
        span(class: "badge bg-success") { "Active" }
      end
    RUBY

    expect(violations).not_to be_empty
    expect(violations.first.message).to include("Badge")
  end

  it "flags a div with badge class" do
    violations = violations_for(<<~RUBY)
      def view_template
        div(class: "badge badge-pill") { "3" }
      end
    RUBY

    expect(violations).not_to be_empty
  end

  it "flags a span with badge among other classes" do
    violations = violations_for(<<~RUBY)
      def view_template
        span(class: "badge text-bg-danger rounded-pill") { "New" }
      end
    RUBY

    expect(violations).not_to be_empty
  end

  it "does not flag a span without badge class" do
    violations = violations_for(<<~RUBY)
      def view_template
        span(class: "text-muted small") { "note" }
      end
    RUBY

    expect(violations).to be_empty
  end

  it "does not flag a div without badge class" do
    violations = violations_for(<<~RUBY)
      def view_template
        div(class: "d-inline-block") { "content" }
      end
    RUBY

    expect(violations).to be_empty
  end

  it "does not flag a Badge component" do
    violations = violations_for(<<~RUBY)
      def view_template
        Badge.status(status: :success, label: "Active")
      end
    RUBY

    expect(violations).to be_empty
  end

  it "does not flag a span with a dynamic class" do
    violations = violations_for(<<~RUBY)
      def view_template
        span(class: badge_classes) { count }
      end
    RUBY

    expect(violations).to be_empty
  end
end
