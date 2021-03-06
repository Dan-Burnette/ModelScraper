require_relative 'application_service'

class ParseSchemaTables < ApplicationService
  def initialize(schema_content)
    @lines = schema_content.split("\n")
  end

  def call
    table_names_to_column_lines
  end

  private

  def table_names_to_column_lines
    table_definition_lines.inject({}) do |result, definition_line|
      table_name = table_name(definition_line)
      column_lines = table_column_lines(definition_line)
      result[table_name] = column_lines
      result
    end
  end

  def table_definition_lines
    @lines.select { |l| l.include?('create_table') }
  end

  def table_name(definition_line)
    terms = definition_line.split(' ')
    terms[1].delete(",'\"")
  end

  def table_column_lines(definition_line)
    column_lines = []

    line_index = @lines.index(definition_line) + 1
    current_line = @lines[line_index]
    while current_line.include?('t.')
      column_lines << current_line
      line_index += 1
      current_line = @lines[line_index]
    end

    column_lines
  end
end
