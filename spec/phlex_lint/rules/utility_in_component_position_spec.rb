# frozen_string_literal: true

require "spec_helper"

RSpec.describe PhlexLint::Rules::UtilityInComponentPosition do

  def parse(source)
    PhlexLint::Parser.parse_source(source, "test.rb")
  end
  subject(:rule) { described_class.new(file_path: "test.rb") }

  describe "#check" do
    it "flags card with flex utilities suggesting FlexColumn" do
      tree = parse(<<~RUBY)
        def view_template
          div(class: "card d-flex flex-column gap-3") { "content" }
        end
      RUBY

      rule.check(tree)
      expect(rule.violations.count).to eq(1)
      expect(rule.violations.first.message).to include("FlexColumn")
    end

    it "flags d-flex with align-items and gap suggesting FlexRow" do
      tree = parse(<<~RUBY)
        def view_template
          div(class: "d-flex align-items-center gap-2")
        end
      RUBY

      rule.check(tree)
      expect(rule.violations.count).to eq(1)
      expect(rule.violations.first.message).to include("FlexRow")
    end

    it "flags d-flex flex-column with gap suggesting FlexColumn" do
      tree = parse(<<~RUBY)
        def view_template
          div(class: "d-flex flex-column gap-2")
        end
      RUBY

      rule.check(tree)
      expect(rule.violations.count).to eq(1)
      expect(rule.violations.first.message).to include("FlexColumn")
    end

    it "flags container with spacing suggesting PageContainer" do
      tree = parse(<<~RUBY)
        def view_template
          div(class: "container mt-4")
        end
      RUBY

      rule.check(tree)
      expect(rule.violations.count).to eq(1)
      expect(rule.violations.first.message).to include("PageContainer")
    end

    it "flags container with d-flex suggesting PageContainer" do
      tree = parse(<<~RUBY)
        def view_template
          div(class: "container d-flex")
        end
      RUBY

      rule.check(tree)
      expect(rule.violations.count).to eq(1)
      expect(rule.violations.first.message).to include("PageContainer")
    end

    it "ignores design system components" do
      tree = parse(<<~RUBY)
        def view_template
          FlexColumn(gap: :md)
          FlexRow(gap: :sm)
          Container { "content" }
        end
      RUBY

      rule.check(tree)
      expect(rule.violations).to be_empty
    end

    it "ignores div without flagged patterns" do
      tree = parse(<<~RUBY)
        def view_template
          div(class: "card card-body")
          div(class: "d-flex")
          div(class: "container")
        end
      RUBY

      rule.check(tree)
      expect(rule.violations).to be_empty
    end

    it "ignores raw HTML elements other than div" do
      tree = parse(<<~RUBY)
        def view_template
          span(class: "card d-flex flex-column gap-3")
        end
      RUBY

      rule.check(tree)
      expect(rule.violations).to be_empty
    end

    it "ignores dynamic classes" do
      tree = parse(<<~RUBY)
        def view_template
          div(class: @dynamic_classes)
        end
      RUBY

      rule.check(tree)
      expect(rule.violations).to be_empty
    end
  end
end
