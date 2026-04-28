# Unit: retrospective テンプレートと Operations 自動生成

## 概要

`templates/retrospective_template.md` を新規作成し、`steps/operations/04-completion.md`（または相当する Operations 完了ステップ）に retrospective サブステップを追加する。テンプレートには「skill 起因判定（3 問自問）」セクションを含め、自動生成されたファイルが空にならないガード（最低 1 件 or 「問題なし」明示）を実装する。

## 含まれるユーザーストーリー

- ストーリー 4: retrospective テンプレートと Operations 自動生成
- ストーリー 5: skill 起因判定（3 問自問）

## 責務

- `templates/retrospective_template.md` 新規作成（概要 / 問題項目（タイトル / 何が起きたか / なぜ起きたか / 損失と影響 / skill 起因判定 YAML フロントマター）/ 次サイクル引き継ぎ）
- `steps/operations/04-completion.md`（または該当ファイル）に「retrospective 作成」サブステップ追加
- `feedback_mode ∈ {silent, mirror}` 時に自動実行、`feedback_mode = "disabled"` で完全スキップする条件分岐（Intent「feedback_mode 値の正式定義」の語彙と一致）
- v2.5.0 リリース後の Operations Phase からのみトリガー（既存サイクルへの遡及生成防止）
- skill 起因判定の YAML フロントマタースキーマ: `q1_answer / q1_quote / q2_answer / q2_quote / q3_answer / q3_quote`（user_stories.md ストーリー 5 の正規スキーマ）
- 不正値ガード: `q*_answer: yes` の対応 `q*_quote` が空文字 / 10 文字未満 / 禁止語（`該当` / `あり` / `該当箇所` / `あります` 単独）の場合、警告 + `skill_caused` を `false` にダウングレード

## 境界

- mirror モードの /aidlc-feedback 連動は Unit 005 で実施（本 Unit はローカル記録 + judgment フラグまで）
- 重複検出と上限ガードは Unit 006 で実施
- `[rules.retrospective] feedback_mode = "silent"` の defaults.toml 追加は本 Unit に含む

## 依存関係

### 依存する Unit

- Unit 001（前提: defaults.toml に `[rules.retrospective]` セクションを安全に追加できる土台が整っている）

### 外部依存

- なし（既存 markdown テンプレート機構を流用）

## 非機能要件（NFR）

- **空ファイル禁止**: 自動生成された retrospective.md は最低 1 件の問題項目または「問題なし」明示を含む
- **markdownlint パス**: テンプレート差分が現状の markdownlint 設定で警告ゼロ
- **トリガー精度**: v2.5.0 以前のサイクルディレクトリでは自動生成しない

## 技術的考慮事項

- テンプレートの問題項目は配列形式（`### 問題 N: ...`）で複数項目をサポートする構造
- 3 問自問は YAML フロントマター or Markdown チェックリスト形式で機械可読にする（Unit 005/006 がパース可能）
- v2.5.0 トリガー条件: サイクルディレクトリ名 / config の `[project] starter_kit_version` のいずれかでガード

## 関連Issue

- #590（部分対応: 実装スコープ 1, 2, 3, 4 を担当）

## 実装優先度

High

## 見積もり

1.0 セッション（テンプレート設計 + ステップ追加 + テスト）

---
## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
- **エクスプレス適格性**: -
- **適格性理由**: -
