require 'optparse'

module SettingTestCreateTool
  def self.get_paths
    yml_path = "settings.yml"
    csv_path = "output.csv"

    { yml_path: yml_path, csv_path: csv_path }
  end

  def self.set_options
    options = {}
    opt_parser = OptionParser.new do |opts|
      opts.banner = "使い方: test_create_tool.rb [options]"
      opts.on("-fVAL", "--f=VAL", "テストを作成する機能名") do |f|
        options[:f] = f
      end

      opts.on("-dVAL", "--d=VAL", "テストを作成する画面名") do |d|
        options[:d] = d
      end

      opts.on("-vVAL", "--v=VAL", "テストを作成するバージョン") do |v|
        options[:v] = v
      end

      # ヘルプの表示
      opts.on_tail("-h", "--help", "ヘルプを表示") do
        puts opts
        exit
      end
    end

    begin
      opt_parser.parse!
    rescue OptionParser::InvalidOption => e
      puts e
      exit
    rescue OptionParser::MissingArgument => e
      if e.message.include?("--f")
        puts "機能名を指定してください"
      elsif e.message.include?("--d")
        puts "画面名を指定してください"
      elsif e.message.include?("--v")
        puts "バージョンを指定してください"
      end
      exit
    else
      options
    end
  end
end