# frozen_string_literal: true

require "spec_helper"

RSpec.describe PhlexLint::Rules::ReviewInterpolatedClasses do

  def parse(source)
    PhlexLint::Parser.parse_source(source, "test.rb")
  end
  subject(:rule) { described_class.new(file_path: "test.rb") }

  describe "#check" do
    it "flags interpolated class strings" do
      tree = parse(<<~RUBY)
        def view_template
          Button(class: "btn btn-\#{@variant}") { "Save" }
        end
      RUBY

      rule.check(tree)
      expect(rule.violations.count).to eq(1)
      expect(rule.violations.first.message).to include("interpolation")
    end

    it "flags multiple interpolated class strings" do
      tree = parse(<<~RUBY)
        def view_template
          Button(class: "btn btn-\#{@variant}") { "Save" }
          div(class: "widget-#{@type}") { "content" }
        end
      RUBY

      rule.check(tree)
      expect(rule.violations.count).to eq(2)
    end

    it "ignores static class strings" do
      tree = parse(<<~RUBY)
        def view_template
          Button(class: "btn btn-primary") { "Save" }
        end
      RUBY

      rule.check(tree)
      expect(rule.violations).to be_empty
    end

    it "ignores missing class kwarg" do
      tree = parse(<<~RUBY)
        def view_template
          Button(text: "Save", variant: :primary)
        end
      RUBY

      rule.check(tree)
      expect(rule.violations).to be_empty
    end
  end
end
