require 'yaml'
require 'csv'
require 'optparse'

require './setting_test_create_tool'
include SettingTestCreateTool

require './set_application_settings.rb'
include SetApplicationSettings

# ファイルパスを取得
paths = SettingTestCreateTool.get_paths
yml_path = paths[:yml_path]
csv_path = paths[:csv_path]

# オプションパラメータで指定された機能名・画面名・バージョンを取得
options = SettingTestCreateTool.set_options
function_name, display_name, version = options[:f], options[:d], options[:v]

# 試験対象のアプリケーションの名前を取得
APP_NAME = SetApplicationSettings.set_application_name

# 試験でデフォルトで試験を行うユーザータイプを取得
DEFAULT_TEST_USER = SetApplicationSettings.default_test_user

# テスト対象の機能名と日本語名のハッシュ
FUNCTION_NAME_HASH = SetApplicationSettings.set_function_name_hash

# テスト対象の機能名と左メニュー、顧客タブ、設置先タブの表示有無のハッシュ
FUNCTION_LEFT_MENU_HASH = SetApplicationSettings.set_function_left_menu_hash
FUNCTION_CUSTOMER_TAB_HASH = SetApplicationSettings.set_function_customer_tab_hash
FUNCTION_PLACE_TAB_HASH = SetApplicationSettings.set_function_place_tab_hash

# ユーザータイプと日本語名のハッシュ
USER_TYPE_ARRAY = SetApplicationSettings.set_user_type_array

class CreateTest
  # テスト仕様書を生成するメソッド
  def generate_test_spec(yml_path, csv_path, function_name, display_name, version)
    data = YAML.load_file(yml_path)

    is_left_menu =    left_menu?(FUNCTION_LEFT_MENU_HASH, function_name)
    is_customer_tab = customer_tab?(FUNCTION_CUSTOMER_TAB_HASH, function_name)
    is_place_tab =    place_tab?(FUNCTION_PLACE_TAB_HASH, function_name)

    return if !is_left_menu && !is_customer_tab && !is_place_tab

    CSV.open(csv_path, 'w', write_headers: true, headers: ['セクション', 'タイトル', '前提条件', '備考', '手順', '期待する結果', '対応バージョン']) do |csv|
      [is_left_menu, is_customer_tab, is_place_tab].each_with_index do |is_creatable, order|
        next unless is_creatable
        USER_TYPE_ARRAY.each do |user_type|
          csv << [
            '表示',
            user_type.values.first,
            generate_precondition(user_type, function_name, display_name, is_left_menu, is_customer_tab, is_place_tab, order),
            '',
            generate_step(function_name, display_name, data['permissions']["#{user_type.keys.first}"][function_name], is_left_menu, is_customer_tab, is_place_tab, order),
            generate_result(function_name, display_name, data['permissions']["#{user_type.keys.first}"][function_name], is_left_menu, is_customer_tab, is_place_tab, order),
            version
          ]
        end
        if display_name == '新規登録'
          csv << [
            display_name,
            '登録',
            "#{APP_NAME}に#{DEFAULT_TEST_USER}でログインしていること。#{FUNCTION_NAME_HASH[function_name]}の#{display_name}画面へ遷移していること。。備考の表をもとにデータを登録していること。",
            '',
            "1. 備考の表に沿ってデータを入力し、「登録」ボタンをクリックする。<br>2. 「キャンセル」ボタンをクリックする。",
            "1. 正常に登録され、#{FUNCTION_NAME_HASH[function_name]}閲覧画面へ遷移すること。このとき、入力した内容が表示されていること。<br>2. #{FUNCTION_NAME_HASH[function_name]}一覧画面へ遷移すること。このとき、登録したデータが一覧テーブルに表示されていること。",
            version
          ]
        elsif display_name == '複製'
          csv << [
            display_name,
            '登録',
            "#{APP_NAME}に#{DEFAULT_TEST_USER}でログインしていること。#{FUNCTION_NAME_HASH[function_name]}の#{display_name}画面へ遷移していること。。備考の表をもとにデータを登録していること。",
            '',
            "1. 備考の表に沿ってデータを入力し、「複製」ボタンをクリックする。<br>2. 「キャンセル」ボタンをクリックする。",
            "1. 正常に登録され、#{FUNCTION_NAME_HASH[function_name]}閲覧画面へ遷移すること。このとき、入力した内容が表示されていること。<br>2. #{FUNCTION_NAME_HASH[function_name]}一覧画面へ遷移すること。このとき、複製元のデータと複製したデータが一覧テーブルに表示されていること。",
            version
          ]
        elsif display_name == '編集'
          csv << [
            display_name,
            '更新',
            "#{APP_NAME}に#{DEFAULT_TEST_USER}でログインしていること。#{FUNCTION_NAME_HASH[function_name]}の#{display_name}画面へ遷移していること。。備考の表をもとにデータを登録していること。",
            '',
            "1. 備考の表に沿ってデータを入力し、「更新」ボタンをクリックする。<br>2. 「キャンセル」ボタンをクリックする。",
            "1. 正常に登録され、#{FUNCTION_NAME_HASH[function_name]}閲覧画面へ遷移すること。このとき、入力した内容が表示されていること。<br>2. #{FUNCTION_NAME_HASH[function_name]}一覧画面へ遷移すること。このとき、更新したデータが一覧テーブルに表示されていること。",
            version
          ]
          generate_destroy(csv, function_name, version)
        end
      end
    end
  end

  private

  def left_menu?(hash, function_name)
    hash[function_name]
  end

  def customer_tab?(hash, function_name)
    hash[function_name]
  end

  def place_tab?(hash, function_name)
    hash[function_name]
  end

  # テスト仕様書の前提条件を生成するメソッド（表示の場合）
  def generate_precondition(user_type, function_name, display_name, is_left_menu, is_customer_tab, is_place_tab, order)
    if order == 0 && is_left_menu
      precondition_display_name = precondition_display(display_name)
      case display_name
      when '一覧'
        "#{APP_NAME}に#{user_type.values.first}でログインしていること。#{FUNCTION_NAME_HASH[function_name]}の#{precondition_display_name}に遷移していること。"
      when '新規登録' , '閲覧', '編集'
        "#{APP_NAME}に#{user_type.values.first}でログインしていること。#{FUNCTION_NAME_HASH[function_name]}の#{precondition_display_name}に遷移していること。備考の表をもとにデータを登録していること。"
      end
    elsif order == 1 && is_customer_tab
      case display_name
      when '一覧'
        "#{APP_NAME}に#{user_type.values.first}でログインしていること。顧客閲覧画面に遷移していること。"
      when '新規登録' , '閲覧', '編集'
        "#{APP_NAME}に#{user_type.values.first}でログインしていること。顧客閲覧画面に遷移していること。備考の表をもとにデータを登録していること。"
      end
    elsif order == 2 && is_place_tab
      case display_name
      when '一覧'
        "#{APP_NAME}に#{user_type.values.first}でログインしていること。設置先閲覧画面に遷移していること。"
      when '新規登録' , '閲覧', '編集'
        "#{APP_NAME}に#{user_type.values.first}でログインしていること。設置先閲覧画面に遷移していること。備考の表をもとにデータを登録していること。"
      end
    end
  end

  # テスト仕様書の前提条件で予めどこへ遷移しているべきかを返すメソッド
  def precondition_display(display_name)
    case display_name
    when '一覧'
      'ダッシュボード'
    when '新規登録', '複製', '閲覧'
      '一覧画面'
    when '編集'
      '閲覧'
    end
  end

  # テスト仕様書の手順を生成するメソッド
  def generate_step(function_name, display_name, permissions, is_left_menu, is_customer_tab, is_place_tab, order)
    if order == 0 && is_left_menu
      case display_name
      when '一覧'
        "1. 左メニューの「#{FUNCTION_NAME_HASH[function_name]}」をクリックする。"
      when '新規登録', '複製', '編集'
        "1. 「#{display_name}」ボタンをクリックする。"
      when '閲覧'
        '1. 予め登録しておいたデータの行をクリックする。'
      end
    elsif order == 1 && is_customer_tab || order == 2 && is_place_tab
      case display_name
      when '一覧'
        "1. 「#{FUNCTION_NAME_HASH[function_name]}」タブをクリックする。"
      when '新規登録', '複製', '編集'
        "1. 「#{display_name}」ボタンをクリックする。"
      when '閲覧'
        '1. 予め登録しておいたデータの行をクリックする。'
      end    
    end
  end

  # テスト仕様書の期待する結果を生成するメソッド
  def generate_result(function_name, display_name, permissions, is_left_menu, is_customer_tab, is_place_tab, order)
    readable = permissions.include?('read') || permissions.include?('limit_read') ? true : false
    writable = permissions.include?('write') || permissions.include?('limit_write') ? true : false

    case display_name
    when '一覧'
      return "1. 左メニューに#{FUNCTION_NAME_HASH[function_name]}が存在していないこと。" unless readable
    when '新規登録', '複製', '編集'
      return "1. 「新規登録」ボタンが存在していないこと。" unless writable
    end
    "1. #{FUNCTION_NAME_HASH[function_name]}#{display_name}画面へ遷移すること。"
  end

  # 編集画面での削除の試験を生成するメソッド
  def generate_destroy(csv, function_name, version)
    csv << [
      '削除',
      '削除確認モーダル表示',
      "#{APP_NAME}nに#{DEFAULT_TEST_USER}でログインしていること。#{FUNCTION_NAME_HASH[function_name]}の編集画面へ遷移していること。",
      '',
      "1. 「削除」ボタンをクリックする。",
      "1. 削除確認モーダルが表示されること。",
      version
    ]
    csv << [
      '削除',
      '削除キャンセル',
      "#{APP_NAME}nに#{DEFAULT_TEST_USER}でログインしていること。#{FUNCTION_NAME_HASH[function_name]}の編集画面へ遷移していること。",
      '',
      "1. 「削除」ボタンをクリックする。<br>2. 「キャンセル」ボタンをクリックする。<br>3. 「キャンセル」ボタンを2回クリックする。",
      "1. 削除確認モーダルが表示されること。<br>2. 削除確認モーダルが閉じること。<br>3. #{FUNCTION_NAME_HASH[function_name]}一覧画面へ遷移すること。このとき、削除対象のデータが存在していること。",
      version
    ]
    csv << [
      '削除',
      '削除',
      "#{APP_NAME}nに#{DEFAULT_TEST_USER}でログインしていること。#{FUNCTION_NAME_HASH[function_name]}の編集画面へ遷移していること。",
      '',
      "1. 「削除」ボタンをクリックする。<br>2. 「削除」ボタンをクリックする。",
      "1. 削除確認モーダルが表示されること。<br>2. 削除が実行され、#{FUNCTION_NAME_HASH[function_name]}一覧画面へ遷移すること。このとき、削除対象のデータが存在していないこと。",
      version
    ]
  end
end

CreateTest.new.generate_test_spec(yml_path, csv_path, function_name, display_name, version)
