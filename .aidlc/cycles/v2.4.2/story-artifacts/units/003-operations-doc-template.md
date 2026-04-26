# Unit: Operations 手順書 / template 明文化

## 概要

Operations Phase の手順書（`operations-release.md §7.2-§7.6` および `02-deploy.md §7`）と progress.md テンプレート（`operations_progress_template.md`）に、empirical-prompt-tuning で検出された 8 件の不明瞭点を解消する明文化を反映する（#591 + #585 統合 Unit）。

## 含まれるユーザーストーリー

- ストーリー3: Operations 手順書の固定スロット明文化（#591）
- ストーリー4: progress.md テンプレートへの固定スロット同梱（#591 [P2] / #585）

## 責務

### `skills/aidlc/steps/operations/operations-release.md`

- **§7.2-§7.6 [P1]**: 固定スロット 3 行（`release_gate_ready` / `completion_gate_ready` / `pr_number`）を `## 固定スロット（Operations 復帰判定用）` セクションへ追記する具体例コードブロックを inline で記載
- **§7.7 [P4]** へ追加: コミット対象ファイル列挙を `operations-release.md §7.7` セクション内に追加
  - `operations/progress.md`
  - `history/operations.md`
  - `README.md`
  - `CHANGELOG.md`（`rules.release.changelog=true` の場合のみ）
  - `version.txt` / `.aidlc/config.toml`（`bin/update-version.sh` で更新した場合のみ）
  - markdownlint で修正したその他ファイル
- **行区切り規約**: 改行区切り（Markdown リスト形式 `- key=value` ではなく独立行）の明示
- **§7.2 CHANGELOG 設定値確認**: `rules.release.changelog` の確認手順を追加
- **empirical-prompt-tuning 残課題 4 件の文章補強**: [P1]-[P4] 4 件のほか、retrospective で検出された 8 件中の残り 4 件（CHANGELOG 設定値確認手順 / 既存 progress.md セクション有無判定 / CHANGELOG 該当なし判定 / 設定依存判定）を上記 §7.2 / §7.7 / §7.5 等の文章補強で同時カバーする

### `skills/aidlc/steps/operations/02-deploy.md`

- **§7 状態ラベル列挙 [P3]**: 5 値（`未着手` / `進行中` / `完了` / `スキップ` / `PR準備完了`）を冒頭または注記に明示
- **§7.7 誘導注記**: 「詳細は **[必読] operations-release.md §7.7**」を `02-deploy.md §7.7` に残し、本体は operations-release 側に集約

### `skills/aidlc/templates/operations_progress_template.md`

- **固定スロット同梱 [P2] / [#585]**: `## 固定スロット（Operations 復帰判定用）` セクションを新設し、以下を記載:
  - `<!-- fixed-slot-grammar: v1 -->` コメント
  - `release_gate_ready=`
  - `completion_gate_ready=`
  - `pr_number=`
- **後方互換性**: 既存サイクルへの強制移行は行わない（テンプレートはサイクル初期化時のみ展開）

## 境界

- `phase-recovery-spec.md` 自体の改訂は本 Unit のスコープ外（grammar 仕様 v1 はそのまま準拠）
- 既存サイクル（v2.4.1 以前）の `operations/progress.md` の上書き / 移行は行わない
- 復帰判定ロジック（`session-continuity.md`、`PhaseResolver`）の改訂は本 Unit のスコープ外

## 依存関係

### 依存する Unit

- なし（Unit 001 / Unit 002 と完全独立、並列実装可能）

### 外部依存

- なし（Markdown ファイル更新のみ、外部ライブラリ依存なし）

## 非機能要件（NFR）

- **互換性**: 既存サイクルの `operations/progress.md` フォーマットに対する後方互換性を維持。固定スロットが存在しない既存形式を読み込んだ場合は既存形式継続でエラー扱いしない
- **可用性**: テンプレート展開時に既存サイクルの `operations/progress.md` を上書きしない（サイクル初期化時のみ展開）

## 技術的考慮事項

- **セクション名の統一**: 手順書とテンプレートの両方で `## 固定スロット（Operations 復帰判定用）` を使用（ストーリー3 / ストーリー4 の指摘修正で統一済み）
- **既存形式の判定ロジック**: 復帰判定 / `RecoveryJudgmentService.judge()` 側の new_format / legacy_format 自動切替（`DecisionCategoryClassifier`）は既に実装済み（v2.3.6 Unit 005）。本 Unit は手順書・テンプレートのドキュメント整備のみで、判定ロジックには触れない
- **CHANGELOG 設定値の確認手順**: `scripts/read-config.sh rules.release.changelog` を例示（既存スクリプト経由）
- **markdownlint 対応**: 手順書追加部分は markdownlint 違反を起こさないことを Operations Phase の §7.5 で確認

## 関連Issue

- #591（Closes 対象）
- #585（Closes 対象、#591 [P2] と統合実装するため #591 完了時に同時 close）

## 実装優先度

High

## 見積もり

小〜中規模（3 ファイル更新 + 文章改訂、技術的不確実性は低い）。Construction Phase で 1 Unit セッション内に収まる想定。Unit 001 / Unit 002 と並列実装可能。

---
## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
- **エクスプレス適格性**: -
- **適格性理由**: -
