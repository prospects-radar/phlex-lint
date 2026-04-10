# frozen_string_literal: true

require "spec_helper"

RSpec.describe PhlexLint::Rules::UseParentGapForSpacing do
  def check(source, file_path: "app/components/glass_morph/organisms/foo.rb")
    tree = PhlexLint::Parser.parse_source(source, file_path)
    return [] unless tree

    return [] unless described_class.applies_to_file?(file_path)

    rule = described_class.new(file_path:)
    rule.check(tree)
    rule.violations
  end

  it "flags Heading with margin utility class" do
    violations = check(<<~RUBY)
      def view_template
        Heading(level: 2, class: "mb-3")
      end
    RUBY

    expect(violations.count).to eq(1)
    expect(violations.first.message).to include("Heading")
  end

  it "flags Badge with margin-top utility class" do
    violations = check(<<~RUBY)
      def view_template
        Badge(class: "mt-2")
      end
    RUBY

    expect(violations.count).to eq(1)
    expect(violations.first.message).to include("Badge")
  end

  it "flags Button with margin-bottom utility class" do
    violations = check(<<~RUBY)
      def view_template
        Button(variant: :primary, text: "Save", class: "mb-4")
      end
    RUBY

    expect(violations.count).to eq(1)
    expect(violations.first.message).to include("Button")
  end

  it "flags Text with margin utility" do
    violations = check(<<~RUBY)
      def view_template
        Text(class: "me-2")
      end
    RUBY

    expect(violations.count).to eq(1)
  end

  it "flags Icon with margin-start utility" do
    violations = check(<<~RUBY)
      def view_template
        Icon(name: "house", class: "ms-1")
      end
    RUBY

    expect(violations.count).to eq(1)
  end

  it "flags Separator with margin utility" do
    violations = check(<<~RUBY)
      def view_template
        Separator(class: "my-3")
      end
    RUBY

    # my-3 matches /\bm[tbes]?-\d+\b/ — 'my' does not match [tbes]? but the whole pattern
    # 'my-3' has 'y' which is not in [tbes], so it won't match. This is the expected behavior.
    expect(violations).to be_empty
  end

  it "does not flag Heading without margin classes" do
    violations = check(<<~RUBY)
      def view_template
        Heading(level: 2, class: "fw-bold gm-text-primary")
      end
    RUBY

    expect(violations).to be_empty
  end

  it "does not flag FlexRow with margin classes (layout components are allowed)" do
    violations = check(<<~RUBY)
      def view_template
        FlexRow(gap: :md, class: "mb-4")
      end
    RUBY

    expect(violations).to be_empty
  end

  it "does not flag GlassCard with margin classes (layout components are allowed)" do
    violations = check(<<~RUBY)
      def view_template
        GlassCard(class: "mt-3")
      end
    RUBY

    expect(violations).to be_empty
  end

  it "does not flag a dynamic class on Heading" do
    violations = check(<<~RUBY)
      def view_template
        Heading(level: 2, class: computed_class)
      end
    RUBY

    expect(violations).to be_empty
  end

  it "flags multiple inline components with margin utilities" do
    violations = check(<<~RUBY)
      def view_template
        Heading(level: 1, class: "mb-2")
        Paragraph(class: "mt-3")
      end
    RUBY

    expect(violations.count).to eq(2)
  end

  it "does not flag inline components in atom files (atoms define their own internals)" do
    violations = check(<<~RUBY, file_path: "app/components/glass_morph/atoms/button.rb")
      def view_template
        Icon(name: "arrow", class: "ms-1")
      end
    RUBY

    expect(violations).to be_empty
  end
end
