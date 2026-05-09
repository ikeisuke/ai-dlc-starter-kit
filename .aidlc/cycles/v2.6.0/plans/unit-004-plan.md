# Unit 004 計画: aidlc-setup の starter_kit_version-only 差分 no-op スキップ

## Unit 概要

`aidlc-setup` のアップグレードフローで、適用差分が `.aidlc/config.toml.starter_kit_version` の値変化のみと判定された場合に書き込み（starter_kit_version 更新）をスキップし、`「.aidlc/config.toml の starter_kit_version 更新をスキップしました（差分なし）」` を表示する。

- 関連 Issue: #618
- 依存 Unit: 003（完了済 / `marketplace.json` SoT 一本化により `starter_kit_version` がローカルキャッシュ値として確定）
- 見積もり: 1〜2 時間

## 依存関係

- **依存元**: Unit 003 完了（受け渡し契約: `config.toml.starter_kit_version` は「ローカルキャッシュ値」として確定済、SoT は `marketplace.json` に集約済）
- **被依存**: なし（本サイクル v2.6.0 の他 Unit には影響しない）

## Phase 1 意思決定ゲート（完了条件の前提）

| ゲート | 論点 | 採用案 |
|------|------|--------|
| GATE-1 | 差分判定の対象範囲 | `.aidlc/config.toml` のみ（migrate-config.sh / detect-missing-keys.sh の影響範囲）。`setup-ai-tools.sh` (.claude/settings.json) と `migrate-backlog.sh` (.aidlc/cycles/) は判定対象外（Unit 定義「アップグレード本処理」+ Issue #618 の意図と一致） |
| GATE-2 | 差分判定の方式（指摘 #1, #2 反映） | **既存スクリプト出力ベースの集約判定**（一次情報）。`migrate-config.sh` の `result:` 行から `migrated=N` を、`detect-missing-keys.sh` の `summary\ttotal\tN` から欠落キー追加件数を、対話結果（追加実行有無）と組み合わせて `noop=true/false` を導出する。ステップ順序を変更して **7.4 → 7.4b → no-op 判定 → 7.3 を条件実行** とする（write-then-rollback は採用しない） |
| GATE-3 | スキップする「書き込み」の対象（指摘 #4 反映） | `.aidlc/config.toml` の `starter_kit_version` 値更新のみスキップ。`setup-ai-tools.sh` (8.4 / .claude/settings.json) は別責務として独立に動作（no-op メッセージは「config.toml の starter_kit_version 更新のみスキップ」と明示） |
| GATE-4 | 差分判定の実装位置 | aidlc-setup 配下に新規スクリプト `scripts/check-noop-upgrade.sh` を追加（aidlc プラグイン本体への依存を増やさない / aidlc-setup コンテキストで完結）。**入出力契約は構造化形式（`noop=true/false` + `reason=*`）に固定**（指摘 #3 反映） |
| GATE-5 | 異常系フォールバック | スクリプト出力解析失敗 / 引数不足 / 判定不能 → 警告表示 + 安全側フォールバック（通常通り starter_kit_version 更新を実行 = 既存挙動維持） |
| GATE-6 | 表示位置 | no-op 判定時はステップ 7.3 実行前に「`.aidlc/config.toml` の `starter_kit_version` 更新をスキップしました（差分なし）」を表示し、ステップ 7.3 をスキップ。アップグレード完了メッセージはそのまま表示。`setup-ai-tools.sh` (8.4) の動作には影響しない（独立責務） |

## 完了条件チェックリスト

### Phase 1 ゲート由来

- [ ] GATE-1〜GATE-6 すべての論点が確定し、設計ドキュメントに記録されている

### Unit 定義「責務」由来

- [ ] **差分判定ロジック追加**: `scripts/check-noop-upgrade.sh` を新規作成。引数 `--migrate-config-result <text>` `--detect-missing-applied <0|1>` を受け取り、構造化出力 `noop=true|false` と `reason=*` を返す（diff 依存ではなく既存スクリプト出力を一次情報とする）
- [ ] **検出時のスキップ**: ステップ順序を **7.4 → 7.4b → no-op 判定 → 7.3 条件実行** に変更（02-generate-config.md 改訂）
- [ ] **メッセージ表示**: no-op 時は「`.aidlc/config.toml` の `starter_kit_version` 更新をスキップしました（差分なし）」を stdout に表示
- [ ] **通常フローの保持**: 他フィールド差分があるアップグレードは従来通り動作（`should_update_starter_kit_version=true`）
- [ ] **異常系フォールバック**: スクリプト出力解析失敗 / 引数不足時は警告表示 + 通常更新を継続

### Issue #618 受け入れ基準由来

- [ ] no-op 判定: `migrate-config.sh` (migrated=0) + `detect-missing-keys.sh` 追加なし の場合に no-op と判定（一次情報源）
- [ ] no-op フィードバック: 「`.aidlc/config.toml` の `starter_kit_version` 更新をスキップしました（差分なし）」を表示
- [ ] starter_kit_version 更新スキップ: no-op 検出時は更新しない（write-then-rollback は使わない / 一切書かない）

### 横断要件

- [ ] テスト追加: `check-noop-upgrade.sh` の単体テスト（migrate-config=migrated=0 + missing 追加なし → noop=true / migrate-config=migrated=N → noop=false / missing 追加あり → noop=false / 引数不足 → exit 2）
- [ ] codex によるコード AI レビュー実施
- [ ] codex review --base main による統合 AI レビュー実施

## 実装スコープ

### 含む

1. `scripts/check-noop-upgrade.sh` 新規作成（既存スクリプト出力ベースの構造化判定）
2. `02-generate-config.md` のステップ順序変更（7.4 → 7.4b → no-op 判定 → 7.3 条件実行）+ スキップ時メッセージ
3. テスト追加（`scripts/tests/test_check_noop_upgrade.sh` 新規）
4. メッセージとログ出力（責務境界を明示）

### 含まない

- `setup-ai-tools.sh` の no-op 判定（.claude/settings.json は判定対象外）
- `migrate-backlog.sh` の no-op 判定（.aidlc/cycles/ は判定対象外）
- 4 スクリプトの dry-run 統合フレームワーク
- aidlc-migrate 側のロジック（v1→v2 マイグレーションは別系統）

## 設計考慮事項

### 1. ステップ順序の変更（指摘 #1 反映 / write-then-rollback 廃止）

現行の 02-generate-config.md は「7.3 (starter_kit_version 更新) → 7.4 (migrate-config) → 7.4b (detect-missing-keys)」の順。本 Unit でこれを「7.4 → 7.4b → no-op 判定 → 7.3（条件実行）」に変更する。

理由: write-then-rollback 方式は失敗点が増え、ロールバック失敗時に config.toml が中間状態で残るリスクがある。順序入れ替えにより「書かない」を一発で実現する。

### 2. no-op 判定の正本（指摘 #2 反映 / 一次情報源の単一化）

判定の正本は **既存スクリプトの機械可読出力**:

| 入力 | 由来 | no-op 条件 |
|------|------|----------|
| `migrate-config.sh` の `result:` 行 | 7.4 の stdout | `migrated=0` かつ `warnings=0` |
| `detect-missing-keys.sh` 後の追加実行有無 | 7.4b の対話結果（ユーザーが「追加する」を選び実際に追記したか） | 追加なし（欠落キー 0 件 or ユーザーがスキップ） |

両方が満たされる場合のみ `noop=true`。`diff` ベースの比較は廃止する。

### 3. check-noop-upgrade.sh の入出力契約（指摘 #3 反映 / 構造化出力）

```text
Usage: check-noop-upgrade.sh \
    --migrate-config-result <result-line>     # migrate-config.sh の "result:..." 行
    --detect-missing-applied <0|1>             # 0=追加なし(or skipped) / 1=追加あり

stdout（構造化出力）:
  noop=<true|false>
  reason=<no-changes|migrate-config-changed|missing-keys-applied|invalid-input>

exit:
  0=判定成功（noop=true/false いずれも 0）
  2=引数不足 / 入力解析失敗（呼び出し側はフォールバック扱い）
```

呼び出し側（02-generate-config.md）はこの構造化出力を読み、`noop=true` なら 7.3 をスキップ + 通知メッセージ表示、`noop=false` なら 7.3 を実行。exit 2 の場合は警告表示 + 通常フロー（安全側）。

### 4. 7.3 スキップ時のメッセージ（指摘 #4 反映 / 責務境界の明示）

```text
.aidlc/config.toml の starter_kit_version 更新をスキップしました（差分なし）
- migrate-config: 適用変更なし
- detect-missing-keys: 追加なし
- 注意: .claude/settings.json (8.4) は別責務として通常通り適用されます
```

`setup-ai-tools.sh` (8.4) は本判定の対象外であることを明示し、ユーザーが「すべての書き込みがスキップされた」と誤認しないようにする。

### 5. 異常系フォールバック

- スクリプト出力解析失敗 → exit 2 → 警告表示 + 通常フロー（既存挙動維持 = 安全側）
- 引数不足 → exit 2 → 同上
- 7.3 実行直前のフォールバック判定: `check-noop-upgrade.sh` が exit 2 を返した場合、`should_update_starter_kit_version=true` として通常通り 7.3 を実行する

## レビュー戦略

- **設計レビュー**: codex で `reviewing-construction-design`（差分判定アルゴリズム / 順序入れ替え判断 / ロールバック安全性）
- **コードレビュー**: codex で `reviewing-construction-code`（シェル安全性・テスト網羅）
- **統合レビュー**: `codex review --base main`

## リスク・トレードオフ

| リスク | 軽減策 |
|------|------|
| migrate-config / detect-missing-keys の出力フォーマット変更で判定が壊れる | 入力契約をスクリプトのインターフェース（`result:` / `summary` 行）に固定し、テストで明示的に検証。フォーマット変更時はテストが先に失敗 |
| 7.4b の対話結果（追加 yes/no）が呼び出し側で正しく集約されない | `02-generate-config.md` でユーザー応答を `detect_missing_applied=0|1` 変数に格納する手順を明記 |
| ステップ順序変更による既存フロー破壊 | 既存テストや statefulness の影響を Phase 1 設計で精査。7.3 は冪等な値更新のみのため順序変更の副作用は限定的 |
| ユーザーが `setup-ai-tools.sh` の動作を誤認 | スキップメッセージで「.claude/settings.json は別責務」と明示 |
| 設定ファイル不在時の挙動 | フォールバック規定（exit 2 → 通常フロー）でカバー |
