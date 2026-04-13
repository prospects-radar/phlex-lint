# frozen_string_literal: true

module PhlexLint
  module Rules
    # Views may compose components, but they must not render other view classes.
    #
    # Reusable Phlex subviews belong in app/components so the boundary remains:
    # views are composition roots, components are reusable building blocks.
    #
    # @example Bad
    #   render Views::GlassMorph::Shared::RecommendedActionsTileContent.new(...)
    #   render Contexts::FollowUpTask.new(...)
    #
    # @example Good
    #   render Components::GlassMorph::Organisms::Shared::RecommendedActionsTileContent.new(...)
    #   render Components::GlassMorph::Molecules::TileBody.new(...)
    class NoSubviewRenderingInViews < Rule
      category "Architecture"

      MESSAGE = "Views must not render other view classes (`%<target>s`). " \
                "Move reusable subviews into app/components and render organisms, molecules, or atoms instead."

      RELATIVE_VIEW_NAMESPACES = %w[Contexts].freeze

      def self.applies_to_file?(file_path)
        file_path.include?("app/views/glass_morph") &&
          !file_path.include?("app/views/glass_morph/devise")
      end

      def check(tree)
        source_node = tree.source_node
        return unless source_node

        each_ruby_node(source_node) do |node|
          next unless render_call?(node)

          target_node = render_target_node(node)
          target_path = constant_path(target_node)
          next unless subview_target?(target_path)

          violation(
            PhlexNode.new(name: :render, kwargs: { target: target_path }, source_node: node),
            format(MESSAGE, target: target_path)
          )
        end
      end

      private

      def render_call?(node)
        node.is_a?(::Parser::AST::Node) &&
          node.type == :send &&
          node.children[1] == :render
      end

      def render_target_node(node)
        target = node.children[2]
        return unless target.is_a?(::Parser::AST::Node)

        if target.type == :send && target.children[1] == :new
          target.children[0]
        else
          target
        end
      end

      def subview_target?(target_path)
        return false if target_path.nil?
        return true if target_path.start_with?("Views::")

        relative_namespace = target_path.split("::").first
        RELATIVE_VIEW_NAMESPACES.include?(relative_namespace) || relative_subview_path_exists?(target_path)
      end

      def relative_subview_path_exists?(target_path)
        current_dir = File.dirname(@file_path)
        relative_path = target_path.split("::").map { |segment| underscore(segment) }
        File.exist?(File.join(current_dir, *relative_path) + ".rb")
      end

      def constant_path(node)
        return unless node.is_a?(::Parser::AST::Node)

        case node.type
        when :const
          parent, name = node.children
          parent_path = constant_path(parent)
          parent_path ? "#{parent_path}::#{name}" : name.to_s
        when :cbase
          nil
        else
          nil
        end
      end

      def each_ruby_node(node, &block)
        return unless node.is_a?(::Parser::AST::Node)

        yield node
        node.children.each { |child| each_ruby_node(child, &block) }
      end

      def underscore(segment)
        segment
          .to_s
          .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
          .gsub(/([a-z\d])([A-Z])/, '\1_\2')
          .tr("-", "_")
          .downcase
      end
    end
  end
end
