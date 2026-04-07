# poe-uniques

PoEDB の [Unique item](https://poedb.tw/us/Unique_item) 一覧をローカルに保存し、ユニークアイテムの効果本文を部分一致検索して CSV を出力する Ruby スクリプトです。

## Requirements

- rbenv
- Ruby 4.0.2
- `nokogiri` gem

このリポジトリは [/.ruby-version](/Users/clock/poe-uniques/.ruby-version) で Ruby `4.0.2` を指定しています。
この環境では Ruby `4.0.2` と Nokogiri `1.13.8` で動作確認しています。

## Files

- [bin/fetch_uniques.rb](/Users/clock/poe-uniques/bin/fetch_uniques.rb)
  - PoEDB からユニーク一覧を取得し、検索用データを生成します
- [bin/search_uniques.rb](/Users/clock/poe-uniques/bin/search_uniques.rb)
  - ローカルJSONを検索して CSV を標準出力に出します
- [data/uniques.json](/Users/clock/poe-uniques/data/uniques.json)
  - 生成される検索用データです

## Setup

`rbenv` で Ruby `4.0.2` をインストールしてから、このディレクトリで有効化してください。

```sh
rbenv install -s 4.0.2
rbenv local 4.0.2
```

次に `nokogiri` が入っていない場合はインストールしてください。

```sh
gem install nokogiri
```

## Usage

最初に PoEDB からデータを取得します。

```sh
ruby bin/fetch_uniques.rb
```

成功すると `data/uniques.json` が生成されます。

次に、効果本文を部分一致検索します。

```sh
ruby bin/search_uniques.rb "Power Charge"
```

CSV をファイルに保存する場合はリダイレクトします。

```sh
ruby bin/search_uniques.rb "Explode" > result.csv
```

## Output

検索結果の CSV 列は次の 3 つです。

- `name`
- `effect_text`
- `url`

マッチ対象は効果本文のみです。アイテム名やカテゴリは検索対象に含めていません。

## Data Format

`data/uniques.json` の各要素は次のキーを持ちます。

- `name`
- `base_type`
- `category`
- `url`
- `effects`
- `effect_text`
- `source_page`
- `fetched_at`

## Notes

- データ元は英語ページ `https://poedb.tw/us/Unique_item` 固定です
- 検索は大文字小文字を区別する単純な部分一致です
- PoEDB の HTML 構造が変わると取得スクリプトの修正が必要になる可能性があります

## Troubleshooting

`ruby bin/search_uniques.rb` 実行時にデータファイルがないと言われた場合は、先に次を実行してください。

```sh
ruby bin/fetch_uniques.rb
```

引数なしで検索すると usage を表示して終了します。

```sh
ruby bin/search_uniques.rb "search text"
```
