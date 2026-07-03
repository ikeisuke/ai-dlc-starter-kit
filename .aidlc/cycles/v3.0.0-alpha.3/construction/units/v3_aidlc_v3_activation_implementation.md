# 実装記録: Unit 005 aidlc-v3 起動有効化（marketplace.json 登録 + 統合検証）

## 基本情報

- **サイクル**: v3.0.0-alpha.3（Phase 3）
- **Unit**: 005-aidlc-v3-activation
- **関連 Issue**: なし
- **状態**: 完了
- **depth_level**: standard / **review_mode**: required / **automation_mode**: semi_auto

## 実装内容

### 1. `.claude-plugin/marketplace.json`（改修 / 1 要素追加）

- `plugins[0].skills` の末尾に `"./skills/aidlc-v3"` を追加（既存 15 → 16 エントリ）。`metadata.version`（3.0.0-alpha.2）・既存 skill・source・strict は不変。JSON 妥当性維持。これにより `/aidlc-v3` 起動が有効化される。

### 2. `skills/aidlc-v3/SKILL.md`（改修 / skeleton 注記の実態同期）

- 位置づけブロック: `steps/define.md`（Unit 001）/ `steps/status.md`（Unit 001）/ `steps/develop.md`（tiny / Unit 003）と Unit 参照を明示。「`/aidlc-v3` 起動は marketplace.json 登録済みで有効（Unit 005）」へ更新。
- 共存ブロック: `v3.0.0-alpha.2 / Phase 2` → `v3.0.0-alpha.3 / Phase 3`、「marketplace 登録済み / 起動表面は /aidlc-v3」へ更新。最終表面 `/aidlc` への切替（本流化）は Phase 7 と明記。
- コマンド表: define/status/develop の「本 Unit で作成」を該当 Unit 参照（001/001/003）へ修正。
- 据え置き: release/reflect/doctor の予約記述、コマンド名正本性（workflow.md/RFC DG-1）、marketplace version。

### 3. `skills/aidlc-v3/scripts/tests/test-activation.sh`（新規 / 構造検証ハーネス）

- 起動可能性を構造的に検証（jq 前提 / 自己完結 / bash 3.2 互換 / exit 0/1/2）:
  - marketplace.json の JSON 妥当性 / `./skills/aidlc-v3` 含有（起動有効化）/ `./skills/aidlc` 共存（v2 非後退）。
  - 起動必須ファイル存在: SKILL.md / steps（define/develop/status）/ 主要スクリプト 7 種（state-init/validate/write/read + work-item-validate/next/status）。
  - SKILL.md の stale 注記 3 種（「本 Unit で作成」/「Unit 005 で行う」/「v3.0.0-alpha.2 / Phase 2」）不在確認。

## テスト結果

- `test-activation.sh`: **PASS=19 FAIL=0**。
- 全 v3 テスト緑: define=75 / develop=44 / state=88 / work-item-next=27（非後退）。
- `bash -n` / `shellcheck`: 通過。
- `markdownlint-cli2`（SKILL.md / 設計 / 計画 / サマリ）: 0 error。
- **v2 非影響**: `skills/aidlc/` 配下に変更なし（`git status` / `git diff` で確認）。

## レビュー

- 計画レビュー（reviewing-construction-plan / codex / 3R）: R1 2件 + R2 1件 resolve / R3 clean。
- 設計レビュー（reviewing-construction-design / codex / 4R）: R1 2件 + R2 1件 + R3 1件 resolve / R4 clean。
- コードレビュー（reviewing-construction-code / focus code,security / codex / 1R）: 指摘0件（1R clean）。codex がテスト実行し PASS=19・全 v3 テスト緑・v2 非影響を確認。security は N/A（ネットワーク非使用 / 機密非取扱 / ローカル構造検証）。
- 統合レビュー: 本記録作成後に実施。

## 完了条件チェックリスト達成状況

- [x] marketplace.json の plugins に `./skills/aidlc-v3` が追加されている（JSON 妥当性維持）
- [x] `/aidlc-v3 define` / `/aidlc-v3 develop` が起動可能であることを構造的に確認（SKILL.md ルーティング + 手順ファイル + 参照スクリプト存在 / test-activation.sh）
- [x] v2 非影響を確認（`skills/aidlc/` 変更なし）
- [x] SKILL.md skeleton 注記（起動有効化注記 + stale な「本 Unit で作成」+ version/phase）を実態同期（予約コマンド据え置き）
- [x] marketplace.json の version / 本流化に手を入れていない（Phase 7 スコープ非侵犯）
- [x] bash -n / shellcheck / markdownlint 通過

## 備考

- 終了コード規約（0/1/2）準拠 / bash 3.2 互換（通常配列）。
- 本 Unit 完了で v3.0.0-alpha.3 の全 Unit（001〜005）完了。本流化（v3→v2 置換）・version 化は Phase 7。
