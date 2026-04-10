# frozen_string_literal: true

module PhlexLint
  # A node in the Phlex semantic component tree.
  #
  # Unlike a Ruby AST node (which represents syntax), a PhlexNode represents a
  # rendered component — with its component name, kwargs, and children already
  # resolved (including inlined helper method bodies).
  class PhlexNode
    attr_reader :name, :kwargs, :children, :parent, :source_node

    def initialize(name:, kwargs: {}, children: [], parent: nil, source_node: nil)
      @name = name
      @kwargs = kwargs
      @children = children
      @parent = parent
      @source_node = source_node
    end

    # Returns the value of a keyword argument, or nil if not present.
    def kwarg(key)
      @kwargs[key]
    end

    # Depth-first traversal yielding every node in the tree.
    # Pass a component name Symbol to filter (e.g. each_node(:GlassCard)).
    # The synthetic :__root__ node is never yielded.
    def each_node(component_name = nil, &block)
      return enum_for(:each_node, component_name) unless block_given?

      unless @name == :__root__
        yield self if component_name.nil? || @name == component_name
      end

      @children.each { |child| child.each_node(component_name, &block) }
    end

    # Returns direct children whose name matches the given component name.
    def direct_children_named(component_name)
      @children.select { |c| c.name == component_name }
    end

    # Returns true if any ancestor node has the given component name.
    def ancestor?(component_name)
      return false if @parent.nil? || @parent.name == :__root__
      return true if @parent.name == component_name

      @parent.ancestor?(component_name)
    end

    # Returns true if any ancestor satisfies the given block.
    # Useful for checking ancestors with specific kwargs, e.g.:
    #   node.any_ancestor? { |a| a.name == :GlassCard && a.kwarg(:variant) == :section }
    def any_ancestor?(&block)
      parent = @parent
      while parent && parent.name != :__root__
        return true if yield(parent)

        parent = parent.parent
      end
      false
    end

    # Returns the root node (:__root__) of the tree.
    def root
      @parent.nil? ? self : @parent.root
    end

    def inspect
      args = @kwargs.map { |k, v| "#{k}: #{v.inspect}" }.join(", ")
      children_str = @children.empty? ? "" : " [#{@children.map(&:name).join(', ')}]"
      "#{@name}(#{args})#{children_str}"
    end

    alias to_s inspect
  end
end
