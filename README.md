# poe-uniques

PoEDB の [Unique item](https://poedb.tw/us/Unique_item) 一覧をローカルに保存し、ユニークアイテムの効果本文を部分一致検索して CSV を出力する Ruby スクリプトです。

## Requirements

- rbenv
- Ruby 4.0.2
- Bundler

このリポジトリは [/.ruby-version](/Users/clock/poe-uniques/.ruby-version) で Ruby `4.0.2` を指定しています。
この環境では Ruby `4.0.2` と Bundler `4.0.6` で動作確認しています。

## Files

- [bin/fetch_uniques.rb](/Users/clock/poe-uniques/bin/fetch_uniques.rb)
  - PoEDB からユニーク一覧を取得し、検索用データを生成します
- [bin/search_uniques.rb](/Users/clock/poe-uniques/bin/search_uniques.rb)
  - ローカルJSONを検索して CSV を標準出力に出します
- [data/uniques.json](/Users/clock/poe-uniques/data/uniques.json)
  - 生成される検索用データです
- [index.html](/Users/clock/poe-uniques/index.html)
  - `data/uniques.json` を読み込んでブラウザ上で検索する Web UI です
- [app.js](/Users/clock/poe-uniques/app.js)
  - Web UI の検索処理と結果表示を担当します

## Setup

`rbenv` で Ruby `4.0.2` をインストールしてから、このディレクトリで有効化してください。

```sh
rbenv install -s 4.0.2
rbenv local 4.0.2
```

次に Bundler で依存をインストールしてください。

```sh
bundle install
```

## Usage

最初に PoEDB からデータを取得します。

```sh
bundle exec ruby bin/fetch_uniques.rb
```

成功すると `data/uniques.json` が生成されます。
`item_type` を含む最新データに更新したい場合も、このコマンドを再実行してください。

次に、効果本文を部分一致検索します。

```sh
bundle exec ruby bin/search_uniques.rb "Power Charge"
```

複数引数を渡した場合は OR 検索になります。

```sh
bundle exec ruby bin/search_uniques.rb allies minion
```

CSV をファイルに保存する場合はリダイレクトします。

```sh
bundle exec ruby bin/search_uniques.rb "Explode" > result.csv
```

Web UI を使う場合はローカルHTTPサーバーを起動してからブラウザで開きます。

```sh
python3 -m http.server 8000
```

その後、ブラウザで `http://127.0.0.1:8000/index.html` を開いて検索します。
Web UI も CLI と同じく `effect_text` のみを対象に、大文字小文字を区別しない部分一致で検索します。
入力欄に空白区切りで複数語を入れた場合は OR 検索になります。

## Output

検索結果の CSV 列は次の 4 つです。

- `name`
- `item_type`
- `effect_text`
- `url`

マッチ対象は効果本文のみです。アイテム名やカテゴリは検索対象に含めていません。

## Data Format

`data/uniques.json` の各要素は次のキーを持ちます。

- `name`
- `base_type`
- `item_type`
- `category`
- `url`
- `effects`
- `effect_text`
- `source_page`
- `fetched_at`

## Notes

- データ元は英語ページ `https://poedb.tw/us/Unique_item` 固定です
- 検索は大文字小文字を区別しない単純な部分一致です
- 複数引数を渡した場合は OR 条件で検索します
- PoEDB の HTML 構造が変わると取得スクリプトの修正が必要になる可能性があります

## Troubleshooting

`bundle exec ruby bin/search_uniques.rb` 実行時にデータファイルがないと言われた場合は、先に次を実行してください。

```sh
bundle exec ruby bin/fetch_uniques.rb
```

引数なしで検索すると usage を表示して終了します。

```sh
bundle exec ruby bin/search_uniques.rb "search text"
```
