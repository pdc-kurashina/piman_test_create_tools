# frozen_string_literal: true

require 'pathname'

class CreateMarkdownSchema
  def main
    # mainメソッドの内容
  end

  # 他のメソッド
  def parse_schema(schema_content)
    # parse_schemaメソッドの内容
  end

  def column_element(col_name, col_type, options_str)
    # column_elementメソッドの内容
  end

  def parse_constraints(options_str)
    # parse_constraintsメソッドの内容
  end

  def generate_markdown(tables)
    # generate_markdownメソッドの内容
  end

  def format_column_type(col_type, remarks)
    # format_column_typeメソッドの内容
  end
end  # <-- このendがクラスの終了


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
    return { not_null: false, primary_key: false, remarks: '' } if options_str.nil? || options_str.strip.empty?

    constraints = {
      not_null: false,
      primary_key: false,
      remarks: ''.dup  # 空文字列をdupで複製して変更可能にする
    }

    pattern_map = {
      /null:\s*(false|true)/ => ->(val) { constraints[:not_null] = val == 'false' },
      /default:\s*([^,]+)/ => ->(val) { constraints[:remarks] << "default=#{val}, " },
      /limit:\s*([^,]+)/ => ->(val) { constraints[:remarks] << "limit=#{val}, " },
      /precision:\s*([^,]+)/ => ->(val) { constraints[:remarks] << "precision=#{val}, " },
      /scale:\s*([^,]+)/ => ->(val) { constraints[:remarks] << "scale=#{val}, " },
      /primary_key:\s*(true|false)/ => ->(val) { constraints[:primary_key] = val == 'true' }
    }

    pattern_map.each do |regex, converter|
      if options_str =~ regex
        match_value = Regexp.last_match(1).strip
        converter.call(match_value)
      end
    end

    constraints[:remarks].strip!
    constraints[:remarks].chomp!(',')

    constraints
  end

  def generate_markdown(tables)
    # 論理カラム名のマッピング（例として一部を追加）
    logical_column_names = {
      'id' => 'ID',
      'name' => '顧客名',
      'kana' => '顧客名（かな）',
      'note' => '備考',
      'created_user_id' => '作成者',
      'updated_user_id' => '更新者',
      'created_at' => '作成日時',
      'updated_at' => '更新日時',
      'supplier' => '直接取引先',
      'cancelled' => '解約済み'
    }

    lines = []
    lines << "| 物理カラム名 | 論理カラム名 | 型 | 長さ | NOT NULL | Primary Key | 備考 |"
    lines << "| --- | --- | --- | --- | --- | --- | --- |"

    tables.each do |table|
      table[:columns].each do |col|
        col_name = col[:name]
        logical_name = logical_column_names[col_name] || 'N/A'
        col_type = format_column_type(col[:type], col[:constraints][:remarks])
        col_length = col_type.include?('VARCHAR') ? col[:constraints][:remarks][/(?<=limit=)\d+/] || 'ー' : 'ー'
        not_null = col[:constraints][:not_null] ? '○' : 'ー'
        primary_key = col[:constraints][:primary_key] ? '○' : 'ー'
        remarks = col[:constraints][:remarks].gsub(/limit=\d+,?/, '').strip

        lines << "| #{col_name} | #{logical_name} | #{col_type} | #{col_length} | #{not_null} | #{primary_key} | #{remarks} |"
      end
    end

    lines.join("\n")
  end

  def format_column_type(col_type, remarks)
    case col_type.downcase
    when 'string'
      # VARCHARの長さをremarksから取得し、適切に表示する
      if remarks =~ /limit=(\d+)/
        "VARCHAR(#{$1})"
      else
        'VARCHAR'
      end
    when 'integer'
      'INT'
    when 'datetime'
      'DATETIME'
    when 'boolean'
      'INT'  # BOOLEAN型をINTで表現するように変更
    else
      col_type.upcase
    end
  end



# スクリプト実行
CreateMarkdownSchema.new.main if __FILE__ == $PROGRAM_NAME
