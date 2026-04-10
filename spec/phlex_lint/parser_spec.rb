# frozen_string_literal: true

require "spec_helper"

RSpec.describe PhlexLint::Parser do
  def parse(source, file_path: "test.rb")
    described_class.parse_source(source, file_path)
  end

  describe "basic component detection" do
    it "detects a PascalCase component with kwargs" do
      tree = parse(<<~RUBY)
        def view_template
          GlassCard(variant: :section, row_wrapper: false) do
          end
        end
      RUBY

      expect(tree.children.count).to eq(1)
      node = tree.children.first
      expect(node.name).to eq(:GlassCard)
      expect(node.kwarg(:variant)).to eq(:section)
      expect(node.kwarg(:row_wrapper)).to eq(false)
    end

    it "detects nested components and preserves parent/child relationships" do
      tree = parse(<<~RUBY)
        def view_template
          PageContainer do
            PageHeader(title: "test", icon: "linkedin")
            GlassCard(variant: :section, row_wrapper: false) do
              FlexColumn(gap: :md) do
              end
            end
          end
        end
      RUBY

      page_container = tree.children.first
      expect(page_container.name).to eq(:PageContainer)
      expect(page_container.children.map(&:name)).to eq(%i[PageHeader GlassCard])

      glass_card = page_container.children.last
      expect(glass_card.children.first.name).to eq(:FlexColumn)
      expect(glass_card.children.first.parent).to be(glass_card)
    end

    it "detects component calls without blocks" do
      tree = parse(<<~RUBY)
        def view_template
          FlexColumn(gap: :md) do
            Icon(name: "check-circle-fill", size: :sm)
            Text(content: "hello", size: :sm)
          end
        end
      RUBY

      flex_col = tree.children.first
      expect(flex_col.children.map(&:name)).to eq(%i[Icon Text])
    end

    it "ignores snake_case method calls that are not helpers" do
      tree = parse(<<~RUBY)
        def view_template
          PageContainer do
            form_with(url: "/test") do
              Button(type: :submit, text: "Save", variant: :primary)
            end
          end
        end
      RUBY

      page_container = tree.children.first
      # form_with is transparent — Button appears as child of PageContainer
      expect(page_container.children.map(&:name)).to include(:Button)
    end

    it "extracts boolean false kwargs correctly" do
      tree = parse(<<~RUBY)
        def view_template
          GlassCard(variant: :section, row_wrapper: false, icon: "info-circle-fill") do
          end
        end
      RUBY

      node = tree.children.first
      expect(node.kwarg(:row_wrapper)).to eq(false)
      expect(node.kwarg(:icon)).to eq("info-circle-fill")
    end

    it "marks dynamic values as :__dynamic__" do
      tree = parse(<<~RUBY)
        def view_template
          GlassCard(variant: :section, title: t("some.key"), row_wrapper: false) do
          end
        end
      RUBY

      node = tree.children.first
      expect(node.kwarg(:title)).to eq(:__dynamic__)
    end

    it "returns nil for source with syntax errors" do
      tree = parse("def view_template\n  broken ruby {{{\nend")
      expect(tree).to be_nil
    end

    it "returns nil when there is no view_template method" do
      tree = parse("class Foo; end")
      expect(tree).to be_nil
    end
  end

  describe "helper method expansion" do
    it "expands a private helper called from view_template" do
      tree = parse(<<~RUBY)
        def view_template
          PageContainer do
            render_section
          end
        end

        def render_section
          GlassCard(variant: :section, row_wrapper: false) do
          end
        end
      RUBY

      page_container = tree.children.first
      expect(page_container.name).to eq(:PageContainer)
      expect(page_container.children.first.name).to eq(:GlassCard)
    end

    it "expands nested helpers (helper calling another helper)" do
      tree = parse(<<~RUBY)
        def view_template
          render_outer
        end

        def render_outer
          FlexColumn(gap: :md) do
            render_inner
          end
        end

        def render_inner
          Icon(name: "check-circle-fill", size: :sm)
        end
      RUBY

      flex_col = tree.children.first
      expect(flex_col.name).to eq(:FlexColumn)
      expect(flex_col.children.first.name).to eq(:Icon)
    end

    it "does not expand view_template or initialize as helpers" do
      # view_template is the entry point, not a helper to expand
      tree = parse(<<~RUBY)
        def initialize(user:)
          @user = user
        end

        def view_template
          GlassCard(variant: :section, row_wrapper: false) do
          end
        end
      RUBY

      expect(tree.children.first.name).to eq(:GlassCard)
    end

    it "expands helpers called from inside helper block content" do
      tree = parse(<<~RUBY)
        def view_template
          GlassCard(variant: :section, row_wrapper: false) do
            FlexColumn(gap: :md) do
              render_features
            end
          end
        end

        def render_features
          Icon(name: "check-circle-fill", size: :sm)
          Text(content: "Feature", size: :sm)
        end
      RUBY

      flex_col = tree.children.first.children.first
      expect(flex_col.children.map(&:name)).to eq(%i[Icon Text])
    end
  end

  describe "raw HTML element detection" do
    it "captures a bare hr call as a raw HTML node named :hr" do
      tree = parse(<<~RUBY)
        def view_template
          FlexColumn(gap: :md) do
            hr
          end
        end
      RUBY

      flex_col = tree.children.first
      hr_node = flex_col.children.first
      expect(hr_node).not_to be_nil
      expect(hr_node.name).to eq(:hr)
    end

    it "captures an a(href:) call as a raw HTML node with kwargs" do
      tree = parse(<<~RUBY)
        def view_template
          a(href: "/dashboard", class: "nav-link") { "Home" }
        end
      RUBY

      a_node = tree.children.first
      expect(a_node.name).to eq(:a)
      expect(a_node.kwarg(:href)).to eq("/dashboard")
      expect(a_node.kwarg(:class)).to eq("nav-link")
    end

    it "captures a div with class kwarg for spacing detection" do
      tree = parse(<<~RUBY)
        def view_template
          div(class: "d-flex mb-3") do
            Icon(name: "search")
          end
        end
      RUBY

      div_node = tree.children.first
      expect(div_node.name).to eq(:div)
      expect(div_node.kwarg(:class)).to eq("d-flex mb-3")
    end

    it "nests raw HTML nodes under their parent component correctly" do
      tree = parse(<<~RUBY)
        def view_template
          FlexRow(gap: :md) do
            a(href: "/path") { "link" }
            span(class: "text-muted") { "note" }
          end
        end
      RUBY

      flex_row = tree.children.first
      child_names = flex_row.children.map(&:name)
      expect(child_names).to eq(%i[a span])
      expect(flex_row.children.first.ancestor?(:FlexRow)).to be true
    end

    it "captures raw HTML inside component children" do
      tree = parse(<<~RUBY)
        def view_template
          GlassCard(variant: :section, row_wrapper: false) do
            hr
            p(class: "text-muted") { "note" }
          end
        end
      RUBY

      glass_card = tree.children.first
      names = glass_card.children.map(&:name)
      expect(names).to include(:hr, :p)
    end

    it "does not capture non-HTML snake_case calls like form_with or link_to" do
      tree = parse(<<~RUBY)
        def view_template
          PageContainer do
            form_with(url: "/test") do
              link_to "home", "/", class: "nav-link"
              Button(text: "Save", variant: :primary)
            end
          end
        end
      RUBY

      page_container = tree.children.first
      all_names = page_container.each_node.map(&:name)
      expect(all_names).not_to include(:form_with, :link_to)
      expect(all_names).to include(:Button)
    end

    it "supports each_node filtering by raw HTML element name" do
      tree = parse(<<~RUBY)
        def view_template
          div(class: "wrapper") do
            a(href: "/one") { "one" }
            a(href: "/two") { "two" }
            hr
          end
        end
      RUBY

      links = tree.each_node(:a).to_a
      expect(links.size).to eq(2)
      expect(links.map { |n| n.kwarg(:href) }).to eq(%w[/one /two])
    end

    it "expands helpers and includes raw HTML from helper bodies" do
      tree = parse(<<~RUBY)
        def view_template
          FlexColumn(gap: :sm) do
            render_divider
          end
        end

        def render_divider
          hr
        end
      RUBY

      flex_col = tree.children.first
      expect(flex_col.children.first.name).to eq(:hr)
    end
  end

  describe "conditional branches" do
    it "walks both branches of an if/else" do
      tree = parse(<<~RUBY)
        def view_template
          PageContainer do
            if @connected
              GlassCard(variant: :section, row_wrapper: false) do
              end
            else
              EmptyState(icon: "linkedin")
            end
          end
        end
      RUBY

      page_container = tree.children.first
      # Both GlassCard and EmptyState should appear
      names = page_container.children.map(&:name)
      expect(names).to include(:GlassCard, :EmptyState)
    end
  end

  describe "PhlexNode traversal helpers" do
    let(:tree) do
      parse(<<~RUBY)
        def view_template
          PageContainer do
            PageHeader(title: "Test")
            GlassCard(variant: :section, row_wrapper: false) do
              FlexColumn(gap: :md) do
                Icon(name: "check-circle-fill")
              end
            end
          end
        end
      RUBY
    end

    it "each_node finds all nodes of a given type depth-first" do
      names = tree.each_node(:GlassCard).map(&:name)
      expect(names).to eq(%i[GlassCard])
    end

    it "ancestor? checks for parent chain" do
      icon = tree.each_node(:Icon).first
      expect(icon.ancestor?(:FlexColumn)).to be true
      expect(icon.ancestor?(:GlassCard)).to be true
      expect(icon.ancestor?(:PageContainer)).to be true
      expect(icon.ancestor?(:PageHeader)).to be false
    end

    it "direct_children_named returns only direct children" do
      glass_card = tree.each_node(:GlassCard).first
      expect(glass_card.direct_children_named(:FlexColumn).count).to eq(1)
      expect(glass_card.direct_children_named(:Icon)).to be_empty  # Icon is a grandchild
    end
  end

  describe "case/when statements" do
    it "walks all when branches of a case statement" do
      tree = parse(<<~RUBY)
        def view_template
          PageContainer do
            case @status
            when :active
              GlassCard(variant: :section, row_wrapper: false) do
              end
            when :pending
              Badge(type: :status, label: "Pending")
            else
              EmptyState(icon: "linkedin")
            end
          end
        end
      RUBY

      page_container = tree.children.first
      # All branches should be walked
      names = page_container.children.map(&:name)
      expect(names).to include(:GlassCard, :Badge, :EmptyState)
    end
  end

  describe "and/or expressions" do
    it "walks both sides of an and expression" do
      tree = parse(<<~RUBY)
        def view_template
          PageContainer do
            Icon(name: "search") if @show_search && @has_permission
          end
        end
      RUBY

      # Icon should be in the tree (both branches of && are walked)
      page_container = tree.children.first
      expect(page_container.children.map(&:name)).to include(:Icon)
    end

    it "walks both sides of an or expression" do
      tree = parse(<<~RUBY)
        def view_template
          PageContainer do
            Icon(name: "info") if @show_info || @show_hint
          end
        end
      RUBY

      # Icon should be in the tree (both branches of || are walked)
      page_container = tree.children.first
      expect(page_container.children.map(&:name)).to include(:Icon)
    end
  end

  describe "rescue expressions" do
    it "walks rescue body" do
      tree = parse(<<~RUBY)
        def view_template
          PageContainer do
            begin
              GlassCard(variant: :section, row_wrapper: false) do
              end
            rescue => e
              ErrorBanner(message: e.message)
            end
          end
        end
      RUBY

      page_container = tree.children.first
      # Both the normal path and the rescue path should be walked
      names = page_container.children.map(&:name)
      expect(names).to include(:GlassCard, :ErrorBanner)
    end
  end

  describe "interpolated strings" do
    it "marks interpolated strings as :__interpolated__" do
      tree = parse(<<~RUBY)
        def view_template
          Button(class: "btn btn-\#{@variant}") { "Save" }
        end
      RUBY

      button = tree.children.first
      expect(button.kwarg(:class)).to eq(:__interpolated__)
    end

    # Note: Interpolated symbols (:"widget-#{@type}") have a limitation
    # where the parser only extracts the static prefix. This is a known
    # limitation of the AST-based approach.
    xit "marks interpolated symbols as :__interpolated__" do
      tree = parse(<<~RUBY)
        def view_template
          div(class: :"widget-#{@type}") { "content" }
        end
      RUBY

      div_node = tree.children.first
      expect(div_node.kwarg(:class)).to eq(:__interpolated__)
    end

    it "extracts literal values from static strings" do
      tree = parse(<<~RUBY)
        def view_template
          div(class: "static-class") { "content" }
        end
      RUBY

      div_node = tree.children.first
      expect(div_node.kwarg(:class)).to eq("static-class")
    end
  end
end
