# frozen_string_literal: true

require "spec_helper"

RSpec.describe PhlexLint::Rules::EnforceDesignTokenClasses do
  def check(source)
    tree = PhlexLint::Parser.parse_source(source)
    return [] unless tree

    rule = described_class.new(file_path: "test.rb")
    rule.check(tree)
    rule.violations
  end

  it "flags text-muted Bootstrap class" do
    violations = check(<<~RUBY)
      def view_template
        span(class: "text-muted")
      end
    RUBY

    expect(violations.count).to eq(1)
    expect(violations.first.message).to include("gm-text-")
  end

  it "flags text-dark Bootstrap class" do
    violations = check(<<~RUBY)
      def view_template
        p(class: "text-dark fw-bold")
      end
    RUBY

    expect(violations.count).to eq(1)
  end

  it "flags text-white Bootstrap class" do
    violations = check(<<~RUBY)
      def view_template
        h3(class: "text-white mb-2")
      end
    RUBY

    expect(violations.count).to eq(1)
  end

  it "flags text-light Bootstrap class" do
    violations = check(<<~RUBY)
      def view_template
        div(class: "text-light small")
      end
    RUBY

    expect(violations.count).to eq(1)
  end

  it "flags text-black-50 Bootstrap class" do
    violations = check(<<~RUBY)
      def view_template
        span(class: "text-black-50")
      end
    RUBY

    expect(violations.count).to eq(1)
  end

  it "flags text-body Bootstrap class" do
    violations = check(<<~RUBY)
      def view_template
        p(class: "text-body")
      end
    RUBY

    expect(violations.count).to eq(1)
  end

  it "does not flag gm-text-* design token classes" do
    violations = check(<<~RUBY)
      def view_template
        span(class: "gm-text-muted")
        p(class: "gm-text-primary fw-bold")
      end
    RUBY

    expect(violations).to be_empty
  end

  it "does not flag unrelated Bootstrap utility classes" do
    violations = check(<<~RUBY)
      def view_template
        div(class: "fw-bold d-flex align-items-center")
      end
    RUBY

    expect(violations).to be_empty
  end

  it "does not flag a dynamic class value" do
    violations = check(<<~RUBY)
      def view_template
        span(class: dynamic_class)
      end
    RUBY

    expect(violations).to be_empty
  end

  it "flags a component node using text-muted" do
    violations = check(<<~RUBY)
      def view_template
        Text(class: "text-muted small")
      end
    RUBY

    expect(violations.count).to eq(1)
  end
end
