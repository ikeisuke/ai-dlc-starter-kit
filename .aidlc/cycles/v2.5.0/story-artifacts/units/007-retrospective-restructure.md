# Unit: 04-completion §1-2 振り返りステップの構造化（B-3+B-4 セット対応）

## 概要

`steps/operations/04-completion.md` の §1「フィードバック収集」/ §2「分析と改善点洗い出し」を §1「振り返り（retrospective）」に統合し、§3 以降を繰り上げる。KPT テンプレ + 主因切り分け 3 分類 + 格納先 3 分岐ガイド + マージ前完結契約整合を組み込む。新規テンプレ `predecessor_retrospective.md` を追加し、既存 `retrospective_template.md` に KPT セクションを拡張する。`steps/inception/01-setup.md` 等で次サイクル Inception 開始時に前サイクル振り返りを読む手順を追加する。

## 含まれるユーザーストーリー

- ストーリー 8: 04-completion §1-2 を振り返りステップに統合（KPT + 3 分岐 + マージ前完結契約整合）

## 責務

- `04-completion.md` §1-2 を §1「振り返り」に統合（既存 §3.5 retrospective 作成は新 §1 の中に統合）
- §3 以降を繰り上げ（旧 §3 バックログ記録 → 新 §2、旧 §4 → 新 §3、…）
- KPT (Keep / Problem / Try) テンプレを §1 に組み込み
- 主因切り分け 3 分類（プロダクト固有 / AI-DLC Starter Kit 固有 / 両方）を §1 に必須化
- 格納先 3 分岐ガイドを §1 に組み込み:
  - (a) マージ前 → `cycles/{{CYCLE}}/operations/retrospective.md`
  - (b) マージ後 → 次サイクル `cycles/{{NEXT}}/inception/predecessor_retrospective.md`
  - (c) 横断改善 → `/aidlc feedback`
- §1 冒頭に §1.0「実施判定」を追加し、`feedback_mode` ベースの opt-out スイッチを明示（`disabled` で §1 全体スキップ / `silent` `mirror` で実施）
- §1 に write-history.sh ガード整合を明記
- `templates/retrospective_template.md` に KPT セクション + 主因切り分けマトリクスを追加（既存 YAML frontmatter スキーマは維持）
- `templates/predecessor_retrospective.md` 新規作成（分岐 b 用、KPT セクション + 引き継ぎ事項）
- `steps/operations/index.md` のフェーズインデックスから新 §1 を参照可能にする
- `steps/inception/01-setup.md` 等で次サイクル Inception 開始時に `predecessor_retrospective.md` を読む手順を追加（分岐 b 採用時）
- v2.5.0 自身の retrospective.md を新構造に更新（自己改善ループの本番テスト）

## 境界

- 既存 retrospective 自動生成スクリプト（`retrospective-generate.sh` / `retrospective-validate.sh` / `retrospective-mirror.sh`）の挙動変更は最小限（KPT セクションは markdown 拡張のみ、YAML frontmatter スキーマは Unit 004 のまま維持、新規 KPT セクションは機械判定対象外）
- 主因切り分けは markdown マトリクス記載で機械判定はしない（v2.6.x 以降の課題）
- 分岐 (b) `predecessor_retrospective.md` の自動読込は Inception Phase の手順追加のみで自動化はしない（v2.6.x 以降）

## 依存関係

### 依存する Unit

- Unit 004（前提: retrospective テンプレートと Operations 自動生成が既に実装されている）
- Unit 005（前提: mirror モード `/aidlc-feedback` 連動が既に実装されている = 分岐 c の実装基盤）

### 外部依存

- なし（既存 markdown / template 機構を流用）

## 非機能要件（NFR）

- **既存スクリプト互換**: `retrospective-validate.sh` の YAML frontmatter パース挙動が変わらない（Unit 004 の判定ロジックがそのまま動作する）
- **markdownlint パス**: 新テンプレ + 04-completion.md 修正後の差分が現状の markdownlint 設定で警告ゼロ
- **マージ前完結契約整合**: 各分岐の write-history.sh exit 3 ガードとの関係が明文化され、既存契約に抵触しない

## 技術的考慮事項

- 04-completion.md §3.5 「retrospective 作成」は新 §1 の中に統合する位置取り。スクリプト呼び出し（`retrospective-generate.sh` / `retrospective-validate.sh` / `retrospective-mirror.sh`）は保持
- §3 以降の繰り上げに伴うアンカー / 参照リンクの整合確認（他ドキュメントから §3-§7 を参照している箇所の更新）
- KPT セクションは既存 retrospective_template.md の「概要」と「問題項目」の間に挿入（既存 YAML frontmatter `skill_caused_judgment` セクションは Problem 項目内に維持）
- 主因切り分けは Problem / Try のマトリクス列として追加（自由記述）
- predecessor_retrospective.md は `{{CYCLE}}` / `{{PREV_CYCLE}}` プレースホルダー対応

## 関連 Issue

- #625（完全対応）
- #590（部分対応: B-3+B-4 は #590 で実装した自動振り返り機能を構造化拡張する位置付け）

## 実装優先度

Should-have

## 見積もり

1.5 セッション（04-completion.md §1-2 統合 + テンプレ拡張 + predecessor_retrospective.md 新規 + index.md / inception/01-setup.md 修正 + v2.5.0 retrospective.md 自己適用テスト）
