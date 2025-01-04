# 使用方法

## PIMAN試験仕様書作成スクリプト

### 準備

1. コードを開いて、`settings.yml`のパス、`output.csv`のパスを設定します。

### コマンド実行

1. 以下のコマンドを実行します。

```sh
thor tool:test_create_tool --f <機能名> --d <画面名> --v <バージョン>
```

もしくは

```sh
ruby <スクリプトのあるパス>/test_create_tool.rb --f <機能名> --d <画面名> --v <バージョン>
```

### 注意点

* PIMANに存在しない機能を指定した場合、十分な試験仕様書は作成されません。
* PIMANに存在しない画面名を設定した場合、試験仕様書は作成されません。
* PIMAN以外でスクリプトを使用したい場合、ソースコードの修正が必要となります。

## FROM DBスキーマ TO マークダウン

### 準備

1. `db_schema.rb`にRailsの`db/schema.rb`の中身をコピー&ペーストします。

### コマンド実行

1. 以下のコマンドを実行します。

```sh
thor tool:create_markdown_schema
```

もしくは

```sh
ruby create_markdown_schema.rb
```
