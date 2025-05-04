# LLM Code Reviewer

- 事前定義されたレビュアー観点を基にLLMを使ってコードレビューを行うためのプラクティスまとめ。
- コードレビューの実行には`jq`と`curl`が必要です。

## 目的
- コードレビュアーの負荷軽減

## 手順
### 1. リポジトリのクローン

```sh
git clone git@github.com:YuheiNakasaka/llm-code-reviewer.git
cd llm-code-reviewer
```

### 2. PR内容の取得

#### 事前準備
- git/jq/curl/mkdirの実行できる環境
- `PR_URL`が適切にセットされていること
- `GITHUB_TOKEN`が適切にセットされていること

#### 実行
```sh
PR_URL="https://github.com/owner/repo/pull/123" \
GITHUB_TOKEN="your_token" \
bash -c '
set -e
owner=$(echo $PR_URL | awk -F/ "{print \$4}")
repo=$(echo $PR_URL | awk -F/ "{print \$5}")
pr_number=$(echo $PR_URL | awk -F/ "{print \$7}")
mkdir -p ~/Desktop/code_review_tmp
pr_api="https://api.github.com/repos/$owner/$repo/pulls/$pr_number"
files_api="https://api.github.com/repos/$owner/$repo/pulls/$pr_number/files"
pr=$(curl -s -H "Authorization: token $GITHUB_TOKEN" $pr_api)
files=$(curl -s -H "Authorization: token $GITHUB_TOKEN" $files_api)
{
  echo "# $(echo "$pr" | jq -r .title)"
  echo
  echo "- 作成者: @$(echo "$pr" | jq -r .user.login)"
  echo "- 変更ファイル数: $(echo "$pr" | jq -r .changed_files)"
  echo "- [PRリンク]($PR_URL)"
  echo
  echo "## PR本文"
  echo
  body=$(echo "$pr" | jq -r .body)
  [ "$body" = "null" ] && echo "(本文なし)" || echo "$body"
  echo
  echo "## 変更ファイル一覧"
  echo
  echo "$files" | jq -c ".[]" | while read -r file; do
    filename=$(echo "$file" | jq -r .filename)
    patch=$(echo "$file" | jq -r .patch)
    echo "### \`$filename\`"
    echo
    if [ "$patch" != "null" ]; then
      echo "\`\`\`diff"
      echo "$patch"
      echo "\`\`\`"
    else
      echo "_バイナリファイルまたはdiffなし_"
    fi
    echo
  done
} > pr_content.md
'
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
- `/Users/example/dev/hoge_repo`にあります

# コードレビュー時の注意
- コードレビューを行う際には`reviewer_personality.md`に記載されている人格になりきってください振る舞わなければなりません。
- 良い点や適切であるコードに対してはレビューコメントを残してはいけません。
- 修正すべき点や気になる点がある箇所をなんとしてでも見つけ出して必ずレビューコメントを残さなければなりません。

# コードレビューの実行
- `pr_content.md`に対象のPRの内容が記載されています。

# レビュー結果の出力
- attempt_completionを使ってください。
- PRのレビュー結果はmarkdown形式でまとめてください。もし特にレビューに引っかかる点がなければLGTMと返してください。
```

#### 注意
- ClineやCursor Agentでファイルを読み込む際にコーディングエージェント側で一度に読み込みできるファイル行数を制限している場合があるので、その場合は制限を外してください。
- PRが大きい場合はコンテキストウィンドウが大きい`gemini-2.5-pro-preview-03-25`を使うとレビュー結果の精度が高くなります。
  - **そもそも大きいPRを作るのは避けるべきです**
