# frozen_string_literal: true

require "spec_helper"

RSpec.describe PhlexLint::Rules::SettingsPageUsesPageContainer do
  def violations_for(source, file_path: "app/components/settings/test/show_page.rb")
    tree = PhlexLint::Parser.parse_source(source)
    rule = described_class.new(file_path:)
    rule.check(tree)
    rule.violations
  end

  it "flags view_template that starts with FlexColumn instead of PageContainer" do
    violations = violations_for(<<~RUBY)
      def view_template
        FlexColumn(gap: :lg) do
          PageHeader(title: "Test")
        end
      end
    RUBY

    expect(violations.count).to eq(1)
    expect(violations.first.message).to include("PageContainer")
    expect(violations.first.message).to include("FlexColumn")
  end

  it "does not flag view_template that starts with PageContainer" do
    violations = violations_for(<<~RUBY)
      def view_template
        PageContainer do
          PageHeader(title: "Test")
        end
      end
    RUBY

    expect(violations).to be_empty
  end

  it "flags view_template that starts with GlassCard instead of PageContainer" do
    violations = violations_for(<<~RUBY)
      def view_template
        GlassCard(padding: :lg) do
          PageHeader(title: "Test")
        end
      end
    RUBY

    expect(violations.count).to eq(1)
    expect(violations.first.message).to include("GlassCard")
  end

  it "does not apply to non-settings files" do
    violations = violations_for(
      <<~RUBY,
        def view_template
          FlexColumn(gap: :lg) do
          end
        end
      RUBY
      file_path: "app/components/dashboard/show.rb"
    )

    expect(violations).to be_empty
  end

  it "applies to nested settings paths" do
    violations = violations_for(
      <<~RUBY,
        def view_template
          FlexColumn(gap: :lg) do
          end
        end
      RUBY
      file_path: "app/components/settings/linkedin_dma/show_page.rb"
    )

    expect(violations.count).to eq(1)
  end

  it "does not flag when view_template is empty" do
    violations = violations_for(<<~RUBY)
      def view_template
      end
    RUBY

    expect(violations).to be_empty
  end

  describe ".applies_to_file?" do
    it "returns true for settings component files" do
      expect(described_class.applies_to_file?("app/components/settings/foo/show_page.rb")).to be true
    end

    it "returns false for non-settings files" do
      expect(described_class.applies_to_file?("app/components/dashboard/index.rb")).to be false
    end

    it "returns false for views files" do
      expect(described_class.applies_to_file?("app/views/settings/show.rb")).to be false
    end
  end
end
