# 論理設計: スコープ外バックログ自動登録

## 概要
指摘対応判断フローにステップ5aを挿入し、OUT_OF_SCOPE判断時のバックログ自動登録を実現する。成果物はMarkdownプロンプトの変更であり、ソフトウェアコードではない。

**重要**: この論理設計では**コードは書かず**、コンポーネント構成とインターフェース定義のみを行います。

## アーキテクチャパターン
指摘対応判断フロー内のサブステップ挿入パターン。既存のステップ番号を変更せず、ステップ5の直後にサブステップ5aを追加する。

## コンポーネント構成

### 変更対象ファイル構成

```text
prompts/package/prompts/common/review-flow.md
└── 「指摘対応判断フロー」セクション
    ├── ステップ5: 先送り判断の履歴記録（既存・変更なし）
    ├── [追加] ステップ5a: OUT_OF_SCOPEバックログ自動登録
    │   ├── mode判定
    │   ├── gh CLI可用性判定（issue/issue-only時のみ）
    │   ├── 登録実行（IssueまたはFile）
    │   ├── フォールバック処理
    │   └── 履歴記録（write-history.sh）
    └── ステップ6: 全指摘サマリ記録（既存・変更なし）
```

## 処理フロー

### ステップ5a: OUT_OF_SCOPEバックログ自動登録

ステップ5（先送り判断の履歴記録）の後、OUT_OF_SCOPEと判断された指摘がある場合に実行する。

#### 追加するテキスト

ステップ5の後（L382付近）に以下を挿入:

```markdown
   5a. **OUT_OF_SCOPEバックログ自動登録**（OUT_OF_SCOPE判断があった場合のみ）:

       ステップ2でOUT_OF_SCOPEと判断された指摘について、バックログ登録を実行する。

       **mode判定**:
       1. `docs/aidlc.toml` の `[rules.backlog].mode` を読み取る
       2. 読み取り失敗（ファイル未存在・構文エラー・値未設定）の場合は `git` として扱う

       **バックログ種別の決定**:

       レビュー種別から種別ラベルを決定する:
       - security → `type:security`
       - その他（code / architecture / inception） → `type:chore`

       **登録方法の決定と実行**:

       - `mode = git` または `mode = git-only` の場合:

         `docs/cycles/backlog/{type}-{slug}.md` にファイルを作成する。
         `{type}` は上記種別（chore / security）、`{slug}` は指摘内容から生成した短い識別子（英数字・ハイフン）。

         ファイル内容は `docs/aidlc/templates/backlog_item_template.md` に準拠:

         ```markdown
         # [指摘内容の要約]

         - **発見日**: {YYYY-MM-DD}
         - **発見フェーズ**: {Construction / Inception}
         - **発見サイクル**: {現在のサイクル}
         - **優先度**: 中

         ## 概要

         AIレビュー指摘（{レビュー種別}）でスコープ外と判断された項目。

         ## 詳細

         {指摘内容}

         ## 対応案

         次サイクル以降で対応を検討。
         先送り理由: {ユーザーが入力した理由}
         ```

         ファイル作成に失敗した場合（ディレクトリ不在、権限不足等）:
         警告メッセージを表示し、手動対応を依頼する（issue-onlyの場合と同様の警告形式）。

       - `mode = issue` または `mode = issue-only` の場合:

         **gh CLI可用性の確認**:
         1. `gh` コマンドの存在確認
         2. `gh auth status` による認証状態確認

         - **可用な場合**: Issue作成を実行

           **タイトルのサニタイズ**: `{指摘内容の要約}` はAIエージェントが生成する文字列であるため、シェル展開文字（`$`, `` ` ``, `"`, `\`）を含めないこと。改行は除去し、80文字以内に切り詰める。

           ラベルは種別決定の結果に基づき、1つの文字列に解決してから渡す:
           - securityレビュー指摘の場合: `"backlog,type:security,priority:medium"`
           - その他のレビュー指摘の場合: `"backlog,type:chore,priority:medium"`

           ```bash
           gh issue create \
               --title "[Backlog] {サニタイズ済みの指摘内容の要約}" \
               --label "backlog,type:{決定済みの種別},priority:medium" \
               --body "$(cat <<'BODY_EOF'
           ## スラッグ

           {slug}

           ## 概要

           AIレビュー指摘（{レビュー種別}）でスコープ外と判断された項目。

           ## 詳細

           {指摘内容}

           ## 検出元

           - **発見サイクル**: {現在のサイクル}
           - **発見フェーズ**: {Construction / Inception}
           - **先送り理由**: {ユーザーが入力した理由}

           ## 対応案

           次サイクル以降で対応を検討。
           BODY_EOF
           )"
           ```

           Issue作成に失敗した場合:
           - `mode = issue`: ファイルベース（上記git方式）にフォールバック
           - `mode = issue-only`: 警告メッセージを表示し、手動対応を依頼

         - **不可用な場合**:
           - `mode = issue`: ファイルベース（上記git方式）にフォールバック
           - `mode = issue-only`: 以下の警告を表示し、手動対応を依頼

             ```text
             【警告】GitHub CLIが利用できないため、バックログIssueを自動作成できません。
             issue-only モードのため、ファイルベースのフォールバックも使用できません。
             以下の指摘を手動でバックログに登録してください:
             - 指摘内容: {指摘内容}
             - 先送り理由: {理由}
             ```

       **バックログ登録完了の履歴記録**:

       constructionフェーズの場合:

       ```bash
       docs/aidlc/bin/write-history.sh \
           --cycle {{CYCLE}} \
           --phase construction \
           --unit {N} \
           --unit-name "[Unit名]" \
           --unit-slug "[unit-slug]" \
           --step "バックログ自動登録" \
           --content "$(cat <<'CONTENT_EOF'
       【バックログ自動登録】OUT_OF_SCOPE指摘のバックログ登録
       【指摘内容】{指摘内容の要約}
       【登録方法】{Issue / File / スキップ（手動対応依頼）}
       【登録先】{Issue番号 / ファイルパス / -}
       CONTENT_EOF
       )"
       ```

       inceptionフェーズの場合（`--unit*` 引数を省略）:

       ```bash
       docs/aidlc/bin/write-history.sh \
           --cycle {{CYCLE}} \
           --phase inception \
           --step "バックログ自動登録" \
           --content "$(cat <<'CONTENT_EOF'
       【バックログ自動登録】OUT_OF_SCOPE指摘のバックログ登録
       【指摘内容】{指摘内容の要約}
       【登録方法】{Issue / File / スキップ（手動対応依頼）}
       【登録先】{Issue番号 / ファイルパス / -}
       CONTENT_EOF
       )"
       ```
```

## 非機能要件（NFR）への対応

### セキュリティ
- **要件**: write-history.sh呼び出し時にUnit 001で確立した安全なパターンを使用
- **対応策**: heredoc形式（`CONTENT_EOF`）を使用し、ユーザー入力値の直接展開を回避
- **Issue本文**: heredoc形式（`BODY_EOF`）でシェル展開を回避

## 実装上の注意事項
- ステップ5aは指摘対応判断フロー内のサブステップであり、トップレベルのステップ5.5（セルフレビューフロー）とは無関係
- OUT_OF_SCOPE指摘が複数ある場合、各指摘ごとに登録を実行する
- 優先度はデフォルト「中」（priority:medium）とし、ユーザーへの確認は行わない（登録後に変更可能）
- `{slug}` は指摘内容から英数字・ハイフンで構成される短い識別子を生成する（AIエージェントの判断に委ねる）
- ラベルが存在しない場合のエラーは、gh issue create失敗としてフォールバック処理に含まれる

## 不明点と質問（設計中に記録）

（なし - 要件は明確）
