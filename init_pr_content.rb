# frozen_string_literal: true

require 'json'
require 'open3'

# ghコマンドとjqコマンド、GitHubログインは事前に確認されている前提
pr_url = ARGV[0] || 'https://github.com/owner/repo/pull/123'
output_file = 'pr_content.md'
result_dir = 'review_results'

# PR情報諸々取得
jq_filter = '{title, author: .author.login, body, changedFiles, url}'
gh_view_cmd = "gh pr view \"#{pr_url}\" --json title,author,body,changedFiles,url --jq '#{jq_filter}'"
pr_base_data_json, _stderr_view, _status_view = Open3.capture3(gh_view_cmd)
pr_data = JSON.parse(pr_base_data_json)

# 差分取得(本当はdiffごとにMarkdownで構造化したいが、gh pr diff --patchではできないので一旦これで妥協)
gh_diff_cmd = "gh pr diff \"#{pr_url}\" --patch"
pr_diff, _stderr_diff, status_diff = Open3.capture3(gh_diff_cmd)

diff_content = if !status_diff.success? || pr_diff.empty?
                 '_バイナリファイルまたはdiffなし_'
               else
                 "```diff\n#{pr_diff.strip}\n```"
               end

# Markdown生成
markdown_content = <<~MARKDOWN
  # #{pr_data['title']}

  - 作成者: @#{pr_data['author']}
  - 変更ファイル数: #{pr_data['changedFiles']}
  - [PRリンク](#{pr_data['url']})

  ## PR本文

  #{pr_data['body'].nil? || pr_data['body'].empty? ? '(本文なし)' : pr_data['body'].strip}

  ## 変更内容 (Diff)

  #{diff_content}
MARKDOWN

# ファイル書き込み
File.write(output_file, markdown_content)

# reivew_resultsディレクトリの作成
Dir.mkdir(result_dir) unless Dir.exist?(result_dir)
