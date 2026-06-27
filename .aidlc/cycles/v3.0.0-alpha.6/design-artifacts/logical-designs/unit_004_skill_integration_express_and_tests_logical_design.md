# 論理設計: Unit 004 SKILL.md 統合・express 整合・テスト・回帰

## 概要

`SKILL.md` の release 公開フリップと `test-release-flow.sh` 新規作成の構成・assertion を定義する。

**重要**: コードは書かず、変更箇所・テスト assertion の構造のみ定義する。

## アーキテクチャパターン

- **ドキュメント統合 + 自己完結テストハーネス**（既存 `test-activation.sh` と同系統）。SKILL.md は参照同期、テストは jq 前提・ネットワーク非依存の静的構造検証。
- **SoT 非再定義**: SKILL.md / テストは data-model §3/§5・workflow §6 を参照のみ。

## コンポーネント構成

### SKILL.md 変更箇所

```text
skills/aidlc-v3/SKILL.md
├── frontmatter description     ← 実態同期（release 実装済み / reflect・doctor 予約）
├── 位置づけ注記（冒頭 blockquote）← Phase 表記・各コマンドの実装状況を実態同期（stale 除去）
├── コマンド表 release 行        ← 「予約（後続 Phase で実装）」→「steps/release.md（実在 / Unit 001–003）」
├── express セクション           ← define→develop→release 到達の整合確認（矛盾なければ現状維持）
└── パス解決                     ← steps/ に release.md、templates/ に release.md を追加
```

### test-release-flow.sh 構成（新規）

```text
test-release-flow.sh（test-activation.sh 同型 / jq 前提 / pass-fail カウンタ）
├── 静的検査: bash -n / shellcheck（あれば）on self
├── 存在: steps/release.md, templates/release.md
├── release.md 見出し: Step 1, Step 2, Step 3, Step 4
├── release.md 依存契約: state-write.sh release.pr_number/ready/merge_approved, state-read.sh,
│                       work-item-validate.sh, work-item-status.sh
├── release.md merge ゲート: merge_blocker_any, --match-head-commit, gh pr checks --required
├── release.md review ルーティング（スモーク）: docs/v3/workflow.md 参照 + perspective 名(premerge/integration/deploy) + 主要ゲート語彙（条件文の完全一致はしない）
├── release.md post-merge（スモーク）: version_tag/changelog/tag/journal の主要語彙 + SoT 参照（条件再記述しない）
├── templates/release.md マーカー構造（perspective 単位）: start/end が各 1 回, マーカー間にコードフェンス/見出しなし,
│                       premerge/integration/deploy が各 1 回, 各ブロックに status/unresolved_count/max_severity/merge_blocker/skip_reason,
│                       merge_blocker_any が reviews 外に 1 回, enum/boolean(passed/skipped/true/false)
├── SKILL.md ルーティング: release 行が steps/release.md を指す・release 行に「予約」なし
└── SKILL.md stale 回帰: 残してはいけないパターン（v3.0.0-alpha.3 / Phase 3, tiny フローのみ, release の予約・後続 Phase）が無い
```

## インターフェース設計

### test-release-flow.sh の出力契約

- pass/fail カウンタを出力（`test-activation.sh` と同形式）。
- 終了コード: 0=全 pass / 1=fail あり / 2=前提不備（jq 未導入 等）。

### マーカー構造検証（jq 非依存 / parse しない / perspective 単位）

- マーカー抽出: `<!-- aidlc-release-review:start -->` 〜 `<!-- aidlc-release-review:end -->` を行範囲で抽出（awk / sed）。
- 検証（**perspective 単位** / 設計レビュー #2）:
  - start/end が各 1 回出現 / 範囲内に ` ``` `（コードフェンス）・`#`（Markdown 見出し）行がない。
  - `premerge` / `integration` / `deploy` が各 1 回出現する。
  - **各 perspective ブロック**に `status` / `unresolved_count` / `max_severity` / `merge_blocker` / `skip_reason` がある（グローバル grep でなくブロック単位。premerge だけに全キーがあり他で欠落、を見逃さない）。
  - `merge_blocker_any` が reviews リスト外（トップレベル）に 1 回。
  - enum・boolean 文字列（`passed`/`skipped` / `true`/`false`）が存在する。
- **parse はしない**（jq は YAML 非対応）。構造の確認に留める。

### SKILL.md stale 回帰検証（設計レビュー #1）

- Unit 004 後に残してはいけないパターンを明示列挙して grep し、残存を fail とする: `v3.0.0-alpha.3 / Phase 3`（旧 Phase）/ `tiny フローのみ`（develop stale）/ release 行の `予約` / release を「後続 Phase で実装」とする記述。`reflect`/`doctor` の `予約` は実態として残るため対象にしない。

### review ルーティング / post-merge のスモーク検証（設計レビュー #3）

- 条件文の完全一致（`done≥2` 等）を再記述せず、release.md が `docs/v3/workflow.md`/`docs/v3/data-model.md` への **SoT 参照** + perspective 名 + 主要ゲート語彙（version_tag / changelog / tag / journal / premerge / integration / deploy 等）を含むことを確認する。厳密な条件の正本は docs に閉じる（テストを第二の正本化しない）。

## スクリプトインターフェース設計

### test-release-flow.sh

- **概要**: release フローの構造・契約を静的検証する自己完結テスト。
- **引数**: なし。
- **依存**: jq（前提 / 未導入は exit 2 で SKIP）。実 gh / git / merge / ネットワークに依存しない。
- **result-out 関数**: 本テストは result-out 関数を持たない見込み（pass/fail カウンタのみ）。導入する場合は local 命名規約（`_local_<関数省略名>_<名>`）を遵守。
- **クロスプラットフォーム**: BSD/GNU 差のある grep/sed/awk オプションを避ける（`grep -F` / `grep -q` 等の移植性高い形）。

## データモデル概要

データモデルを変更しない。SKILL.md / テストは data-model §3/§5・workflow §6 を参照のみ。

## 処理フロー概要

### Unit 004 の作業フロー

1. SKILL.md の release フリップ + パス解決追記 + 注記同期（stale 除去 / develop 表記訂正）。
2. express セクションの release 到達整合を確認（必要なら修正）。
3. `test-release-flow.sh` を新規作成（上記 assertion）。
4. 全 `test-*.sh`（既存 7 + 新規 1 = 8）を実行し green を確認。
5. SoT 非再定義の確認（release.md/templates/SKILL.md が参照のみ）。
6. release Step 1→4 の通し整合（state 段階書き込み / Unit 002→003 review サマリ契約）を確認。

## 非機能要件（NFR）への対応

### 品質
- 新規テストが Step 1–4 の主要要素（ゲート・契約・マーカー・ルーティング・opt-in）をカバー。

### 互換性
- 既存テスト green 維持（回帰ゼロ）。SKILL.md 以外の Unit 001–003 成果物・state schema・既存スクリプトを変更しない。

### クロスプラットフォーム
- テストの grep/sed/awk は BSD/GNU 両対応の移植性ある形。

## 実装上の注意事項
- **境界**: 機能の新規実装をしない（Unit 001–003 成果物変更なし）。v2 非変更。dogfooding 非実行。reflect/doctor 非実装。
- **SoT 非再定義**: schema/perspective/フェーズ導出を再定義しない（参照同期のみ）。
- **stale 注記を残さない**: `test-activation.sh` のチェック対象 + 旧 Phase 表記を SKILL.md に残さない。
- **Bash ツール安全規約**: テストコード/手順内コマンドで AI Bash ツール引数に `$(...)` / backtick を使わない（スクリプト**ファイル内部**の `$(...)` は許容 / AI ツール引数のみ禁止）。

## 不明点と質問（設計中に記録）

[Question] マーカー間のコードフェンス/見出し検出はどう行うか。
[Answer] awk/sed でマーカー行範囲を抽出し、範囲内に ` ``` ` 始まり行・`#` 始まり行がないことを grep で確認（移植性ある形）。parse はしない。

[Question] test-release-flow.sh は実 gh/merge を実行するか。
[Answer] しない。release.md/templates/SKILL.md の構造・契約文字列の静的検証のみ（ネットワーク非依存 / jq 前提）。
