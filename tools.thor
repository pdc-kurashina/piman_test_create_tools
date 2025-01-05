# frozen_string_literal: true

class Tool < Thor
  def self.exit_on_failure?
    true
  end

  desc 'test_create_tool', 'Create tool'
  option :function, aliases: '--f'
  option :display, aliases: '--d'
  option :version, aliases: '--v'
  option :with_html, aliases: '--w'
  def test_create_tool
    system("ruby test_create_tool.rb --f #{options[:function]} --d #{options[:display]} --v #{options[:version]}")

    return unless options[:with_html] == 'yes' || options[:with_html] == 'y' || options[:with_html] == 'true'

    system('ruby csv_to_html.rb')
  end

  desc 'csv_to_html', 'Convert CSV to HTML'
  def csv_to_html
    system('ruby csv_to_html.rb')
  end

  desc 'create_markdown_schema', 'Create markdown schema'
  def create_markdown_schema
    system('ruby create_markdown_schema.rb')
  end
end
