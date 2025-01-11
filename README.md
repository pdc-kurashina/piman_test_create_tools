# 前提

このツールは、基本的な試験仕様書の作成・簡単なDB試験仕様書の作成を目的としています。
高度な仕様書などを作成したい場合は、ソースコードを直接触って改良してください。

また、使用するにはご自身でファイルを新規作成する必要があります。
サンプル実行であれば、拡張子が`.example`となっているファイルをコピー&ペーストして実行しても問題ありません。

# 現在、作成可能な試験仕様書

* 一覧画面
  * 表示アクセス試験
* 新規登録画面
  * 表示アクセス試験
  * 登録、バリデーション（`not_null`）試験
* 閲覧画面
  * 表示アクセス試験
* 編集画面の表示アクセス試験
  * 表示アクセス試験
  * 更新、バリデーション（`not_null`）試験
  * 削除試験

# 今後実装予定の機能

* 一覧画面
  * 詳細検索試験
  * ソート試験
* 新規登録画面
  * `not_null`以外のバリデーション試験
* 編集画面
  * `not_null`以外のバリデーション試験

```txt
リクエストがあったら以下のXアカウントにDMください。

https://x.com/Tt5mJ
```

# 使用方法

## 試験仕様書作成スクリプト

自動で試験仕様書を作成するためのスクリプトです。

### 準備

1. `config/create_test_settings/`ディレクトリにで`settings.yml`を新規作成します。
2. 以下のような構成でymlファイルに権限情報を記述します。（`settings.yml.example`を参考にしてください。）

```yml
permissions:    # 固定
  admin:        # ユーザ種別
    customers: [read, write, delete]    # 機能名（単数系か複数形かは統一することをお勧めします。）
    users: [read, write]                # 権限は、配列で`read`/`write`/`delete`を例のように記述します。
    roles: [read]
    settings: []
```

1. `config/create_test_settings/`ディレクトリに`set_application_settings.rb`を新規作成します。
2. `set_application_settings.rb.example.rb.example`を参考に、「アプリケーションの名前」「機能名」などを設定します。
3. `config/create_test_settings`ディレクトリに`define_user.yml`を新規作成します。
4. `config/create_test_settings/define_user.yml.example`を参考に、「ユーザ種別」「ユーザ種別の呼び方」「デフォルトユーザか」を設定します。

```yml
admin:             # ユーザ種別
  call: "管理者"    # ユーザ種別の呼び方
  default: true    # デフォルトユーザなら`true`、そうでないなら`false`（`true`を設定できるのは1つのユーザ種別のみです）
```

5. `config/create_test_settings`ディレクトリに`form_items.yml`を新規作成します。
6. `config/create_test_settings/form_items.yml.example`を参考に、新規登録/編集画面の項目情報を設定します。

```yml
customers:             # テーブル名
  customer_name:       # フィールド名
    call: "顧客名"      # フィールドの呼び方
    input_type: "text" # フィールドの入力形式
    require: true      # 必須 or 場合による or 任意 （必須の場合は`true`、場合によるの場合は`case`、任意の場合は`false`）
    case: "XXXXXXXXXXXXの場合は、YYYYYYYYYYYY"   # XXXXXXXXXXXX: 条件、 YYYYYYYYYYYY: 必須 or 任意
    max: 100           # 最大文字数
```

7. `config/create_test_settings`ディレクトリに`function_mapping.yml`を新規作成します。
8. `config/create_test_settings/function_mapping.yml.example`を参考に、「指定する機能名」「識別される機能名」「試験仕様書のログインユーザ」を設定します。

```yml
inquiries:      # コマンド実行時に「--f」オプションで指定する機能名 
  admin/inquiries: "管理者ユーザ"            # 「--f」オプションで指定されたものがymlに存在する場合、`form_items.yml`のどの項目を読み込むのかを指定
  customer_portal/inquiries: "カスタマーポータルユーザ"
test_functions:
  test_functions: "検証用ユーザ"
```

9. `setting_test_create_tool.rb`を開いて、ファイルのパスが正しいか確認します。

### コマンド実行

1. 以下のコマンドを実行します。

```sh
thor tool:test_create_tool --f <機能名> --d <画面名> --v <バージョン> --w <yes or y or true>

# 例: thor tool:test_create_tool --f 'users' --d '一覧' --v 'v2.5.7' --w yes
# --w で yes/y/true のいずれかを指定すると、HTML形式でも試験仕様書が出力されます。
```

もしくは

```sh
ruby <スクリプトのあるパス>/test_create_tool.rb --f <機能名> --d <画面名> --v <バージョン>

# 例: ruby test_create_tool.rb --f 'users' --d '一覧' --v 'v2.5.7'
```

## 新規登録や編集フォームでのバリデーション試験の仕様書を作成する場合

バリデーションの試験仕様書を作成する場合は、項目や制約の情報を記述したymlファイルの作成が必要になります。

### 準備

1. `config/create_test_settings/form_items.yml`を作成します。
2. 以下のように項目情報を入力します。（詳細については、`config/create_test_settings/form_items.yml.example`を参照してください。）

```yml
customers:
  customer_name:
    call: "顧客名"
    input_type: "text"
    require: true
    max: 100
  note:
    call: "備考"
    input_type: "text"
    require: false
    max: 1000
```

3. 上記と同様にコマンドを実行すれば、設定された項目のバリデーションテストが作成されます。（ただし、一覧,閲覧を指定した時はバリデーションのテストは作成されません。）

## CSV to HTML

上記で作成した試験仕様書をHTML形式で出力するスクリプトを実行します。

### コマンド実行

```sh
thor tool:csv_to_html
```

## FROM DBスキーマ TO マークダウン

### 準備

1. `touch db_schema.rb`で`db_schema.rb`を新規作成します。
2. `db_schema.rb`にRailsの`db/schema.rb`の中身をコピー&ペーストします。

### コマンド実行

1. 以下のコマンドを実行します。

```sh
thor tool:create_markdown_schema
```

もしくは

```sh
ruby create_markdown_schema.rb
```

test