# 論理設計: review-flow追加圧縮

## 概要

ドメインモデルで定義したToolConstraint・SecurityRule・SharedProcedureの意味構造を、review-flow-reference.mdのMarkdownレイアウトにマッピングする。

**重要**: このドキュメントでは**コードは書かず**、アーキテクチャとインターフェースの定義のみを行います。

## 変更対象ファイル

| ファイル | 変更種別 |
|---------|---------|
| `steps/common/review-flow-reference.md` | 構造リファクタリング（主変更） |
| `steps/common/review-flow.md` | 参照リンク調整（必要に応じて） |

## review-flow-reference.md レイアウト設計

ドメインモデルの3概念（ToolConstraint群、SecurityRule群、SharedProcedure群）を以下のセクションにレンダリングする。

### セクション1: ヘッダ + 責務境界

- タイトル: 現行維持
- 責務境界: 短文1文（「事前予防の制約カタログ。事後フローはreview-flow.mdのエラー分類表を参照」）
- フォールバック列説明: 短文1文

### セクション2: セキュリティ注意事項（SecurityRule → 箇条書き）

SecurityRule 4項目を簡潔化して箇条書きにレンダリング:

| SecurityRule | 圧縮後 |
|-------------|--------|
| 機密情報除外 | インライン送信前にexclude_patterns適用必須 |
| エラーメッセージマスキング | エラー出力時に機密情報をマスク |
| 認証情報平文禁止 | 認証情報は平文でファイル/ログに出力禁止 |
| 公式配布元確認 | CLIは公式配布元からインストール、定期的にバージョン確認 |

### セクション3: sandbox_restriction（ToolConstraint → テーブル）

ConstraintCategory=sandbox_restriction のToolConstraintを1テーブルにレンダリング。

列: ツール, 適用条件, 症状, 対処法, フォールバック

| ツール | 適用条件 | 症状 | 対処法 | フォールバック |
|-------|---------|------|--------|-------------|
| Codex | read-only実行時 | 出力空/不完全 | インラインプロンプト | CLI出力解析不能 |
| Codex | worktree/symlink環境 | git repo未検出 | --skip-git-repo-check | CLI実行エラー |
| Gemini | --sandbox実行時 | ファイル読取制限 | インラインプロンプト | CLI出力解析不能 |

### セクション4: output_format（ToolConstraint → テーブル）

ConstraintCategory=output_format のToolConstraint（Claude固有1件）を独立テーブル。

列: 適用条件, 症状, 対処法, フォールバック

### セクション5: auth_lifecycle（ToolConstraint → テーブル）

ConstraintCategory=auth_lifecycle のToolConstraintを1テーブル。共通手順はSharedProcedureへの参照のみ記載。

列: ツール, 適用条件, 検知コマンド, 再認証コマンド

| ツール | 適用条件 | 検知コマンド | 再認証コマンド |
|-------|---------|------------|-------------|
| Codex | トークン期限超過 | codex auth status | codex auth login |
| Claude | APIキー無効化 | claude --version | APIキー再設定 |
| Gemini | GCloud認証期限切れ | 認証状態確認 | GCloud再認証 |

「共通フォールバック手順はセクション7を参照」とだけ記載。

### セクション6: interactive_mode（ToolConstraint → テーブル）

ConstraintCategory=interactive_mode のToolConstraint（Codex固有1件）を独立テーブル。

列: 適用条件, 症状, 対処法, フォールバック

「共通フリーズ対策はセクション7を参照」とだけ記載。

### セクション7: 共通手順（SharedProcedure → 箇条書き）

SharedProcedure群を独立セクションとしてレンダリング。ToolConstraintセクションから参照される。

- **auth_fallback**: 認証失効検出→再認証案内→リトライ1回→失敗時CLI実行エラーへ
- **freeze_countermeasure**: タイムアウト120秒→強制終了→CLI実行エラーへ

## review-flow.md への影響

「分割ファイル参照」セクションの説明文は現行のまま。参照先ファイル名・内容説明に変更なし。review-flow-reference.md内のセクション見出しが変わるが、review-flow.mdからのアンカーリンクは未使用のため影響なし。

## サイズ見積もり

| セクション | 現行概算 | 圧縮後概算 |
|-----------|---------|-----------|
| ヘッダ+責務境界 | ~800B | ~200B |
| セキュリティ注意事項 | ~1,200B | ~400B |
| ToolConstraintテーブル群 | ~4,200B | ~2,000B |
| SharedProcedure | ~1,200B | ~400B |
| review-flow-reference.md合計 | 7,438B | ~3,000B |
| review-flow.md | 10,769B | 10,769B（変更なし） |
| **合計** | **18,207B** | **~13,769B（24%削減）** |
