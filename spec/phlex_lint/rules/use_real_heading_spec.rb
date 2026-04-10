# frozen_string_literal: true

require "spec_helper"

RSpec.describe PhlexLint::Rules::UseRealHeading do
  def violations_for(source)
    tree = PhlexLint::Parser.parse_source(source)
    return [] unless tree

    rule = described_class.new(file_path: "test.rb")
    rule.check(tree)
    rule.violations
  end

  it "flags an h2 with fw- font utility class" do
    violations = violations_for(<<~RUBY)
      def view_template
        h2(class: "fw-bold") { "Section Title" }
      end
    RUBY

    expect(violations).not_to be_empty
    expect(violations.first.message).to include("2")
  end

  it "flags an h3 with text-muted class" do
    violations = violations_for(<<~RUBY)
      def view_template
        h3(class: "text-muted fs-5") { "Subtitle" }
      end
    RUBY

    expect(violations).not_to be_empty
    expect(violations.first.message).to include("3")
  end

  it "flags an h1 with text-white class" do
    violations = violations_for(<<~RUBY)
      def view_template
        h1(class: "text-white fw-semibold") { "Hero" }
      end
    RUBY

    expect(violations).not_to be_empty
    expect(violations.first.message).to include("1")
  end

  it "flags an h4 with fs- size utility" do
    violations = violations_for(<<~RUBY)
      def view_template
        h4(class: "fs-4") { "Card title" }
      end
    RUBY

    expect(violations).not_to be_empty
    expect(violations.first.message).to include("4")
  end

  it "does not flag a raw heading with no class" do
    violations = violations_for(<<~RUBY)
      def view_template
        h2 { "Section Title" }
      end
    RUBY

    expect(violations).to be_empty
  end

  it "does not flag a raw heading with non-font classes" do
    violations = violations_for(<<~RUBY)
      def view_template
        h2(class: "mb-3 mt-2") { "Section" }
      end
    RUBY

    expect(violations).to be_empty
  end

  it "does not flag a Heading component" do
    violations = violations_for(<<~RUBY)
      def view_template
        Heading(level: 2, text: "Title")
      end
    RUBY

    expect(violations).to be_empty
  end

  it "does not flag a heading with a dynamic class" do
    violations = violations_for(<<~RUBY)
      def view_template
        h3(class: computed_classes) { "Dynamic" }
      end
    RUBY

    expect(violations).to be_empty
  end
end
