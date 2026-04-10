# frozen_string_literal: true

require "spec_helper"

RSpec.describe PhlexLint::Rules::NoRawSvg do
  def violations_for(source)
    tree = PhlexLint::Parser.parse_source(source)
    return [] unless tree

    rule = described_class.new(file_path: "test.rb")
    rule.check(tree)
    rule.violations
  end

  it "flags any raw svg element" do
    violations = violations_for(<<~RUBY)
      def view_template
        svg(xmlns: "http://www.w3.org/2000/svg", width: "16", height: "16") do
          path(d: "M0 0h16v16H0z")
        end
      end
    RUBY

    expect(violations).not_to be_empty
    expect(violations.first.message).to include("Icon()")
  end

  it "flags a bare svg call with no kwargs" do
    violations = violations_for(<<~RUBY)
      def view_template
        svg { path(d: "M0 0") }
      end
    RUBY

    expect(violations).not_to be_empty
  end

  it "flags an svg inside a component block" do
    violations = violations_for(<<~RUBY)
      def view_template
        FlexRow(gap: :sm) do
          svg(class: "icon") { path(d: "M0 0") }
          Text(content: "label")
        end
      end
    RUBY

    expect(violations).not_to be_empty
    expect(violations.count).to eq(1)
  end

  it "does not flag an Icon component" do
    violations = violations_for(<<~RUBY)
      def view_template
        Icon(name: "check-circle-fill", size: :sm)
      end
    RUBY

    expect(violations).to be_empty
  end

  it "does not flag other elements that contain no svg" do
    violations = violations_for(<<~RUBY)
      def view_template
        FlexColumn(gap: :md) do
          Text(content: "hello")
        end
      end
    RUBY

    expect(violations).to be_empty
  end
end
