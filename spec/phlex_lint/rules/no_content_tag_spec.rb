# frozen_string_literal: true

require "spec_helper"

RSpec.describe PhlexLint::Rules::NoContentTag do

  def parse(source)
    PhlexLint::Parser.parse_source(source, "test.rb")
  end
  subject(:rule) { described_class.new(file_path: "test.rb") }

  describe "#check" do
    it "flags content_tag usage" do
      tree = parse(<<~RUBY)
        def view_template
          content_tag(:div, class: "d-flex") do
            content_tag(:button, "Submit", class: "btn btn-primary")
          end
        end
      RUBY

      rule.check(tree)
      expect(rule.violations.count).to eq(2)
      expect(rule.violations.first.message).to include("content_tag")
    end

    it "ignores Phlex element methods" do
      tree = parse(<<~RUBY)
        def view_template
          div(class: "d-flex") do
            button(class: "btn btn-primary") { "Submit" }
          end
        end
      RUBY

      rule.check(tree)
      expect(rule.violations).to be_empty
    end

    it "flags content_tag with no block" do
      tree = parse(<<~RUBY)
        def view_template
          content_tag(:span, "Hello", class: "text-muted")
        end
      RUBY

      rule.check(tree)
      expect(rule.violations.count).to eq(1)
    end
  end
end
