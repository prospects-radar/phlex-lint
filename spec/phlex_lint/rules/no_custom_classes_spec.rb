# frozen_string_literal: true

require "spec_helper"

RSpec.describe PhlexLint::Rules::NoCustomClasses do

  def parse(source)
    PhlexLint::Parser.parse_source(source, "test.rb")
  end
  subject(:rule) { described_class.new(file_path: "test.rb") }

  describe "#check" do
    it "flags custom classes" do
      tree = parse(<<~RUBY)
        def view_template
          div(class: "my-widget") { "content" }
        end
      RUBY

      rule.check(tree)
      expect(rule.violations.count).to eq(1)
      expect(rule.violations.first.message).to include("my-widget")
    end

    it "allows gm-* design tokens" do
      tree = parse(<<~RUBY)
        def view_template
          div(class: "gm-mt-4 gm-text-muted") { "content" }
        end
      RUBY

      rule.check(tree)
      expect(rule.violations).to be_empty
    end

    it "allows Bootstrap layout utilities" do
      tree = parse(<<~RUBY)
        def view_template
          div(class: "d-flex gap-3 mb-4 text-muted") { "content" }
        end
      RUBY

      rule.check(tree)
      expect(rule.violations).to be_empty
    end

    it "allows Bootstrap component classes" do
      tree = parse(<<~RUBY)
        def view_template
          div(class: "card card-body")
          button(class: "btn btn-primary")
        end
      RUBY

      rule.check(tree)
      expect(rule.violations).to be_empty
    end

    it "flags multiple custom classes (reports first)" do
      tree = parse(<<~RUBY)
        def view_template
          div(class: "my-widget status-box") { "content" }
        end
      RUBY

      rule.check(tree)
      expect(rule.violations.count).to eq(1)
      expect(rule.violations.first.message).to include("my-widget")
    end

    it "ignores dynamic classes" do
      tree = parse(<<~RUBY)
        def view_template
          div(class: @custom_class) { "content" }
        end
      RUBY

      rule.check(tree)
      expect(rule.violations).to be_empty
    end
  end
end
