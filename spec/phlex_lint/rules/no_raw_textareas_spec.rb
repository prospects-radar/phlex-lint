# frozen_string_literal: true

require "spec_helper"

RSpec.describe PhlexLint::Rules::NoRawTextareas do
  def violations_for(source)
    tree = PhlexLint::Parser.parse_source(source)
    return [] unless tree

    rule = described_class.new(file_path: "test.rb")
    rule.check(tree)
    rule.violations
  end

  it "flags any raw textarea element" do
    violations = violations_for(<<~RUBY)
      def view_template
        textarea(name: "body", rows: 5)
      end
    RUBY

    expect(violations).not_to be_empty
    expect(violations.first.message).to include("TextArea()")
  end

  it "flags a textarea with a class kwarg" do
    violations = violations_for(<<~RUBY)
      def view_template
        textarea(name: "notes", class: "form-control", rows: 3)
      end
    RUBY

    expect(violations).not_to be_empty
  end

  it "flags a textarea inside a block" do
    violations = violations_for(<<~RUBY)
      def view_template
        div(class: "form-group") do
          textarea(name: "description")
        end
      end
    RUBY

    expect(violations).not_to be_empty
  end

  it "does not flag a TextArea component" do
    violations = violations_for(<<~RUBY)
      def view_template
        TextArea(name: "body", rows: 5)
      end
    RUBY

    expect(violations).to be_empty
  end

  it "does not flag components unrelated to textarea" do
    violations = violations_for(<<~RUBY)
      def view_template
        FlexColumn(gap: :md) do
          Text(content: "label")
        end
      end
    RUBY

    expect(violations).to be_empty
  end
end
