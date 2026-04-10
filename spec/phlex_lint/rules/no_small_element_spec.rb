# frozen_string_literal: true

require "spec_helper"

RSpec.describe PhlexLint::Rules::NoSmallElement do
  def check(source, file_path: "app/components/glass_morph/organisms/foo.rb")
    tree = PhlexLint::Parser.parse_source(source, file_path)
    return [] unless tree

    rule = described_class.new(file_path:)
    rule.check(tree)
    rule.violations
  end

  it "flags a bare small element" do
    violations = check(<<~RUBY)
      def view_template
        small { "Helper text" }
      end
    RUBY

    expect(violations.count).to eq(1)
    expect(violations.first.message).to include("Text(level: :small")
  end

  it "flags small with classes" do
    violations = check(<<~RUBY)
      def view_template
        small(class: "gm-text-muted fw-medium") { "Caption" }
      end
    RUBY

    expect(violations.count).to eq(1)
  end

  it "flags multiple small elements" do
    violations = check(<<~RUBY)
      def view_template
        small { "first" }
        small(class: "text-muted") { "second" }
      end
    RUBY

    expect(violations.count).to eq(2)
  end

  it "does not flag Text atom using level: :small (correct usage)" do
    violations = check(<<~RUBY)
      def view_template
        Text(level: :small, color: :muted) { "Caption" }
      end
    RUBY

    expect(violations).to be_empty
  end

  it "does not flag other HTML elements" do
    violations = check(<<~RUBY)
      def view_template
        span(class: "label") { "text" }
      end
    RUBY

    expect(violations).to be_empty
  end
end
