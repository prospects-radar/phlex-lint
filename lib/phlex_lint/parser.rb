# frozen_string_literal: true

require "parser/current"
require "set"

module PhlexLint
  # Parses a Phlex component Ruby file into a PhlexNode tree.
  #
  # The parser:
  #   1. Uses the `parser` gem to produce a Ruby AST
  #   2. Extracts all private `def` methods as a helper map
  #   3. Walks `view_template`, expanding helper calls inline
  #   4. Produces a PhlexNode tree where each node is a rendered component
  #
  # Also collects skip annotations (# phlex-lint:disable ...) for suppressing
  # violations on specific lines.
  class Parser
    SKIP_PATTERN = /phlex-lint:disable\s*(.*)/

    # Standard HTML elements available as Phlex helper methods.
    # Used by rules to distinguish raw HTML from component calls.
    RAW_HTML_ELEMENTS = Set.new(%i[
      a abbr address article aside b bdi bdo blockquote br button
      canvas caption cite code col colgroup data datalist dd del
      details dfn dialog div dl dt em embed fieldset figcaption
      figure footer form h1 h2 h3 h4 h5 h6 header hgroup hr i
      iframe img input ins kbd label legend li link main map mark
      menu meter nav noscript object ol optgroup option output p
      param picture pre progress q rp rt ruby s samp script
      search section select slot small source span strong sub
      summary sup svg table tbody td template textarea tfoot th
      thead time tr track u ul var video wbr
    ]).freeze

    attr_reader :skip_annotations

    # Parse a file on disk. Returns a PhlexNode root, or nil if unparseable.
    def self.parse_file(file_path)
      source = File.read(file_path)
      new(source, file_path).parse
    rescue Errno::ENOENT
      nil
    end

    # Parse a source string. Returns a PhlexNode root, or nil if unparseable.
    def self.parse_source(source, file_path = "(string)")
      new(source, file_path).parse
    end

    def initialize(source, file_path = "(string)")
      @source = source
      @file_path = file_path
      @expanding_helpers = Set.new  # cycle detection for recursive/mutual helper calls
      @skip_annotations = {}       # { line_number => [:all] or [RuleName, ...] }
    end

    def parse
      collect_skip_annotations
      ast = build_ruby_ast
      return nil unless ast

      @helpers = extract_helpers(ast)

      view_template = find_view_template(ast)
      return nil unless view_template

      root = PhlexNode.new(name: :__root__, source_node: view_template)
      walk(view_template.children[2], parent: root)
      root
    end

    # Check if a rule is disabled for a given line number.
    def disabled_at?(line, rule_name)
      return false unless @skip_annotations.key?(line)

      disabled_rules = @skip_annotations[line]
      disabled_rules.include?(:all) || disabled_rules.include?(rule_name)
    end

    private

    def collect_skip_annotations
      @source.each_line.with_index(1) do |line, line_number|
        match = line.match(SKIP_PATTERN)
        next unless match

        rules_str = match[1].strip
        if rules_str.empty?
          # Bare "# phlex-lint:disable" disables all rules for the next line
          @skip_annotations[line_number + 1] = [:all]
        else
          rule_names = rules_str.split(",").map(&:strip).reject(&:empty?)
          @skip_annotations[line_number + 1] = rule_names
        end
      end
    end

    def build_ruby_ast
      buffer = ::Parser::Source::Buffer.new(@file_path, source: @source)
      parser = ::Parser::CurrentRuby.new(::Parser::Builders::Default.new)
      parser.diagnostics.all_errors_are_fatal = false
      parser.diagnostics.ignore_warnings = true
      ast, = parser.parse_with_comments(buffer)
      ast
    rescue ::Parser::SyntaxError
      nil
    end

    # Build a map of { method_name_sym => body_node } for all defs except
    # view_template and initialize (which are the public interface).
    def extract_helpers(ast)
      helpers = {}
      each_ruby_node(ast, :def) do |node|
        method_name = node.children[0]
        next if %i[view_template initialize].include?(method_name)

        helpers[method_name] = node.children[2]
      end
      helpers
    end

    def find_view_template(ast)
      each_ruby_node(ast, :def) do |node|
        return node if node.children[0] == :view_template
      end
      nil
    end

    # Walk a Ruby AST node, adding PhlexNodes to the tree under `parent`.
    def walk(node, parent:)
      return unless node.is_a?(::Parser::AST::Node)

      case node.type
      when :begin
        node.children.each { |child| walk(child, parent:) }
      when :block
        walk_block(node, parent:)
      when :send
        walk_send(node, parent:)
      when :if
        # Walk both branches — the tree represents all possible render paths.
        walk(node.children[1], parent:)
        walk(node.children[2], parent:)
      end
      # lvar, ivar, str, int, const, etc. are opaque leaves — intentionally ignored.
    end

    def walk_block(node, parent:)
      send_node  = node.children[0]
      block_body = node.children[2]

      receiver, method_name, *arg_nodes = send_node.children

      if receiver.nil? && expandable_helper?(method_name)
        # Helper block (unusual but possible): expand the helper body, ignore the block.
        expand_helper(method_name, parent:)
        return
      end

      if component?(method_name)
        kwargs    = extract_kwargs(arg_nodes)
        phlex_node = PhlexNode.new(
          name:        method_name,
          kwargs:      kwargs,
          children:    [],
          parent:      parent,
          source_node: send_node
        )
        parent.children << phlex_node
        walk(block_body, parent: phlex_node)
      else
        # Non-component block (form_with, each, etc.): walk its body transparently
        # in the same parent context so nested components remain visible.
        walk(block_body, parent:)
      end
    end

    def walk_send(node, parent:)
      receiver, method_name, *arg_nodes = node.children

      if receiver.nil? && expandable_helper?(method_name)
        expand_helper(method_name, parent:)
        return
      end

      return unless component?(method_name)

      kwargs    = extract_kwargs(arg_nodes)
      phlex_node = PhlexNode.new(
        name:        method_name,
        kwargs:      kwargs,
        children:    [],
        parent:      parent,
        source_node: node
      )
      parent.children << phlex_node
    end

    def expandable_helper?(method_name)
      @helpers.key?(method_name) && !@expanding_helpers.include?(method_name)
    end

    def expand_helper(method_name, parent:)
      @expanding_helpers.add(method_name)
      walk(@helpers[method_name], parent:)
      @expanding_helpers.delete(method_name)
    end

    # A method call is a component if its name starts with an uppercase letter.
    # This matches Phlex's convention: GlassCard, FlexColumn, PageContainer, etc.
    def component?(name)
      name.is_a?(Symbol) && name.to_s.match?(/\A[A-Z]/)
    end

    # Extract keyword arguments from the argument list of a send node.
    # Returns a Hash of { key_sym => value }. Dynamic values map to :__dynamic__.
    def extract_kwargs(arg_nodes)
      kwargs = {}
      arg_nodes.each do |arg|
        next unless arg.is_a?(::Parser::AST::Node)

        hash_node = case arg.type
                    when :hash   then arg
                    when :kwargs then arg
                    else              next
                    end

        hash_node.children.each do |child|
          next unless child.is_a?(::Parser::AST::Node) && child.type == :pair

          key_node, value_node = child.children
          key = extract_sym(key_node)
          next unless key

          kwargs[key] = extract_literal_value(value_node)
        end
      end
      kwargs
    end

    def extract_sym(node)
      return nil unless node.is_a?(::Parser::AST::Node)

      case node.type
      when :sym then node.children[0]
      when :str then node.children[0].to_sym
      end
    end

    # Extract a static value from a node. Returns :__dynamic__ for non-literals.
    def extract_literal_value(node)
      return :__dynamic__ unless node.is_a?(::Parser::AST::Node)

      case node.type
      when :sym   then node.children[0]
      when :str   then node.children[0]
      when :true  then true
      when :false then false
      when :nil   then nil
      when :int   then node.children[0]
      else             :__dynamic__
      end
    end

    # Depth-first traversal of a Ruby AST, yielding nodes of the given type.
    def each_ruby_node(node, type, &block)
      return unless node.is_a?(::Parser::AST::Node)

      yield node if node.type == type
      node.children.each { |child| each_ruby_node(child, type, &block) }
    end
  end
end
