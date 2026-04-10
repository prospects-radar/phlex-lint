# frozen_string_literal: true

require "spec_helper"

RSpec.describe PhlexLint::Rules::NoMixingLayerConcerns do

  def parse(source)
    PhlexLint::Parser.parse_source(source, "test.rb")
  end
  subject(:rule) { described_class.new(file_path: "test.rb") }

  describe "#check" do
    it "flags high utility density with component class" do
      tree = parse(<<~RUBY)
        def view_template
          div(class: "card mb-4 shadow-sm d-flex align-items-center") { "content" }
        end
      RUBY

      rule.check(tree)
      expect(rule.violations.count).to eq(1)
      expect(rule.violations.first.message).to include("3 utilities")
    end

    it "flags very high utility density" do
      tree = parse(<<~RUBY)
        def view_template
          p(class: "card-text text-muted mt-2 mb-3 fw-bold fs-6")
        end
      RUBY

      rule.check(tree)
      expect(rule.violations.count).to eq(1)
      expect(rule.violations.first.message).to include("6 utilities")
    end

    it "ignores low utility density with component class" do
      tree = parse(<<~RUBY)
        def view_template
          div(class: "card mb-4 shadow-sm")
        end
      RUBY

      rule.check(tree)
      expect(rule.violations).to be_empty
    end

    it "ignores utilities without component classes" do
      tree = parse(<<~RUBY)
        def view_template
          div(class: "d-flex gap-3 mb-4 text-muted")
        end
      RUBY

      rule.check(tree)
      expect(rule.violations).to be_empty
    end

    it "allows pure component classes" do
      tree = parse(<<~RUBY)
        def view_template
          div(class: "card card-body")
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
