# frozen_string_literal: true

require "spec_helper"
require "phlex_lint/rules/no_subview_rendering_in_views"

RSpec.describe PhlexLint::Rules::NoSubviewRenderingInViews do
  def check(source, file_path: "app/views/glass_morph/task_wizard/context.rb")
    tree = PhlexLint::Parser.parse_source(source, file_path)
    return [] unless tree
    return [] unless described_class.applies_to_file?(file_path)

    rule = described_class.new(file_path:)
    rule.check(tree)
    rule.violations
  end

  it "flags rendering another view class through the Views namespace" do
    violations = check(<<~RUBY, file_path: "app/views/glass_morph/prospects/show.rb")
      def view_template
        render Views::GlassMorph::Shared::RecommendedActionsTileContent.new(prospect: @prospect)
      end
    RUBY

    expect(violations.count).to eq(1)
    expect(violations.first.message).to include("Views::GlassMorph::Shared::RecommendedActionsTileContent")
    expect(violations.first.message).to include("app/components")
  end

  it "flags rendering a relative subview namespace such as Contexts" do
    violations = check(<<~RUBY)
      def view_template
        render Contexts::FollowUpTask.new(task: @task)
      end
    RUBY

    expect(violations.count).to eq(1)
    expect(violations.first.message).to include("Contexts::FollowUpTask")
  end

  it "does not flag rendering organisms from components" do
    violations = check(<<~RUBY, file_path: "app/views/glass_morph/prospects/show.rb")
      def view_template
        render Components::GlassMorph::Organisms::Shared::RecommendedActionsTileContent.new(prospect: @prospect)
      end
    RUBY

    expect(violations).to be_empty
  end

  it "does not flag rendering molecules or atom factories" do
    violations = check(<<~RUBY, file_path: "app/views/glass_morph/prospects/show.rb")
      def view_template
        render Components::GlassMorph::Molecules::TileBody.new do
          render Badge.inline_count(3)
        end
      end
    RUBY

    expect(violations).to be_empty
  end

  it "does not apply to devise views" do
    violations = check(<<~RUBY, file_path: "app/views/glass_morph/devise/sessions/new.rb")
      def view_template
        render Views::GlassMorph::Shared::RecommendedActionsTileContent.new(prospect: @prospect)
      end
    RUBY

    expect(violations).to be_empty
  end

  it "does not apply to non-glass_morph views" do
    violations = check(<<~RUBY, file_path: "app/views/admin/foo.rb")
      def view_template
        render Views::GlassMorph::Shared::RecommendedActionsTileContent.new(prospect: @prospect)
      end
    RUBY

    expect(violations).to be_empty
  end
end
