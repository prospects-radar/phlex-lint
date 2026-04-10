# frozen_string_literal: true

require "spec_helper"

RSpec.describe PhlexLint::Rules::PageContainerInFlexRow do
  def violations_for(source)
    tree = PhlexLint::Parser.parse_source(source)
    rule = described_class.new(file_path: "app/components/test.rb")
    rule.check(tree)
    rule.violations
  end

  it "flags PageContainer directly inside FlexRow" do
    violations = violations_for(<<~RUBY)
      def view_template
        FlexRow(gap: :md) do
          Sidebar(nav_items: [])
          PageContainer do
            PageHeader(title: t("page.title"))
          end
        end
      end
    RUBY

    expect(violations.count).to eq(1)
    expect(violations.first.message).to include("FlexRow")
  end

  it "flags PageContainer nested deeply inside FlexRow" do
    violations = violations_for(<<~RUBY)
      def view_template
        FlexRow(gap: :md) do
          FlexColumn(gap: :lg) do
            PageContainer do
              PageHeader(title: t("page.title"))
            end
          end
        end
      end
    RUBY

    expect(violations.count).to eq(1)
  end

  it "does not flag PageContainer at the root level" do
    violations = violations_for(<<~RUBY)
      def view_template
        PageContainer do
          PageHeader(title: t("page.title"))
          FlexRow(gap: :md) { }
        end
      end
    RUBY

    expect(violations).to be_empty
  end

  it "does not flag FlexRow inside PageContainer" do
    violations = violations_for(<<~RUBY)
      def view_template
        PageContainer do
          FlexRow(gap: :md) do
            FlexColumn(gap: :lg) { }
          end
        end
      end
    RUBY

    expect(violations).to be_empty
  end
end
