# frozen_string_literal: true

require "spec_helper"

RSpec.describe PhlexLint::Rules::NoIconInHeading do
  def violations_for(source)
    tree = PhlexLint::Parser.parse_source(source)
    return [] unless tree

    rule = described_class.new(file_path: "test.rb")
    rule.check(tree)
    rule.violations
  end

  it "flags Icon directly inside Heading" do
    violations = violations_for(<<~RUBY)
      def view_template
        Heading(level: 1, class: "hero-title") do
          Icon(name: "graph-up-arrow", size: :md, color: :white)
          plain t("dashboard.title")
        end
      end
    RUBY

    expect(violations).not_to be_empty
    expect(violations.first.message).to include("FlexRow")
  end

  it "flags Icon nested deeper inside Heading" do
    violations = violations_for(<<~RUBY)
      def view_template
        Heading(level: 2, class: "hero-title") do
          span do
            Icon(name: "star", size: :sm)
          end
          plain "Title"
        end
      end
    RUBY

    expect(violations).not_to be_empty
  end

  it "does not flag Icon outside Heading" do
    violations = violations_for(<<~RUBY)
      def view_template
        FlexRow(align: :center, gap: :sm) do
          Icon(name: "graph-up-arrow", size: :md, color: :white)
          Heading(level: 1, class: "hero-title") { t("dashboard.title") }
        end
      end
    RUBY

    expect(violations).to be_empty
  end

  it "does not flag standalone Heading without Icon" do
    violations = violations_for(<<~RUBY)
      def view_template
        Heading(level: 1, class: "hero-title") { @title }
      end
    RUBY

    expect(violations).to be_empty
  end

  it "does not flag Icon inside a non-Heading component" do
    violations = violations_for(<<~RUBY)
      def view_template
        Box(class: "header") do
          Icon(name: "house", size: :md)
        end
      end
    RUBY

    expect(violations).to be_empty
  end
end
