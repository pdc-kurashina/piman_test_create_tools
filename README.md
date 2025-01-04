# 前提

このツールは、基本的な試験仕様書の作成・簡単なDB試験仕様書の作成を目的としています。
高度な仕様書などを作成したい場合は、ソースコードを直接触って改良してください。

# 使用方法

## 試験仕様書作成スクリプト

### 準備

1. `touch settings.yml`で`settings.yml`を新規作成します。
2. 以下のような構成でymlファイルに権限情報を記述します。（`settings.yml.example`を参考にしてください。）

```yml
permissions:    # 固定
  admin:        # ユーザ種別
    customers: [read, write, delete]    # 機能名（単数系か複数形かは統一することをお勧めします。）
    users: [read, write]                # 権限は、配列で`read`/`write`/`delete`を例のように記述します。
    roles: [read]
    settings: []
```

3. `touch set_application_settings.rb`で`set_application_settings.rb`を新規作成します。
4. `set_application_settings.rb.example.rb.example`を参考に、「アプリケーションの名前」「デフォルトテストユーザ」「機能名」「ユーザ種別」などを設定します。
5. `setting_test_create_tool.rb`を開いて、ファイルのパスが正しいか確認します。

### コマンド実行

1. 以下のコマンドを実行します。

```sh
thor tool:test_create_tool --f <機能名> --d <画面名> --v <バージョン>

# 例: thor tool:test_create_tool --f 'users' --d '一覧' --v 'v2.5.7'
```

もしくは

```sh
ruby <スクリプトのあるパス>/test_create_tool.rb --f <機能名> --d <画面名> --v <バージョン>

# 例: ruby test_create_tool.rb --f 'users' --d '一覧' --v 'v2.5.7'
```

### 注意点

* PIMANに存在しない機能を指定した場合、十分な試験仕様書は作成されません。
* PIMANに存在しない画面名を設定した場合、試験仕様書は作成されません。
* PIMAN以外でスクリプトを使用したい場合、ソースコードの修正が必要となります。

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
