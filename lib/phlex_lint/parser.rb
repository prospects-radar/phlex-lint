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
  # Component detection: method calls starting with an uppercase letter (PascalCase)
  # are treated as component calls. Snake_case calls matching a helper definition
  # are expanded inline. All other calls (form_with, t(), etc.) are opaque leaves.
  class Parser
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
      @disabled_rules = {}          # { line_number => Set of disabled rule names }
      parse_disabled_rules
    end

    def parse
      ast = build_ruby_ast
      return nil unless ast

      @helpers = extract_helpers(ast)

      view_template = find_view_template(ast)
      return nil unless view_template

      root = PhlexNode.new(name: :__root__, source_node: view_template)
      walk(view_template.children[2], parent: root)
      root
    end

    # Check if a rule is disabled at a specific line
    def rule_disabled_at_line?(rule_name, line)
      return false if @disabled_rules.empty?

      # Build the current disabled state at this line
      # Start with no disabled rules
      current_disabled = Set.new

      # Process all disable/enable directives up to this line
      @disabled_rules.keys.sort.each do |directive_line|
        next if directive_line > line  # Directives after this line don't affect it; same-line directives DO apply

        if @disabled_rules[directive_line] == :all
          # Disable or enable all rules
          # We need to know if it's a disable or enable directive
          # Let's check the actual line
          source_line = @source.lines[directive_line - 1]
          if source_line =~ /#\s*phlex-lint:disable/
            current_disabled = :all
          elsif source_line =~ /#\s*phlex-lint:enable/
            current_disabled = Set.new
          end
        else
          # Disable or enable specific rules
          source_line = @source.lines[directive_line - 1]
          if source_line =~ /#\s*phlex-lint:enable/
            # Enable specific rules - remove them from current_disabled
            current_disabled = current_disabled - @disabled_rules[directive_line]
          else
            # Disable specific rules - add them to current_disabled
            current_disabled = current_disabled | @disabled_rules[directive_line]
          end
        end
      end

      # Check if the rule is currently disabled
      return true if current_disabled == :all
      current_disabled.include?(rule_name)
    end

    private

    # Parse source comments for phlex-lint:disable and phlex-lint:enable directives
    def parse_disabled_rules
      @source.lines.each_with_index do |line, index|
        line_num = index + 1

        # Check for phlex-lint:disable or phlex-lint:enable
        if line =~ /#\s*phlex-lint:disable(?:\s+(.+))?/
          rules = $1
          if rules.nil? || rules.strip.empty? || rules.strip.start_with?("(")
            @disabled_rules[line_num] = :all
          else
            # Strip trailing comments (e.g., "RuleName -- reason" or "RuleName # rubocop:disable ...")
            clean_rules = rules.split('#').first.split('--').first
            @disabled_rules[line_num] = clean_rules.split(',').map(&:strip).reject(&:empty?).to_set
          end
        elsif line =~ /#\s*phlex-lint:enable(?:\s+(.+))?/
          rules = $1
          if rules.nil? || rules.strip.empty?
            # Enable all - store as :all to clear all previous disables
            @disabled_rules[line_num] = :all
          else
            # Enable specific rules - store as empty set to clear those specific rules
            # Note: This actually means "enable only these rules" not "clear these rules"
            # For simplicity, we treat enable without specific rules as :all
            @disabled_rules[line_num] = rules.split(',').map(&:strip).to_set
          end
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

      handled = case node.type
                when :begin
                  node.children.each { |child| walk(child, parent:) }
                  true
                when :block
                  walk_block(node, parent:)
                  true
                when :send
                  walk_send(node, parent:)
                  true
                when :if
                  # Walk both branches — the tree represents all possible render paths.
                  walk(node.children[1], parent:)
                  walk(node.children[2], parent:)
                  true
      when :case
        # Walk all when branches and else branch
        # case structure: [condition, when_node1, when_node2, ..., else_node]
        condition_node, *when_branches, else_branch = node.children
        when_branches.each do |when_node|
          # when_node structure: [:when, condition, body]
          # The body is at children[1]
          walk(when_node.children[1], parent:) if when_node.children[1]
        end
        walk(else_branch, parent:) if else_branch && else_branch != condition_node
                  true
                when :and, :or
                  # Walk both sides of and/or — all paths are possible
                  walk(node.children[0], parent:)
                  walk(node.children[1], parent:)
                  true
                when :resbody
                  # Walk rescue body (error handling paths)
                  walk(node.children[2], parent:) if node.children[2]
                  true
                else
                  false
                end

      # For unhandled node types, walk all children recursively
      unless handled
        node.children.each { |child| walk(child, parent:) }
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

      if component?(method_name) || tracked_method?(method_name)
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
      elsif receiver.nil? && raw_html_element?(method_name)
        kwargs     = extract_kwargs(arg_nodes)
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

      if component?(method_name) || tracked_method?(method_name)
        kwargs    = extract_kwargs(arg_nodes)
        phlex_node = PhlexNode.new(
          name:        method_name,
          kwargs:      kwargs,
          children:    [],
          parent:      parent,
          source_node: node
        )
        parent.children << phlex_node
      elsif receiver.nil? && raw_html_element?(method_name)
        kwargs     = extract_kwargs(arg_nodes)
        phlex_node = PhlexNode.new(
          name:        method_name,
          kwargs:      kwargs,
          children:    [],
          parent:      parent,
          source_node: node
        )
        parent.children << phlex_node
      end
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

    # Additional method names to track for linting purposes (not Phlex components)
    TRACKED_METHODS = Set.new(%i[content_tag tag]).freeze

    def tracked_method?(name)
      TRACKED_METHODS.include?(name)
    end

    # HTML element method names that Phlex maps to raw HTML output.
    # These are tracked as PhlexNodes with the element name as :name so rules
    # can detect raw HTML usage (e.g. `a` instead of Link, `hr` instead of Separator).
    RAW_HTML_ELEMENTS = Set.new(%i[
      a abbr address article aside audio
      b blockquote br button
      caption code col colgroup
      datalist dd del details dfn dialog div dl dt
      em
      fieldset figcaption figure footer form
      h1 h2 h3 h4 h5 h6 header hr
      i iframe img input
      kbd
      label legend li
      main mark menu meter
      nav
      ol optgroup option output
      p picture pre progress
      q
      s samp section select small span strong sub summary sup svg
      table tbody td template textarea tfoot th thead time tr
      u ul
      video
    ]).freeze

    def raw_html_element?(name)
      name.is_a?(Symbol) && RAW_HTML_ELEMENTS.include?(name)
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
      when :dstr  then :__interpolated__  # Interpolated string: "btn #{variant}"
      when :dsym  then :__interpolated__  # Interpolated symbol: :"btn-#{variant}"
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
