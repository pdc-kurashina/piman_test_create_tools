require 'pathname'

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
      # t.xxxx "column_name", [オプション]
      if line =~ /^\s*t\.(\w+)\s+"([^"]+)"(.*)$/
        col_type = Regexp.last_match(1)
        col_name = Regexp.last_match(2)
        options_str = Regexp.last_match(3).strip

        # constraintsを加工して人間が読みやすい文字列にする
        constraints = parse_constraints(options_str)
        columns << {
          name: col_name,
          type: col_type,
          constraints: constraints
        }
      end
    end

    tables << {
      table_name: tbl_name,
      columns: columns
    }
  end

  tables
end

def parse_constraints(options_str)
  return '' if options_str.nil? || options_str.strip.empty?

  constraints = []

  # null
  if options_str =~ /null:\s*(false|true)/
    not_null = Regexp.last_match(1) == 'false' ? 'NOT NULL' : 'NULL'
    constraints << not_null
  end

  # default
  if options_str =~ /default:\s*([^,]+)/ # default: value
    default_val = Regexp.last_match(1).strip
    constraints << "default=#{default_val}"
  end

  # limit
  if options_str =~ /limit:\s*([^,]+)/ # limit: 100
    limit_val = Regexp.last_match(1).strip
    constraints << "limit=#{limit_val}"
  end

  # precision
  if options_str =~ /precision:\s*([^,]+)/ # precision: 10
    precision_val = Regexp.last_match(1).strip
    constraints << "precision=#{precision_val}"
  end

  # scale
  if options_str =~ /scale:\s*([^,]+)/ # scale: 2
    scale_val = Regexp.last_match(1).strip
    constraints << "scale=#{scale_val}"
  end

  # 他にも必要に応じて正規表現で取り出す
  # e.g. unique: true, etc.

  constraints.join(', ')
end

def generate_markdown(tables)
  lines = []

  lines << "# Schema Information\n\n"

  tables.each do |table|
    lines << "## Table: `#{table[:table_name]}`\n"
    lines << "| Column Name | Type | Constraints |"
    lines << "|-------------|------|-------------|"

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

# スクリプト実行
main if __FILE__ == $PROGRAM_NAME
