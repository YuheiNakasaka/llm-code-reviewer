# LLM Code Reviewer

- 事前定義されたカスタムのコードレビューガイドラインを基にLLMを使ってコードレビューを行う試み。
- コードレビューの実行には`jq`と`curl`が必要です。

## 目的
- コードレビュアーの負荷軽減

## やっていること
- 対象のPRの内容を取得する
- コードレビューガイドラインを基にコーディングエージェントにコードレビューを行ってもらう
- コーディングエージェントのレビュー結果を出力する

## 手順
### 1. リポジトリのクローン

```sh
git clone git@github.com:YuheiNakasaka/llm-code-reviewer.git
cd llm-code-reviewer
```

### 2. PR内容の取得

#### 事前準備
- rubyが実行できる環境(Ruby 3.3.1で動作確認済み)
- ghコマンドが実行できる環境

#### 実行
```sh
# 例: ruby init_pr_content.rb https://github.com/owner/repo/pull/123
ruby init_pr_content.rb <PR URL>
```

### 3. コードレビューの実行

#### 事前準備
下記のプロンプトのうち以下は書き換える必要がある。

- リポジトリの場所
  - レビュー対象のリポジトリがローカルに存在する場合の方が精度が高いのでcloneされてあることを推奨。

#### 実行
このプロンプトをClineやCursor Agentで実行する。

```markdown
# 要求
- あなたはこれからコードレビューを行う必要があります。
- `general_code_review_guide.md`と`rails_specific_code_review_guide.md`にコードレビューガイドラインがあります。このドキュメントを基にしてコードレビューを行ってください。

# 対象のリポジトリ
- `/Users/example/dev/hoge_repo`

# PRの内容
- `pr_content.md`に対象のPRの内容が記載されています。

# コードレビュー時に絶対に守るべき事
- コードレビューを行う際には`general_code_review_guide.md`と`rails_specific_code_review_guide.md`に記載されているコードレビューガイドラインに常に従ってください。
- コードレビューを行う際には`reviewer_personality.md`に記載されている人格に徹底的になりきって振る舞わなければなりません。
- 良い点や適切であるコードに対してはレビューコメントを残してはいけません。
- 修正すべき点や気になる点がある箇所をなんとしてでも見つけ出して必ずレビューコメントを残さなければなりません。
- コードレビューは対象のリポジトリ全体を考慮して行わないといけません。

# レビュー結果の出力
- PRのレビュー結果はmarkdown形式でまとめて`review_results/`に`<repository_name>_<PRのID>.md`をファイル名にして出力してください。
```

`review_results/`にレビュー結果が出力されます。

#### 注意
- ClineやCursor Agentでファイルを読み込む際にコーディングエージェント側で一度に読み込みできるファイル行数を制限している場合があるので、その場合は制限を外してください。
- PRが大きい場合はコンテキストウィンドウが大きい`gemini-2.5-pro-preview-03-25`を使うとレビュー結果の精度が高くなります。
  - **そもそも大きいPRを作るのは避けるべき**
