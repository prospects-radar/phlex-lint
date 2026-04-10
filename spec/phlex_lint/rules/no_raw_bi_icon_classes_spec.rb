# frozen_string_literal: true

require "spec_helper"

RSpec.describe PhlexLint::Rules::NoRawBiIconClasses do
  def check(source)
    tree = PhlexLint::Parser.parse_source(source)
    return [] unless tree

    rule = described_class.new(file_path: "test.rb")
    rule.check(tree)
    rule.violations
  end

  it "flags a raw HTML element with bi bi-* class" do
    violations = check(<<~RUBY)
      def view_template
        span(class: "bi bi-house")
      end
    RUBY

    expect(violations.count).to eq(1)
    expect(violations.first.message).to include("Icon(name:")
  end

  it "flags an i element with bi bi-* among other classes" do
    violations = check(<<~RUBY)
      def view_template
        i(class: "bi bi-arrow-right me-2")
      end
    RUBY

    expect(violations.count).to eq(1)
  end

  it "flags a component with bi bi-* class" do
    violations = check(<<~RUBY)
      def view_template
        Button(class: "bi bi-plus", variant: :primary)
      end
    RUBY

    expect(violations.count).to eq(1)
  end

  it "does not flag a node without bi bi-* pattern" do
    violations = check(<<~RUBY)
      def view_template
        span(class: "gm-text-primary fw-bold")
      end
    RUBY

    expect(violations).to be_empty
  end

  it "does not flag a dynamic class value" do
    violations = check(<<~RUBY)
      def view_template
        span(class: computed_class)
      end
    RUBY

    expect(violations).to be_empty
  end

  it "does not flag a node with only a single bi- class (no leading bi space)" do
    violations = check(<<~RUBY)
      def view_template
        span(class: "bi-house")
      end
    RUBY

    expect(violations).to be_empty
  end

  it "flags multiple nodes with bi bi-* in one template" do
    violations = check(<<~RUBY)
      def view_template
        span(class: "bi bi-house")
        i(class: "bi bi-gear")
      end
    RUBY

    expect(violations.count).to eq(2)
  end
end
