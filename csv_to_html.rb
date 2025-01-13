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

      @rows.headers.each do |header|
        file.puts "            <th>#{header}</th>"
      end

      file.puts <<~HTML
          </tr>
        </thead>
        <tbody>
      HTML

      @rows.each do |row|
        file.puts '          <tr>'
        row.fields.each do |field|
          file.puts "            <td>#{field}</td>"
        end
        file.puts '          </tr>'
      end

      file.puts <<~HTML
              </tbody>
            </table>
          </div>
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
            margin: 1em 0;
            min-width: 800px;
          }
          th, td {
            border: 1px solid #ccc;
            padding: 0.5em;
          }
          th {
            background: #f2f2f2;
          }
          .table-container {
            overflow-x: auto;
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
        <div class="table-container">
          <table>
            <thead>
              <tr>
    BODY
  end
end

csv_to_html = CsvToHtml.new(CSV_FILE)
csv_to_html.convert
puts I18n.t('convert_success', html_file: HTML_FILE)
