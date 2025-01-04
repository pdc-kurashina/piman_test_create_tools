# frozen_string_literal: true

require 'pathname'

class CreateMarkdownSchema
  def main
    # コマンドライン引数からファイルパスを取得
    schema_path = 'db_schema.rb'
    output_path = 'schema_tables.md'

    unless File.exist?(schema_path)
      puts "File not found: #{schema_path}"
      exit 1
    end

    schema_content = File.read(schema_path)

    # スキーマからテーブル情報をパース
    tables = parse_schema(schema_content)

    # テーブル情報をMarkdown形式で出力
    markdown = generate_markdown(tables)

    # ファイルに書き込む
    File.write(output_path, markdown)
    puts "Markdown file generated: #{output_path}"
  end

  private

  def parse_schema(schema_content)
    table_blocks = schema_content.scan(
      /create_table\s+"(?<tbl_name>[^"]+)"(.*?)do\s*\|(.*?)\|\s*(?<definition>.*?)end/m
    )

    tables = []

    table_blocks.each do |match|
      tbl_name    = match[0]
      definition  = match[1]

      # 各行に分割してパース
      lines = definition.lines.map(&:strip)

      columns = []
      lines.each do |line|
        next unless line =~ /^\s*t\.(\w+)\s+"([^"]+)"(.*)$/

        col_type = Regexp.last_match(1)
        col_name = Regexp.last_match(2)
        options_str = Regexp.last_match(3).strip

        columns << column_element(col_name, col_type, options_str)
      end

      tables << {
        table_name: tbl_name,
        columns: columns
      }
    end

    tables
  end

  def column_element(col_name, col_type, options_str)
    constraints = parse_constraints(options_str)
    {
      name: col_name,
      type: col_type,
      constraints: constraints
    }
  end

  def parse_constraints(options_str)
    return '' if options_str.nil? || options_str.strip.empty?

    constraints = []

    pattern_map = {
      /null:\s*(false|true)/ => ->(val) { val == 'false' ? 'NOT NULL' : 'NULL' },
      /default:\s*([^,]+)/ => ->(val) { "default=#{val}" },
      /limit:\s*([^,]+)/ => ->(val) { "limit=#{val}" },
      /precision:\s*([^,]+)/ => ->(val) { "precision=#{val}" },
      /scale:\s*([^,]+)/ => ->(val) { "scale=#{val}" }
      # 例: unique: true にも対応したいならここに追加
      # /unique:\s*(true|false)/ => ->(val) { "unique=#{val}" },
    }

    pattern_map.each do |regex, converter|
      if options_str =~ regex
        match_value = Regexp.last_match(1).strip
        constraints << converter.call(match_value)
      end
    end

    constraints.join(', ')
  end

  def generate_markdown(tables)
    lines = []

    lines << "# Schema Information\n\n"

    tables.each do |table|
      lines << "## Table: `#{table[:table_name]}`\n"
      lines << '| Column Name | Type | Constraints |'
      lines << '|-------------|------|-------------|'

      table[:columns].each do |col|
        col_name = col[:name]
        col_type = col[:type]
        col_constraints = col[:constraints]

        lines << "| `#{col_name}` | `#{col_type}` | #{col_constraints} |"
      end

      lines << "\n"
    end

    lines.join("\n")
  end
end

# スクリプト実行
CreateMarkdownSchema.new.main if __FILE__ == $PROGRAM_NAME
