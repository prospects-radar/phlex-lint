# frozen_string_literal: true

require "spec_helper"
require "phlex_lint/rules/no_class_on_badge"

RSpec.describe PhlexLint::Rules::NoClassOnBadge do
  def violations_for(source)
    tree = PhlexLint::Parser.parse_source(source)
    rule = described_class.new(file_path: "app/components/test.rb")
    rule.check(tree)
    rule.violations
  end

  it "flags Badge with non-layout class" do
    violations = violations_for(<<~RUBY)
      def view_template
        Badge(type: :status, label: "Active", class: "text-success fw-bold")
      end
    RUBY

    expect(violations.count).to eq(1)
    expect(violations.first.message).to include("layout-positioning classes")
  end

  it "flags Badge with custom badge class" do
    violations = violations_for(<<~RUBY)
      def view_template
        Badge(type: :count, count: 5, class: "badge-custom")
      end
    RUBY

    expect(violations.count).to eq(1)
  end

  it "flags Badge with mixed layout and non-layout classes" do
    violations = violations_for(<<~RUBY)
      def view_template
        Badge(type: :status, label: "Active", class: "mt-2 text-bold")
      end
    RUBY

    expect(violations.count).to eq(1)
  end

  it "does not flag Badge with only margin class" do
    violations = violations_for(<<~RUBY)
      def view_template
        Badge(type: :status, label: "Active", class: "mt-2")
      end
    RUBY

    expect(violations).to be_empty
  end

  it "does not flag Badge with only padding class" do
    violations = violations_for(<<~RUBY)
      def view_template
        Badge(type: :status, label: "Active", class: "pb-1")
      end
    RUBY

    expect(violations).to be_empty
  end

  it "does not flag Badge with multiple layout-only classes" do
    violations = violations_for(<<~RUBY)
      def view_template
        Badge(type: :status, label: "Active", class: "mt-2 mb-1")
      end
    RUBY

    expect(violations).to be_empty
  end

  it "does not flag Badge with gap class" do
    violations = violations_for(<<~RUBY)
      def view_template
        Badge(type: :status, label: "Active", class: "gap-2")
      end
    RUBY

    expect(violations).to be_empty
  end

  it "does not flag Badge without class" do
    violations = violations_for(<<~RUBY)
      def view_template
        Badge(type: :status, label: "Active")
      end
    RUBY

    expect(violations).to be_empty
  end

  it "does not flag Badge with dynamic class value" do
    violations = violations_for(<<~RUBY)
      def view_template
        Badge(type: :status, label: "Active", class: computed_class)
      end
    RUBY

    expect(violations).to be_empty
  end
end
