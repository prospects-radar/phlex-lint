# frozen_string_literal: true

require "spec_helper"

RSpec.describe PhlexLint::Rules::GlassCardSectionRequiresIconAndTitle do
  def violations_for(source)
    tree = PhlexLint::Parser.parse_source(source)
    rule = described_class.new(file_path: "app/components/test.rb")
    rule.check(tree)
    rule.violations
  end

  it "flags GlassCard(variant: :section) missing both icon: and title:" do
    violations = violations_for(<<~RUBY)
      def view_template
        GlassCard(variant: :section, row_wrapper: false) do
        end
      end
    RUBY

    expect(violations.count).to eq(1)
    expect(violations.first.message).to include("icon:")
    expect(violations.first.message).to include("title:")
  end

  it "flags GlassCard(variant: :section) missing only icon:" do
    violations = violations_for(<<~RUBY)
      def view_template
        GlassCard(variant: :section, title: t("section.title"), row_wrapper: false) do
        end
      end
    RUBY

    expect(violations.count).to eq(1)
    expect(violations.first.message).to match(/Missing:.*icon:/)
    expect(violations.first.message).not_to match(/Missing:.*title:/)
  end

  it "flags GlassCard(variant: :section) missing only title:" do
    violations = violations_for(<<~RUBY)
      def view_template
        GlassCard(variant: :section, icon: "info-circle-fill", row_wrapper: false) do
        end
      end
    RUBY

    expect(violations.count).to eq(1)
    expect(violations.first.message).to match(/Missing:.*title:/)
    expect(violations.first.message).not_to match(/Missing:.*icon:/)
  end

  it "does not flag GlassCard(variant: :section) with both icon: and title:" do
    violations = violations_for(<<~RUBY)
      def view_template
        GlassCard(variant: :section, icon: "info-circle-fill", title: t("section.title"), row_wrapper: false) do
        end
      end
    RUBY

    expect(violations).to be_empty
  end

  it "does not flag GlassCard with other variants" do
    violations = violations_for(<<~RUBY)
      def view_template
        GlassCard(variant: :glass) do
        end
      end
    RUBY

    expect(violations).to be_empty
  end

  it "does not flag GlassCard without variant (defaults to :glass)" do
    violations = violations_for(<<~RUBY)
      def view_template
        GlassCard(padding: :lg) do
        end
      end
    RUBY

    expect(violations).to be_empty
  end
end
