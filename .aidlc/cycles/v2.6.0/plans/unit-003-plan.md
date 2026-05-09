# Unit 003 計画: marketplace.json への version SoT 一本化

## Unit 概要

`.claude-plugin/marketplace.json` の `metadata.version` をバージョン参照の唯一の SoT に確定し、ルート / `skills/aidlc/` / `skills/aidlc-setup/` の `version.txt` 3 ファイルを廃止する。`bin/update-version.sh` を `marketplace.json` 主体に再構築し、参照側コード（SKILL.md / 01-setup.md / env-info.sh / lib/version.sh）と CI（auto-tag）を全て書き換える。pre-release / CI ガードを追加。

- 関連 Issue: #617
- 見積もり: 3〜5 時間

## 依存関係

### 依存する Unit

なし（本 Unit は本サイクルの基盤 Unit）

### 被依存 Unit（下流）

- **Unit 004: aidlc-setup の no-op スキップ**: 本 Unit の SoT 一本化完了が前提（`config.toml.starter_kit_version` の役割が「ローカルキャッシュ値」として明確化された後に no-op 判定が意味を持つ）

### 受け渡し契約（Unit 003 → Unit 004）

Unit 003 完了時点で以下の状態を Unit 004 開始の前提として保証する:

| 項目 | Unit 003 完了状態 | Unit 004 から見た保証 |
|------|------------------|----------------------|
| version SoT | `marketplace.json.metadata.version` が単一の正本 | `config.toml.starter_kit_version` は「ローカルキャッシュ値」として確定 |
| 参照経路 | 4 経路（SKILL.md / 01-setup.md / env-info.sh / lib/version.sh）すべて切替済み | `aidlc-setup` の差分判定は新参照経路を前提に書ける |
| 互換状態 | `version.txt` 系 3 ファイル削除済み、CI ガード稼働 | Unit 004 で旧パス参照を考慮する必要なし |
| 文書化 | `config.toml.starter_kit_version` の役割明文化済み | Unit 004 で「ローカルキャッシュ値の no-op 判定」を実装する論拠が確立 |

## Phase 1 意思決定ゲート（完了条件の前提）

Construction 着手前に Phase 1（設計）で以下 6 件の論点を確定すること。確定なしに Phase 2 へ進まない（実装開始ゲート）。各論点の選択肢・採用案・採用理由・影響範囲は本計画末尾の「設計考慮事項」に記載しており、Phase 1 終了時に `[Answer]` を埋め確定する。

| ゲート ID | 論点 | 採用案（確定要） | 影響範囲 |
|----------|------|---------------|---------|
| GATE-1 | SoT バックフィル値 | `2.6.0`（Unit 定義準拠）／代替: `2.5.6`（現行 version.txt 値） | `marketplace.json.metadata.version` |
| GATE-2 | aidlc-migrate fallback 経路の扱い | (C) Unit 003 で fallback 参照ファイルパスのみ `marketplace.json` に切替（migrate の主ロジック=journal ベース判定は不変、Unit 境界違反なし） | `migrate-apply-config.sh` / `migrate-verify.sh` |
| GATE-3 | リモート version 取得の依存ツール | dasel 優先 / jq フォールバック / grep+sed 最終フォールバック | `env-info.sh` / `01-setup.md` ステップ5a |
| GATE-4 | `read_starter_kit_version()` の API 互換 | 公開 API は単一に確定。新規関数 `read_marketplace_version()` を導入、旧関数は本 Unit 内ですべての内部呼び出しを置換し本サイクル内で削除（互換期間 = 本 Unit 内のみ） | `lib/version.sh` 全呼び出し元 |
| GATE-5 | CI ガード実装方式 | (A) `bin/check-marketplace-version.sh` 新規作成 + `pr-check.yml` 新規ジョブ追加 | CI workflow / bin/ |
| GATE-6 | 削除順序・コミット粒度 | 論理段階を分けて作業し、Construction 完了時の squash で 1 コミット集約 | git log |

> **注**: 上記の採用案は計画起案時のデフォルト。Phase 1 設計レビューで再確認・確定する。

## 完了条件チェックリスト

### Phase 1 ゲート由来（実装開始前提）

- [ ] GATE-1〜GATE-6 すべての論点に `[Answer]` が記入され、採用理由が設計ドキュメントに残されている

### Unit 定義「責務」由来

- [ ] **SoT バックフィル**: `.claude-plugin/marketplace.json.metadata.version` が `2.0.4` から最新値に更新されている（バージョン値の決定方針は本計画 §設計考慮事項 で確定）
- [ ] **参照側コード移行（4 箇所）**:
  - [ ] `skills/aidlc/SKILL.md`「バージョン表示」セクションが `marketplace.json` 参照に更新
  - [ ] `skills/aidlc/steps/inception/01-setup.md` ステップ5a の 3 経路（リモート / スキル / ローカル）が `marketplace.json` 参照に更新
  - [ ] `skills/aidlc/scripts/env-info.sh` の `get_starter_kit_version()` が `marketplace.json` 参照に更新
  - [ ] `skills/aidlc/scripts/lib/version.sh` の `read_starter_kit_version()` の API 互換を維持しつつ内部参照先を `marketplace.json` に切替（または別関数を追加し旧関数を deprecate）
- [ ] **`bin/update-version.sh` 再構築**: `marketplace.json.metadata.version` を更新主体とし、`version.txt` 系 3 ファイル更新ロジックを削除（または移行段階の中間対応）
- [ ] **冗長 `version.txt` 3 ファイル削除**: `version.txt` / `skills/aidlc/version.txt` / `skills/aidlc-setup/version.txt` を削除
- [ ] **`config.toml.starter_kit_version` 役割明文化**: README または `.aidlc/rules.md` に「アップグレード差分検出のためのローカルキャッシュ値」「正本判定は `marketplace.json` で行う」を追記
- [ ] **pre-release / CI ガード追加**: `marketplace.json` 未更新検出を CI / ローカルで実行できるチェックスクリプトを追加（`bin/` 新規 or 既存 workflow 拡張）
- [ ] **CI: auto-tag.yml の参照源切替**: `.github/workflows/auto-tag.yml` の `cat version.txt` を `marketplace.json.metadata.version` 抽出に置き換え（`version.txt` 削除に伴う必須対応）
- [ ] **PR check workflow の対応**: `.github/workflows/pr-check.yml` の `PATHS_REGEX` から `version\.txt` / `skills/(.+/)?version\.txt` を除去し、代わりに `\.claude-plugin/marketplace\.json` を加える

### ドキュメント／運用インターフェース整合（指摘 #3 対応）

- [ ] **`.aidlc/operations.md` リリース手順更新**: 「`version.txt` を新バージョンに更新」を `marketplace.json.metadata.version` 更新（`bin/update-version.sh` 経由）に書き換え
- [ ] **`.aidlc/operations.md` CI/CD要点更新**: 自動タグ付けの説明を「`marketplace.json` から読み取り」に書き換え
- [ ] **`README.md` バージョンバッジ**: `[Version]` バッジのリンク先を `version.txt` から `.claude-plugin/marketplace.json` に書き換え（バージョン値は `bin/update-version.sh` で同期更新される運用）
- [ ] **横断検索の漏れ確認**: `grep -rn "version\.txt"` で本 Unit スコープ内の参照が残っていないことを確認（cycle-artifacts / `docs/versions/v*` / aidlc-migrate journal の3カテゴリは対象外として明示）

### Issue #617 受け入れ基準由来

- [ ] SoT の一本化（version 参照系 = 確認 / 表示 / 比較 がすべて `marketplace.json` 参照）
- [ ] 更新フローの整備（リリース時に `marketplace.json` の version が確実に更新される機構）
- [ ] 冗長ファイルの整理方針決定（本 Unit では「廃止」を選択）
- [ ] バックフィル（直近として該当バージョンを `marketplace.json` に反映）

### 横断要件

- [ ] テスト: 参照経路（SKILL.md `version` アクション、env-info.sh、update-version.sh）の動作テストが追加・更新されている
- [ ] テスト: 既存 `test_read_starter_kit_version.sh` が新仕様に追従または廃止／置換されている
- [ ] テスト: `bin/tests/test_update_version_no_toml_write.sh` が新仕様に追従または置換されている
- [ ] codex によるコード AI レビュー実施
- [ ] codex review --base main による統合 AI レビュー実施

## 設計考慮事項（Phase 1 で確定する論点）

### 1. SoT バックフィル値

候補:

- 現行最新タグ近傍（v2.5.6）に揃える
- 本サイクル予定値（v2.6.0）にバンプする

**[Question]** どちらを採用するか。Unit 定義は「`2.0.4` → `2.6.0` に更新」と明記しているため `2.6.0` が候補。ただし `version.txt` も現状 `2.5.6` であり、Operations Phase でリリース時に bump する従来運用との整合確認が必要。
**[Answer]** （Phase 1 で確定）

### 2. `aidlc-migrate` との境界（GATE-2）

Unit 定義「境界」では「`aidlc-migrate` 側の version 参照ロジックは触らない」と明記されている。一方で `aidlc-migrate` の以下 2 箇所は `skills/aidlc/version.txt` を fallback 参照しており、本 Unit で当該ファイルを削除すると壊れる:

- `skills/aidlc-migrate/scripts/migrate-apply-config.sh:217-218`
- `skills/aidlc-migrate/scripts/migrate-verify.sh:188-189`

**境界の解釈定義**: 「version 参照ロジック」を以下 2 層に分離する:

- **主ロジック（境界内＝触らない）**: `aidlc-migrate` の主たる version 比較・migration 判定（journal ベースの hash / version 比較、`config.toml.starter_kit_version` の用途、migrate のエントリポイント挙動）
- **fallback 参照ファイルパス（境界外＝Unit 003 で対応）**: 主ロジックが「expected version」を取得するための fallback として参照する `skills/aidlc/version.txt` のファイルパス。本 Unit で削除する `version.txt` 系ファイルへの単なるバインドであり、migrate の判定ロジック自体には影響しない

**[Question]** 解決策の選択:

- (A) Unit 003 の境界を拡張し migrate の fallback 経路も `marketplace.json` に切替
- (B) migrate の fallback 経路は別 Unit（または本サイクル外バックログ）で対応し、本 Unit では `skills/aidlc/version.txt` を**削除しない**（残す → no-op）。代わりに `update-version.sh` の更新対象から外して deprecation 表記を追加
- (C) migrate の fallback 参照ファイルパスのみを本 Unit で `marketplace.json` に切替（主ロジックは不変）。上記「境界の解釈定義」によれば Unit 境界違反ではない

**[Answer]** **(C) を採用**（GATE-2 確定案）。理由: migrate の主ロジック（journal ベース判定）は不変であり、変更は fallback で参照されるファイルパスを `marketplace.json` 抽出に置き換えるのみ。これにより `version.txt` 削除との整合が取れ、責務定義 #4「冗長 version.txt 3 ファイル削除」を Unit 内で完結できる。Phase 1 設計レビューで本解釈に対する追加指摘がなければ確定。

### 3. リモート version 取得の URL

現状: `https://raw.githubusercontent.com/ikeisuke/ai-dlc-starter-kit/main/version.txt`

切替後: `https://raw.githubusercontent.com/ikeisuke/ai-dlc-starter-kit/main/.claude-plugin/marketplace.json`（取得後 `dasel -i json '.metadata.version'` または `jq -r '.metadata.version'` で抽出）

**[Question]** `dasel` / `jq` 双方フォールバックを実装するか、片方のみとするか。`scripts/env-info.sh` は dasel 必須前提で書かれているため、ローカル経路は dasel 優先・grep+sed フォールバック方針を踏襲する。リモート取得用には Inception ステップ実行時の依存最小化で `jq` 優先が妥当か。
**[Answer]** （Phase 1 で確定）

### 4. `read_starter_kit_version()` の API 互換（GATE-4）

**確定方針**: 公開 API は単一とし、二重経路を残さない。

- 新規関数 `read_marketplace_version(marketplace_json_path)` を `lib/version.sh` に追加（`marketplace.json` から `metadata.version` を抽出して返す）
- 旧関数 `read_starter_kit_version(config_path)` の意味（config.toml キャッシュ値の検証付き読取）は残るため、関数自体は維持。ただし「正本判定」として利用されている呼び出し元（`bin/update-version.sh` の妥当性検証）からは新関数に切替
- 互換期間: **本 Unit 内のみ**。本 Unit 完了時点で内部呼び出し元はすべて `read_marketplace_version` 経由に統一する。`read_starter_kit_version` はキャッシュ値検証用途として残るが、「正本」用途では使用しない（コメントで明示）
- 次サイクルでの追加 deprecation 判断は本 Unit のスコープ外（必要に応じバックログ起票）

**[Answer]** 上記方針で確定。Phase 1 設計レビューで反対指摘がなければ最終化。

### 5. CI ガード（pre-release）の実装方式

候補:

- (A) `bin/check-marketplace-version.sh` 新規作成 + `pr-check.yml` ジョブ追加
- (B) 既存の defaults-sync 系 / size 系チェックに統合
- (C) `bin/update-version.sh` 内に dry-run 自己整合チェックを追加し、CI から呼び出す

**[Answer]** （Phase 1 で確定。デフォルトは (A)）

### 6. 削除順序（DR 候補）

Unit 定義「技術的考慮事項」記載の 6 ステップを尊重するが、Construction では単一コミット内で完結させるか段階分割するかを設計時に決定する:

- 中間段階「後方互換並行参照」を入れず、一括切替＋削除＋ガード追加で 1 コミットに集約（推奨：本サイクル内で完結し、Issue #617 の解消もシンプル）
- vs. 段階分割（branch 内で複数コミットに分け squash で 1 つに）

**[Answer]** （Phase 1 で確定。デフォルトは「論理段階を分けつつ最終 squash で 1 コミット集約」）

## 実装スコープ

### 含む

1. `marketplace.json.metadata.version` バックフィル
2. 4 経路の参照側コード書き換え（SKILL.md / 01-setup.md / env-info.sh / lib/version.sh）
3. `bin/update-version.sh` の再構築
4. `version.txt` 系 3 ファイル削除
5. `config.toml.starter_kit_version` の役割明文化（README または `.aidlc/rules.md`）
6. pre-release / CI ガード追加
7. `auto-tag.yml` の version 取得経路切替
8. `pr-check.yml` の `PATHS_REGEX` 更新
9. テスト追加・更新（既存テスト含む）
10. `aidlc-migrate` の fallback 参照ファイルパス切替（GATE-2 (C) 採用、主ロジックは不変）
11. `.aidlc/operations.md` のリリース手順・CI/CD要点更新（指摘 #3 対応）
12. `README.md` のバージョンバッジリンク先更新

### 含まない

- `aidlc-setup` の no-op スキップ実装（Unit 004 の責務）
- `aidlc-migrate` の主たる version 比較ロジック（journal ベース）の変更
- `config.toml.starter_kit_version` の用途見直し以上の変更（キー削除等）

## レビュー戦略

- **設計レビュー**: codex で `reviewing-construction-design` スキルを使用（参照経路の網羅性、削除順序、後方互換戦略）
- **コードレビュー**: codex で `reviewing-construction-code` スキルを使用（シェル安全性・bash 置換・テスト網羅）
- **統合レビュー**: `codex review --base main` で全変更を統合視点でレビュー

## リスク・トレードオフ

| リスク | 軽減策 |
|------|------|
| `version.txt` 削除で `aidlc-migrate` fallback 破損 | §設計考慮事項 #2 で確定 |
| リモート `marketplace.json` 取得の依存ツール（dasel/jq）不在 | grep+sed フォールバックで対応 |
| `bin/update-version.sh` 互換破壊で外部スクリプト連携破損 | CLI 互換（`--version` / `--dry-run`）は維持 |
| auto-tag CI が `version.txt` 削除直後に壊れる | 同一 PR 内で `auto-tag.yml` も切替 |
| Construction 中の他作業との衝突 | Unit 003 は基盤 Unit（依存元 0 + Unit 004 のみが下流）。Unit 005 / 006 とはファイル衝突しないため並行作業可能 |
