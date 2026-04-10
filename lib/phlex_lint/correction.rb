# frozen_string_literal: true

module PhlexLint
  # Represents a correction that can be applied to a file.
  # Subclasses implement the actual fix logic.
  class Correction
    attr_reader :file_path, :line, :column, :description

    def initialize(file_path:, line:, column:, description:)
      @file_path = file_path
      @line = line
      @column = column
      @description = description
    end

    # Override in subclasses to apply the correction.
    # Should modify the file and return true on success, false on failure.
    def apply
      raise NotImplementedError, "#{self.class}#apply must be implemented"
    end
  end

  # Add a keyword argument to a component call.
  class AddKwargCorrection < Correction
    attr_reader :kwarg_key, :kwarg_value

    def initialize(file_path:, line:, column:, kwarg_key:, kwarg_value:, description: nil)
      @kwarg_key = kwarg_key
      @kwarg_value = kwarg_value
      super(file_path: file_path, line: line, column: column, description: description || "Add #{kwarg_key}: #{kwarg_value}")
    end

    def apply
      return false unless File.exist?(file_path)

      lines = File.readlines(file_path)
      return false if line < 1 || line > lines.length

      # For single-line method calls, find insertion point on same line
      target_line = lines[line - 1]
      insertion_point = find_insertion_point(target_line)

      # If no closing paren on this line, it's a multi-line call - skip for now
      return false unless insertion_point

      kwarg_str = "#{kwarg_key}: #{format_value(kwarg_value)}"

      # Insert before the closing paren
      before_char = insertion_point > 0 ? target_line[insertion_point - 1] : ""

      if before_char == "("
        # No arguments, no comma needed
        replacement = kwarg_str + ")"
      else
        # Has arguments, add comma
        replacement = ", #{kwarg_str})"
      end

      # Preserve anything after the closing paren (like " do" or " { ... }")
      rest_of_line = target_line[insertion_point + 1..-1] || ""
      lines[line - 1] = target_line[0...insertion_point] + replacement + rest_of_line

      File.write(file_path, lines.join)
      true
    rescue StandardError => e
      warn "Failed to apply correction: #{e.message}"
      false
    end

    private

    def find_insertion_point(line)
      # Find the closing paren/bracket of the method call on this line
      # This is a simple heuristic - find the last ) or ] before "do" or end of line
      closing_paren = line.rindex(")")
      closing_bracket = line.rindex("]")

      if closing_paren && closing_bracket
        [closing_paren, closing_bracket].max
      elsif closing_paren
        closing_paren
      elsif closing_bracket
        closing_bracket
      end
    end

    def format_value(value)
      case value
      when Symbol
        ":#{value}"
      when String
        "\"#{value}\""
      when true, false, nil
        value.to_s
      else
        value.to_s
      end
    end
  end

  # Wrap a component with another component.
  class WrapComponentCorrection < Correction
    attr_reader :wrapper_name, :closing_tag

    def initialize(file_path:, line:, column:, wrapper_name:, closing_tag: nil, description: nil)
      @wrapper_name = wrapper_name
      @closing_tag = closing_tag || "end"
      super(
        file_path: file_path,
        line: line,
        column: column,
        description: description || "Wrap with #{wrapper_name}"
      )
    end

    def apply
      return false unless File.exist?(file_path)

      lines = File.readlines(file_path)
      return false if line < 1 || line > lines.length

      target_line = lines[line - 1]

      # Insert opening at the beginning of the component call
      indent = target_line[/\A\s*/]
      lines[line - 1] = "#{indent}#{wrapper_name} do\n#{target_line}"

      # Find the matching end and insert closing tag after it
      closing_line = find_matching_end(lines, line)
      if closing_line
        lines[closing_line] = "#{lines[closing_line]}#{indent}#{closing_tag}\n"
      end

      File.write(file_path, lines.join)
      true
    rescue StandardError => e
      warn "Failed to apply correction: #{e.message}"
      false
    end

    private

    def find_matching_end(lines, start_line)
      depth = 0
      (start_line - 1).upto(lines.length - 1) do |i|
        line = lines[i]
        depth += line.count("do") - line.count("end")
        return i if depth == 0 && i > start_line - 1
      end
      nil
    end
  end
end
