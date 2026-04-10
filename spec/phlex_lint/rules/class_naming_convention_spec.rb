# frozen_string_literal: true

require "spec_helper"

RSpec.describe PhlexLint::Rules::ClassNamingConvention do

  def parse(source)
    PhlexLint::Parser.parse_source(source, "test.rb")
  end
  subject(:rule) { described_class.new(file_path: "test.rb") }

  describe "#check" do
    it "flags camelCase class names" do
      tree = parse(<<~RUBY)
        def view_template
          div(class: "myWidget") { "content" }
        end
      RUBY

      rule.check(tree)
      expect(rule.violations.count).to eq(1)
      expect(rule.violations.first.message).to include("myWidget")
    end

    it "flags underscore-separated class names" do
      tree = parse(<<~RUBY)
        def view_template
          span(class: "status_box") { "content" }
        end
      RUBY

      rule.check(tree)
      expect(rule.violations.count).to eq(1)
      expect(rule.violations.first.message).to include("status_box")
    end

    it "flags PascalCase class names" do
      tree = parse(<<~RUBY)
        def view_template
          p(class: "CustomText") { "content" }
        end
      RUBY

      rule.check(tree)
      expect(rule.violations.count).to eq(1)
      expect(rule.violations.first.message).to include("CustomText")
    end

    it "allows kebab-case class names" do
      tree = parse(<<~RUBY)
        def view_template
          div(class: "my-widget")
          span(class: "status-box")
          p(class: "custom-text")
        end
      RUBY

      rule.check(tree)
      expect(rule.violations).to be_empty
    end

    it "allows Bootstrap classes (already kebab-case)" do
      tree = parse(<<~RUBY)
        def view_template
          div(class: "btn btn-primary")
          span(class: "text-muted")
        end
      RUBY

      rule.check(tree)
      expect(rule.violations).to be_empty
    end

    it "flags mixed naming (reports first invalid)" do
      tree = parse(<<~RUBY)
        def view_template
          div(class: "good-name badName another_bad") { "content" }
        end
      RUBY

      rule.check(tree)
      expect(rule.violations.count).to eq(1)
      expect(rule.violations.first.message).to include("badName")
    end

    it "ignores dynamic classes" do
      tree = parse(<<~RUBY)
        def view_template
          div(class: @dynamic_class) { "content" }
        end
      RUBY

      rule.check(tree)
      expect(rule.violations).to be_empty
    end
  end
end
