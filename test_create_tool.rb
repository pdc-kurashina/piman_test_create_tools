require 'yaml'
require 'csv'
require 'optparse'

# テスト対象の機能名と日本語名のハッシュ
FUNCTION_NAME_HASH = {
  'dashboards' => 'ダッシュボード',
  'customer_control_panels' => 'コンタクトコントロールパネル',
  'questions' => '質問',
  'manuals' => 'マニュアル',
  'customers' => '取引先',
  'places' => '設置先',
  'operation_groups' => '運用グループ',
  'signages' => 'サイネージ',
  'signage_devices' => 'サイネージデバイス',
  'channels' => 'チャンネル',
  'broadcast_methods' => '放映方法',
  'screen_structures' => '画面構成',
  'plots' => 'プロット図',
  'applications' => '申請',
  'systems' => 'システム',
  'place_files' => 'ファイル',
  'inquiries' => 'お問い合わせ',
  'incidents' => 'インシデント',
  'incident_status_logs' => 'インシデントコメント',
  'broadcast_requests' => '放映依頼',  
  'broadcast_request_status_logs' => '放映依頼コメント',
  'estimates' => '見積もり',
  'partners' => 'パートナー',
  'supports' => '体制',
  'agreements' => '契約',
  'agreement_periods' => '契約',
  'devices' => 'デバイス',
  'makers' => 'メーカー',
  'users' => 'ユーザー',
  'passwords' => 'パスワード',
  'notices' => 'お知らせ設定',  
  'alert_emails' => '警告メール送信先設定',
  'place_file_tabs' => '設置先ファイルタブ設定'
}

# テスト対象の機能名と左メニュー、顧客タブ、設置先タブの表示有無のハッシュ
FUNCTION_LEFT_MENU_HASH = {
  'dashboards' => true,
  'customer_control_panels' => false,
  'questions' => true,
  'manuals' => true,
  'customers' => true,
  'places' => true,
  'operation_groups' => false,
  'signages' => false,
  'signage_devices' => false,
  'channels' => false,
  'broadcast_methods' => false,
  'screen_structures' => false,
  'plots' => false,
  'applications' => false,
  'systems' => false,
  'place_files' => false,
  'inquiries' => true,
  'incidents' => true,
  'incident_status_logs' => false,
  'broadcast_requests' => true,  
  'broadcast_request_status_logs' => false,
  'estimates' => true,
  'partners' => true,
  'supports' => true,
  'agreements' => true,
  'agreement_periods' => true,
  'devices' => true,
  'makers' => true,
  'users' => true,
  'passwords' => false,
  'notices' => true,  
  'alert_emails' => true,
  'place_file_tabs' => true
}

FUNCTION_CUSTOMER_TAB_HASH = {
  'dashboards' => false,
  'customer_control_panels' => false,
  'questions' => false,
  'manuals' => false,
  'customers' => false,
  'places' => true,
  'operation_groups' => false,
  'signages' => false,
  'signage_devices' => false,
  'channels' => false,
  'broadcast_methods' => false,
  'screen_structures' => false,
  'plots' => false,
  'applications' => false,
  'systems' => false,
  'place_files' => false,
  'inquiries' => false,
  'incidents' => false,
  'incident_status_logs' => false,
  'broadcast_requests' => false,  
  'broadcast_request_status_logs' => false,
  'estimates' => false,
  'partners' => false,
  'supports' => false,
  'agreements' => false,
  'agreement_periods' => false,
  'devices' => false,
  'makers' => false,
  'users' => false,
  'passwords' => false,
  'notices' => false,  
  'alert_emails' => false,
  'place_file_tabs' => false
}

FUNCTION_PLACE_TAB_HASH = {
  'dashboards' => false,
  'customer_control_panels' => false,
  'questions' => false,
  'manuals' => false,
  'customers' => false,
  'places' => false,
  'operation_groups' => true,
  'signages' => true,
  'signage_devices' => true,
  'channels' => true,
  'broadcast_methods' => true,
  'screen_structures' => true,
  'plots' => true,
  'applications' => true,
  'systems' => true,
  'place_files' => true,
  'inquiries' => false,
  'incidents' => false,
  'incident_status_logs' => false,
  'broadcast_requests' => false,  
  'broadcast_request_status_logs' => false,
  'estimates' => false,
  'partners' => false,
  'supports' => true,
  'agreements' => true,
  'agreement_periods' => true,
  'devices' => false,
  'makers' => false,
  'users' => false,
  'passwords' => false,
  'notices' => false,  
  'alert_emails' => false,
  'place_file_tabs' => false
}

# ユーザータイプと日本語名のハッシュ
USER_TYPE_ARRAY = [
  { admin: '管理者' },
  { maintenance: '保守ユーザ' },
  { sales: '営業ユーザ' },
  { se: 'SEユーザ' },
  { media: 'メディアユーザ' },
  { read_only: '一般ユーザ' },
  { call_center: 'コールセンターユーザ' },
  { partner: 'パートナーユーザ' },
  { pdc_call_center: 'PDCコールセンターユーザ' },
  { customer: 'カスタマーポータルユーザ' },
  { operator: '配信（オペレータ）ユーザ' },
  { broadcast_admin: '配信（管理者）ユーザ' }
]

options = {}
OptionParser.new do |opts|
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
end.parse!

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
          "PIMANに保守ユーザでログインしていること。#{FUNCTION_NAME_HASH[function_name]}の#{display_name}画面へ遷移していること。。備考の表をもとにデータを登録していること。",
          '',
          "1. 備考の表に沿ってデータを入力し、「登録」ボタンをクリックする。<br>2. 「キャンセル」ボタンをクリックする。",
          "1. 正常に登録され、#{FUNCTION_NAME_HASH[function_name]}閲覧画面へ遷移すること。このとき、入力した内容が表示されていること。<br>2. #{FUNCTION_NAME_HASH[function_name]}一覧画面へ遷移すること。このとき、登録したデータが一覧テーブルに表示されていること。",
          version
        ]
      elsif display_name == '複製'
        csv << [
          display_name,
          '登録',
          "PIMANに保守ユーザでログインしていること。#{FUNCTION_NAME_HASH[function_name]}の#{display_name}画面へ遷移していること。。備考の表をもとにデータを登録していること。",
          '',
          "1. 備考の表に沿ってデータを入力し、「複製」ボタンをクリックする。<br>2. 「キャンセル」ボタンをクリックする。",
          "1. 正常に登録され、#{FUNCTION_NAME_HASH[function_name]}閲覧画面へ遷移すること。このとき、入力した内容が表示されていること。<br>2. #{FUNCTION_NAME_HASH[function_name]}一覧画面へ遷移すること。このとき、複製元のデータと複製したデータが一覧テーブルに表示されていること。",
          version
        ]
      elsif display_name == '編集'
        csv << [
          display_name,
          '更新',
          "PIMANに保守ユーザでログインしていること。#{FUNCTION_NAME_HASH[function_name]}の#{display_name}画面へ遷移していること。。備考の表をもとにデータを登録していること。",
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
      "PIMANに#{user_type.values.first}でログインしていること。#{FUNCTION_NAME_HASH[function_name]}の#{precondition_display_name}に遷移していること。"
    when '新規登録' , '閲覧', '編集'
      "PIMANに#{user_type.values.first}でログインしていること。#{FUNCTION_NAME_HASH[function_name]}の#{precondition_display_name}に遷移していること。備考の表をもとにデータを登録していること。"
    end
  elsif order == 1 && is_customer_tab
    case display_name
    when '一覧'
      "PIMANに#{user_type.values.first}でログインしていること。顧客閲覧画面に遷移していること。"
    when '新規登録' , '閲覧', '編集'
      "PIMANに#{user_type.values.first}でログインしていること。顧客閲覧画面に遷移していること。備考の表をもとにデータを登録していること。"
    end
  elsif order == 2 && is_place_tab
    case display_name
    when '一覧'
      "PIMANに#{user_type.values.first}でログインしていること。設置先閲覧画面に遷移していること。"
    when '新規登録' , '閲覧', '編集'
      "PIMANに#{user_type.values.first}でログインしていること。設置先閲覧画面に遷移していること。備考の表をもとにデータを登録していること。"
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
    "PIMANnに保守ユーザでログインしていること。#{FUNCTION_NAME_HASH[function_name]}の編集画面へ遷移していること。",
    '',
    "1. 「削除」ボタンをクリックする。",
    "1. 削除確認モーダルが表示されること。",
    version
  ]
  csv << [
    '削除',
    '削除キャンセル',
    "PIMANnに保守ユーザでログインしていること。#{FUNCTION_NAME_HASH[function_name]}の編集画面へ遷移していること。",
    '',
    "1. 「削除」ボタンをクリックする。<br>2. 「キャンセル」ボタンをクリックする。<br>3. 「キャンセル」ボタンを2回クリックする。",
    "1. 削除確認モーダルが表示されること。<br>2. 削除確認モーダルが閉じること。<br>3. #{FUNCTION_NAME_HASH[function_name]}一覧画面へ遷移すること。このとき、削除対象のデータが存在していること。",
    version
  ]
  csv << [
    '削除',
    '削除',
    "PIMANnに保守ユーザでログインしていること。#{FUNCTION_NAME_HASH[function_name]}の編集画面へ遷移していること。",
    '',
    "1. 「削除」ボタンをクリックする。<br>2. 「削除」ボタンをクリックする。",
    "1. 削除確認モーダルが表示されること。<br>2. 削除が実行され、#{FUNCTION_NAME_HASH[function_name]}一覧画面へ遷移すること。このとき、削除対象のデータが存在していないこと。",
    version
  ]
end

# ファイルパスを指定してください
directory_path = '/Users/kurashinak/code/test_create_tools/'
yml_path = "#{directory_path}settings.yml"
csv_path = "#{directory_path}output.csv"

# テスト対象となる機能名（FUNCTION_NAME_HASHと同じ記載方法）
function_name = options[:f]

if function_name.nil?
  puts '機能名を指定してください。'
  exit
end

# テスト対象となる画面名（一覧、詳細、新規作成、複製、編集）
display_name = options[:d]

if display_name.nil?
  puts '画面名を指定してください。'
  exit
end

# 対応バージョン
version = options[:v]

if version.nil?
  puts 'バージョンを指定してください。'
  exit
end

generate_test_spec(yml_path, csv_path, function_name, display_name, version)
