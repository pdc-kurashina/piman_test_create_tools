# frozen_string_literal: true

require 'csv'
require 'i18n'

require './config/locales/initialize_i18n'

CSV_FILE = 'output.csv'
HTML_FILE = 'output.html'

class SetCsvToHtmlSetting
  include SettingI18n

  SettingI18n::SetI18n.execute
end

class CsvToHtml
  def initialize(csv_file)
    @rows = CSV.read(csv_file, headers: true)
  end

  def convert
    File.open(HTML_FILE, 'w', encoding: 'UTF-8') do |file|
      file.puts html_template
      file.puts body_template

      # ヘッダー行 (列名) を <th> タグとして出力
      @rows.headers.each do |header|
        file.puts "            <th>#{header}</th>"
      end

      file.puts <<~HTML
          </tr>
        </thead>
        <tbody>
      HTML

      # CSV の本文 (2行目以降) を <td> タグとして出力
      @rows.each do |row|
        file.puts '          <tr>'
        row.fields.each do |field|
          file.puts "            <td>#{field}</td>"
        end
        file.puts '          </tr>'
      end

      # HTML 閉じタグ
      file.puts <<~HTML
            </tbody>
          </table>
        </body>
        </html>
      HTML
    end
  end

  private

  def html_template
    <<~HTML
      <!DOCTYPE html>
      <html lang="ja">
      <head>
        <meta charset="UTF-8" />
        <title>#{I18n.t('html_title')}</title>
        <style>
          table {
            border-collapse: collapse;
            width: 100%;
            margin: 1em 0;
          }
          th, td {
            border: 1px solid #ccc;
            padding: 0.5em;
          }
          th {
            background: #f2f2f2;
          }
        </style>
      </head>
    HTML
  end

  def body_template
    <<~BODY
      <br>
      <body>
        <h1>#{I18n.t('html_title')}</h1>
        <table>
          <thead>
            <tr>
    BODY
  end
end

csv_to_html = CsvToHtml.new(CSV_FILE)
csv_to_html.convert
puts I18n.t('convert_success', html_file: HTML_FILE)
