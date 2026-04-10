# frozen_string_literal: true

require "spec_helper"

RSpec.describe PhlexLint::Rules::ButtonRequiresVariant do
  def violations_for(source, file_path: "app/components/test.rb")
    tree = PhlexLint::Parser.parse_source(source)
    rule = described_class.new(file_path:)
    rule.check(tree)
    rule.violations
  end

  it "flags Button without variant: kwarg" do
    violations = violations_for(<<~RUBY)
      def view_template
        Button(text: t("actions.save"))
      end
    RUBY

    expect(violations.count).to eq(1)
    expect(violations.first.message).to include("variant:")
  end

  it "does not flag Button with variant: :primary" do
    violations = violations_for(<<~RUBY)
      def view_template
        Button(text: t("actions.save"), variant: :primary)
      end
    RUBY

    expect(violations).to be_empty
  end

  it "does not flag Button with variant: :secondary" do
    violations = violations_for(<<~RUBY)
      def view_template
        Button(text: t("actions.sync"), variant: :secondary, icon: "arrow-repeat")
      end
    RUBY

    expect(violations).to be_empty
  end

  it "does not flag Button with variant: :danger" do
    violations = violations_for(<<~RUBY)
      def view_template
        Button(text: t("actions.delete"), variant: :danger, icon: "trash")
      end
    RUBY

    expect(violations).to be_empty
  end

  it "flags multiple Buttons missing variant in one file" do
    violations = violations_for(<<~RUBY)
      def view_template
        FlexRow(gap: :sm) do
          Button(text: t("actions.save"))
          Button(text: t("actions.cancel"))
        end
      end
    RUBY

    expect(violations.count).to eq(2)
  end

  it "flags Button inside a helper method" do
    violations = violations_for(<<~RUBY)
      def view_template
        PageContainer do
          render_actions
        end
      end

      def render_actions
        FlexRow(gap: :sm) do
          Button(text: t("actions.save"))
        end
      end
    RUBY

    expect(violations.count).to eq(1)
  end

  it "does not flag when variant: is dynamic" do
    violations = violations_for(<<~RUBY)
      def view_template
        Button(text: t("actions.submit"), variant: computed_variant)
      end
    RUBY

    # variant: key is present (value is :__dynamic__), no offense
    expect(violations).to be_empty
  end
end
