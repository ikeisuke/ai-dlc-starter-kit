# Unit 005 計画: aidlc-v3 起動有効化（marketplace.json 登録 + 統合検証）

## 対象 Unit

- **Unit**: 005-aidlc-v3-activation（aidlc-v3 起動有効化 / marketplace.json 登録 + 統合検証）
- **サイクル**: v3.0.0-alpha.3（Phase 3）
- **依存 Unit**: 001-v3-define-flow（完了）/ 003-v3-develop-tiny-flow（完了）/ 004-state-validate-schema-compat（完了）
- **関連 Issue**: なし
- **depth_level**: standard（設計フェーズあり）/ **review_mode**: required

## 目的（1 文）

`.claude-plugin/marketplace.json` の plugins に `./skills/aidlc-v3` を追加して `/aidlc-v3` 起動を有効化し、`define` / `develop` フローが起動・ドッグフーディング可能であることを構造的に検証し、SKILL.md skeleton の「起動有効化は後続 Phase」という注記を実態（有効化済み）に合わせて更新する。本流化（v3→v2 置換）・marketplace version の v3.0.0 化は Phase 7 へ defer する。

## 設計方針（前提認識）

- **登録は最小 1 行**: marketplace.json の `plugins[0].skills` 配列に `"./skills/aidlc-v3"` を追加する（既存エントリの末尾に 1 要素追加）。他キー（version / 既存 skills / source / strict）は変更しない。
- **v3/v2 共存**: v3 の `state.json`（`.aidlc/state.json`）は v2 の `.aidlc/config.toml` / `cycles/` と location が異なり共存可能。登録は `/aidlc-v3`（v3）と `/aidlc`（v2）の両起動表面を併存させる（クリーンカット = v2 runtime / ファイル非影響）。
- **検証は構造検証**: `/aidlc-v3` の実起動（対話セッション）はテスト不能なため、(a) marketplace.json が有効な JSON で `./skills/aidlc-v3` を含む、(b) `skills/aidlc-v3/SKILL.md` が存在し define/develop へのルーティング記述を持つ、(c) define/develop の手順ファイル（`steps/define.md` / `steps/develop.md`）と参照スクリプトが存在する、を構造的に確認する。
- **skeleton 注記の実態同期**: SKILL.md の「`/aidlc-v3` 起動の有効化（marketplace.json 登録）は Unit 005 で行う」「marketplace.json への登録も Phase 3 以降へ defer」等の起動有効化注記を「有効化済み（alpha.3 / Unit 005）」へ更新する。あわせて同じ位置づけブロック内に残る stale な Unit 文脈注記（`steps/define.md` / `steps/status.md` / `steps/develop.md` を「本 Unit で作成」とする旧表現）も「実装済み（該当 Unit 参照）」へ実態同期する。一方でコマンド名（define/develop 等）の正本性記述、および release/reflect/doctor の**予約**状態の記述は据え置く（本 Unit 対象外）。
- **version は触らない**: marketplace.json `metadata.version`（現 `3.0.0-alpha.2`）の更新は本 Unit のスコープ外（version 化は Phase 7 / alpha バージョン更新は release/Operations の責務）。

## 主要な実装対象

1. **`.claude-plugin/marketplace.json`（改修 / 1 行追加）**: `plugins[0].skills` に `"./skills/aidlc-v3"` を追加。JSON 妥当性を保持。
2. **`skills/aidlc-v3/SKILL.md`（改修 / 注記更新）**: 「起動有効化は Unit 005 / Phase 3 以降へ defer」系の skeleton 注記を「有効化済み（alpha.3 Unit 005）」へ実態同期。あわせて同ブロック内の stale な「`steps/define.md` / `steps/status.md` / `steps/develop.md` を本 Unit で作成」旧表現を「実装済み（該当 Unit 参照）」へ更新。コマンド予約状態（release/reflect/doctor）の記述は据え置き（本 Unit 対象外）。
3. **検証**（テストハーネス or 構造チェック）: marketplace.json の JSON 妥当性 + `./skills/aidlc-v3` 含有 + 起動に必要なファイル（SKILL.md / steps/define.md / steps/develop.md / 参照スクリプト）の存在を確認。v2 非影響（`skills/aidlc/` 差分なし）を確認。

## 設計フェーズで確定すべき主要判断

| # | 論点 | 選択肢候補 | 備考 |
|---|------|-----------|------|
| D1 | marketplace.json への追加位置 | (a) `plugins[0].skills` 配列末尾に追加【推奨】/ (b) aidlc 直後など特定位置 | 配列順は起動に影響しないため末尾追加が最小差分。設計で確定 |
| D2 | 起動検証の手段 | (a) 専用の軽量チェック（jq で JSON 妥当性 + 含有確認 + 必須ファイル existence）をテストハーネス化【推奨】/ (b) 手動目視のみ | 決定的・再現可能な構造検証を優先。既存 test-*.sh 方式に倣うか、単発チェックにするかを設計で確定 |
| D3 | SKILL.md 注記の更新範囲 | (a) 起動有効化注記 + 同じ位置づけブロック内の stale な Unit 文脈注記（「本 Unit で作成」旧表現）のみ実態同期（予約コマンド記述・コマンド名正本性は据え置き）【推奨】/ (b) skeleton 全体を見直し | 責務「skeleton 注記を実態に合わせて更新」に限定。release/reflect/doctor の予約は Phase 維持 |
| D4 | version 更新 | (a) 触らない【推奨 / スコープ外】/ (b) alpha.3 へ更新 | 境界で version 化は Phase 7。alpha 更新も release/Operations 責務。本 Unit はスコープ外 |

## 完了条件チェックリスト

Unit 005「責務」から抽出:

- [x] `.claude-plugin/marketplace.json` の plugins に `./skills/aidlc-v3` が追加されている（JSON 妥当性を保持）
- [x] `/aidlc-v3 define` / `/aidlc-v3 develop` が起動可能であることを構造的に確認している（SKILL.md ルーティング + 手順ファイル + 参照スクリプトの存在）
- [x] v2 非影響を確認している（`skills/aidlc/` 配下に変更なし / v2 `.aidlc/` 成果物を破壊しない）
- [x] SKILL.md の skeleton 注記（「起動有効化は Phase 3 以降 / Unit 005」等の起動有効化注記 + 同ブロックの stale な「本 Unit で作成」旧表現）を実態（有効化済み / 実装済み）に合わせて更新している（予約コマンド記述は据え置き）
- [x] marketplace.json の version / 本流化（v3→v2 置換）に手を入れていない（Phase 7 スコープを侵さない）
- [x] `bash -n`（検証スクリプトがある場合）/ shellcheck（利用可能時）/ markdownlint を通過する

## 検証方針

- marketplace.json を jq で parse し JSON 妥当性 + `plugins[0].skills` に `./skills/aidlc-v3` 含有を確認。
- 起動に必要なファイル（`skills/aidlc-v3/SKILL.md` / `skills/aidlc-v3/steps/define.md` / `skills/aidlc-v3/steps/develop.md` / 参照スクリプト群）の存在を確認。
- `git diff --name-only` で v2（`skills/aidlc/`）配下に変更がないことを確認。
- `markdownlint`（SKILL.md 等）。

## スコープ境界（本 Unit に含まれないもの）

- v3 → v2 置換（本流化 = `skills/aidlc-v3 → skills/aidlc`）→ Phase 7
- marketplace version の v3.0.0 化 / alpha バージョン更新 → Phase 7 / release・Operations
- release / reflect / doctor の起動（未実装コマンドは予約のまま）
- v3 専用 rules 実体（`steps/rules.md` 等）の追加 → 後続 Phase

## リスク

- **R1**: marketplace.json の JSON 破損（カンマ抜け等）で全プラグイン読込が壊れる → jq による妥当性検証を必須とし、最小差分（1 要素追加）に留める。
- **R2**: v2 への影響（`/aidlc` 起動表面・runtime）→ skills/aidlc/ を一切変更せず、追加のみで共存。`git diff` で非影響を確認。
- **R3**: skeleton 注記の更新漏れ・過剰更新（予約コマンド記述まで変える）→ D3 で「起動有効化注記 + 同ブロックの stale な Unit 文脈注記のみ実態同期、予約コマンド記述・コマンド名正本性は据え置き」に限定。
- **R4**: version を誤って更新しスコープ（Phase 7）を侵す → D4 で version 非更新を明示。
