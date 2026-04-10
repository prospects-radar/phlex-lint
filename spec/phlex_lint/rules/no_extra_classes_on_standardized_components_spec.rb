# frozen_string_literal: true

require "spec_helper"

RSpec.describe PhlexLint::Rules::NoExtraClassesOnStandardizedComponents do
  def check(source, file_path: "app/components/glass_morph/organisms/foo.rb")
    tree = PhlexLint::Parser.parse_source(source, file_path)
    return [] unless tree

    return [] unless described_class.applies_to_file?(file_path)

    rule = described_class.new(file_path:)
    rule.check(tree)
    rule.violations
  end

  it "flags Heading with fw-bold class" do
    violations = check(<<~RUBY)
      def view_template
        Heading(level: 2, class: "fw-bold") { "Title" }
      end
    RUBY

    expect(violations.count).to eq(1)
    expect(violations.first.message).to include("Heading")
    expect(violations.first.message).to include("color:")
  end

  it "flags Text with text-muted class" do
    violations = check(<<~RUBY)
      def view_template
        Text(class: "text-muted mt-2") { "Body" }
      end
    RUBY

    expect(violations.count).to eq(1)
    expect(violations.first.message).to include("Text")
  end

  it "does not flag Button with ms-3 margin class (covered by UseParentGapForSpacing)" do
    violations = check(<<~RUBY)
      def view_template
        Button(variant: :primary, class: "ms-3") { "Save" }
      end
    RUBY

    expect(violations).to be_empty
  end

  it "flags Button with pt-2 padding class (not covered by UseParentGapForSpacing)" do
    violations = check(<<~RUBY)
      def view_template
        Button(variant: :primary, class: "pt-2") { "Save" }
      end
    RUBY

    expect(violations.count).to eq(1)
    expect(violations.first.message).to include("Button")
  end

  it "flags Badge with fs-6 class" do
    violations = check(<<~RUBY)
      def view_template
        Badge(class: "fs-6") { "label" }
      end
    RUBY

    expect(violations.count).to eq(1)
  end

  it "flags Icon with fw-light class" do
    violations = check(<<~RUBY)
      def view_template
        Icon(name: "star", class: "fw-light")
      end
    RUBY

    expect(violations.count).to eq(1)
  end

  it "does not flag StatCard with mb-3 margin class (covered by UseParentGapForSpacing)" do
    violations = check(<<~RUBY)
      def view_template
        StatCard(label: "Revenue", value: "$100k", class: "mb-3")
      end
    RUBY

    expect(violations).to be_empty
  end

  it "flags multiple standardized components in one template" do
    violations = check(<<~RUBY)
      def view_template
        Heading(level: 1, class: "fw-bold") { "Title" }
        Text(class: "text-white") { "body" }
      end
    RUBY

    expect(violations.count).to eq(2)
  end

  it "does not flag components without a class kwarg" do
    violations = check(<<~RUBY)
      def view_template
        Heading(level: 2, color: :primary) { "Title" }
        Text(color: :muted) { "Body" }
      end
    RUBY

    expect(violations).to be_empty
  end

  it "does not flag components with non-Bootstrap classes" do
    violations = check(<<~RUBY)
      def view_template
        Heading(level: 2, class: "gm-heading-xl my-custom-class") { "Title" }
      end
    RUBY

    expect(violations).to be_empty
  end

  it "does not flag dynamic class values" do
    violations = check(<<~RUBY)
      def view_template
        Text(class: computed_class) { "Body" }
      end
    RUBY

    expect(violations).to be_empty
  end

  it "does not flag non-standardized components with Bootstrap classes" do
    violations = check(<<~RUBY)
      def view_template
        FlexRow(class: "mb-3") { }
      end
    RUBY

    expect(violations).to be_empty
  end

  it "does not flag standardized components in atom files (atoms define their own internals)" do
    violations = check(<<~RUBY, file_path: "app/components/glass_morph/atoms/button.rb")
      def view_template
        Icon(name: "arrow", class: "ms-2")
      end
    RUBY

    expect(violations).to be_empty
  end
end
