# レビューサマリ: Unit 001 - 個人好みキーの defaults.toml 集約

## 基本情報

- **サイクル**: v2.5.0
- **フェーズ**: Construction
- **対象**: Unit 001（個人好みキーの defaults.toml 集約）

<!-- 以下、AIレビュー完了時に Set が追記される -->

---

## Set 1: 2026-04-29 設計レビュー

- **レビュー種別**: 設計レビュー（reviewing-construction-design）
- **使用ツール**: codex（Codex Session: ce9cc7ec-55df-4e29-a654-cb27eb7f6722）
- **反復回数**: 2 ラウンド
- **結論**: 指摘0件（ラウンド 2 で全 3 件解消）

### 指摘一覧

| # | 重要度 | 内容 | 対応 | バックログ |
|---|--------|------|------|-----------|
| 1 | 中 | logical_design.md `defaults-resolution.bats` 検証方式 - B1 が「defaults 値と一致」のみで `defaults.toml` 改変時の検知力不足（既定値同等性 NFR の崩壊を見逃す可能性） | 修正済み（logical_design.md L131-145: B1 期待値テーブル追加 + ハードコード定数比較に変更 / コミット f1cf445a） | - |
| 2 | 中 | logical_design.md スコープ説明 - `config.toml.example` 編集が「附随的」とも「主要変更」とも読めて Unit 001/002 境界の解釈ぶれリスク | 修正済み（logical_design.md L7-22: 「Unit 001 のスコープ（明示）」表追加 — example も明示スコープ内 / コミット f1cf445a） | - |
| 3 | 低 | domain_model.md `ConfigKeyClassificationCatalog` がリポジトリインターフェース章下にあり「実装非対象だが Repository I/F 命名」で過剰抽象 | 修正済み（domain_model.md L138-152: 「リポジトリインターフェース」を空化し「参考概念（実装非対象）」セクションへ移動 / コミット f1cf445a） | - |

---

## Set 2: 2026-04-29 コードレビュー

- **レビュー種別**: コードレビュー（reviewing-construction-code）
- **使用ツール**: codex（Codex Session: ce9cc7ec-55df-4e29-a654-cb27eb7f6722）
- **反復回数**: 1 ラウンド
- **結論**: 指摘0件
- **対象**: `skills/aidlc-setup/templates/config.toml.template`（個人好み 7 キー除去）/ `skills/aidlc/config/config.toml.example`（同上）
- **事前ローカル検証**: dasel での 7 キー不在確認（template / example とも全 OK）/ `bin/check-defaults-sync.sh` `sync:ok` 確認済み
- **N/A 判定**: ログ・監視 / ネットワーク / セキュアデザイン（理由: 設定テンプレート差分のみで設計・通信・ログ系の影響なし）

### 指摘一覧

なし（指摘0件）

---

## Set 3: 2026-04-29 統合レビュー

- **レビュー種別**: 統合レビュー（reviewing-construction-integration）
- **使用ツール**: codex（Codex Session: ce9cc7ec-55df-4e29-a654-cb27eb7f6722）
- **反復回数**: 3 ラウンド
- **結論**: 指摘0件（ラウンド 1: 3 件 → ラウンド 2: 部分解消 1 件 → ラウンド 3: 完全解消）
- **対象**: 計画 / ドメインモデル / 論理設計 / 実装（template + example）/ bats テスト 2 + helpers + fixture 2 / migration-tests.yml の 11 ファイル
- **事前ローカル検証**: `bats tests/migration/ tests/config-defaults/` で 70/70 pass（migration 36 + config-defaults 34、回帰なし）

### 指摘一覧

| # | 重要度 | 内容 | 対応 | バックログ |
|---|--------|------|------|-----------|
| 1 | 中 | Unit 定義（story-artifacts/units/001-...md L13-15）の責務「defaults.toml に 7 キー追加」が実装方針「defaults.toml は編集なし（既存値）」と不一致 | 修正済み（Unit 定義の責務を「同等性確認・example 整理・bats 追加・CI 拡張」に最新化 / コミット 675048fb） | - |
| 2 | 中 | 計画 plan.md の観点 A 記述が「dasel ベース」のままで、実装の「template: grep/awk / example: aidlc_read_toml」2 経路への切替が反映されていない | 修正済み（plan.md 観点 A 本文・完了条件・テストファイル一覧 L59 をすべて 2 経路表記に統一 / コミット 675048fb と e7deadee） | - |
| 3 | 低 | migration-tests.yml の `tests/fixtures/.+` が過検知（無関係 fixture 変更でも CI ジョブが走る） | 修正済み（PATHS_REGEX を `tests/fixtures/v1-structure/.+\|tests/fixtures/config-defaults/.+` に絞り込み / コミット 675048fb） | - |

---
