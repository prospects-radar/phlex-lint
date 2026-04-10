# frozen_string_literal: true

require "spec_helper"

RSpec.describe PhlexLint::Rules::NoNewTailwindUsage do
  def check(source)
    tree = PhlexLint::Parser.parse_source(source)
    return [] unless tree

    rule = described_class.new(file_path: "test.rb")
    rule.check(tree)
    rule.violations
  end

  it "flags items-center Tailwind class" do
    violations = check(<<~RUBY)
      def view_template
        div(class: "flex items-center")
      end
    RUBY

    expect(violations.count).to eq(1)
    expect(violations.first.message).to include("Tailwind")
  end

  it "flags justify-between Tailwind class" do
    violations = check(<<~RUBY)
      def view_template
        div(class: "justify-between w-full")
      end
    RUBY

    expect(violations.count).to eq(1)
  end

  it "flags text-gray-500 Tailwind color class" do
    violations = check(<<~RUBY)
      def view_template
        span(class: "text-gray-500")
      end
    RUBY

    expect(violations.count).to eq(1)
  end

  it "flags rounded-lg Tailwind class" do
    violations = check(<<~RUBY)
      def view_template
        div(class: "rounded-lg overflow-hidden")
      end
    RUBY

    expect(violations.count).to eq(1)
  end

  it "flags hover: pseudo-class pattern" do
    violations = check(<<~RUBY)
      def view_template
        a(class: "hover:text-blue-500")
      end
    RUBY

    expect(violations.count).to eq(1)
  end

  it "does not flag Bootstrap 5 classes" do
    violations = check(<<~RUBY)
      def view_template
        div(class: "d-flex align-items-center justify-content-between")
      end
    RUBY

    expect(violations).to be_empty
  end

  it "does not flag gm-* design token classes" do
    violations = check(<<~RUBY)
      def view_template
        div(class: "gm-card gm-text-primary")
      end
    RUBY

    expect(violations).to be_empty
  end

  it "does not flag a dynamic class value" do
    violations = check(<<~RUBY)
      def view_template
        div(class: computed_class)
      end
    RUBY

    expect(violations).to be_empty
  end

  it "flags flex-col Tailwind class on a component node" do
    violations = check(<<~RUBY)
      def view_template
        GlassCard(class: "flex-col gap-4")
      end
    RUBY

    expect(violations.count).to eq(1)
  end

  it "flags opacity Tailwind class" do
    violations = check(<<~RUBY)
      def view_template
        div(class: "opacity-50 cursor-pointer")
      end
    RUBY

    expect(violations.count).to eq(1)
  end
end
