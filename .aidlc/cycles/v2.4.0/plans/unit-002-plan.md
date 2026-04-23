# Unit 002 計画: bin/update-version.sh の挙動変更（starter_kit_version 上書き廃止）

## 対象 Unit

- **Unit ファイル**: `.aidlc/cycles/v2.4.0/story-artifacts/units/002-update-version-script-change.md`
- **担当ストーリー**: ストーリー 6a（update-version.sh のスクリプト挙動変更、#596 実装側）
- **関連 Issue**: #596（部分対応：本 Unit はスクリプト挙動変更のみ。ドキュメント・周知は Unit 003）
- **依存 Unit**: なし
- **見積もり**: 1〜2 時間
- **実装優先度**: High

## 課題と修正方針

### 課題

`bin/update-version.sh` がリリース時に `.aidlc/config.toml.starter_kit_version` を上書きするため、メタ開発リポジトリ（AI-DLC スターターキット自身を AI-DLC で開発するリポジトリ）でアップグレード試験ができない。`starter_kit_version` は本来「最後に実行した `aidlc-setup` のバージョン」を記録する値であり、リリース時に書き換えるべきではない。

### 修正方針

`bin/update-version.sh` の更新対象から `.aidlc/config.toml` 書き込みを完全に削除する。一方、**読み取り検証は妥当性検証専用として残す**（既存契約 `error:config-toml-read-failed` / `error:invalid-config-toml-format` を維持し、壊れた config.toml を持つ repo での誤動作を防ぐ）。

具体的には以下の処理を削除:

1. **dry-run 出力**: `aidlc_toml_current` / `aidlc_toml_new` 行（L123-L124）
2. **成功出力**: `aidlc_toml:${VERSION}` 行（L197）
3. **書き込み処理**: `_tmp_toml` 作成（L138, L151）、`_bak_toml` 作成（L161, L163）、mv（L185）
4. **ロールバック処理**: `_bak_toml` 復元・削除（L178, L181, L192）
5. **trap**: `_tmp_toml` / `_bak_toml` 参照（L147）
6. **エラーケース**: `error:config-toml-write-failed`、書き込みパス由来のエラーを削除

**残置する処理**:

- **読み取り検証**: `_current_aidlc_toml=$(read_starter_kit_version ...)` 呼び出し（L108-L117）は維持。値は dry-run 出力から削除されるため未使用変数になるが、`read_starter_kit_version` の副作用として **unreadable / invalid format / duplicate key の検証エラー** が発生する。これは既存契約の維持（`error:config-toml-read-failed` / `error:invalid-config-toml-format` の保持）が目的。コードコメントで「妥当性検証専用、変数値は出力に使用しない」と明示する
- **ヘッダコメント**: 本 Unit では編集しない（Unit 003 が `bin/update-version.sh` の先頭コメントを排他所有しているため、コメント側の追従は Unit 003 で実施）

### 維持する処理

- **存在チェック**: `.aidlc/config.toml` の存在確認（L87-90、`error:config-toml-not-found`）— Unit 定義「責務」に従いリポジトリ整合性検証目的で残置
- **読み取り検証**: `read_starter_kit_version` 呼び出し（L108-L117）— 妥当性検証専用として残置（unreadable / invalid format / duplicate key 検出契約を維持）
- **`set -euo pipefail`**: 維持
- **`version.txt` / `skills/*/version.txt`**: 既存通り更新対象として維持
- **アトミック更新（mktemp + mv）**: 残った 3 ファイル（version.txt + skills/*/version.txt 2 本）に対して既存通り適用

### 変更箇所サマリ

| ファイル | 行番号 | 変更内容 |
|---------|--------|---------|
| `bin/update-version.sh` | L108-L117 | `_current_aidlc_toml` 読み取り処理は **維持**（妥当性検証専用とコメント追加） |
| `bin/update-version.sh` | L123-L124 | dry-run 出力 `aidlc_toml_current/new` 削除 |
| `bin/update-version.sh` | L138 | `_tmp_toml=$(mktemp ...)` 削除 |
| `bin/update-version.sh` | L147 | trap から `_tmp_toml` / `_bak_toml` 参照削除 |
| `bin/update-version.sh` | L151 | sed による toml 書き込み削除 |
| `bin/update-version.sh` | L161, L163 | `_bak_toml` バックアップ作成削除 |
| `bin/update-version.sh` | L178, L181 | `_rollback` 内 toml 復元削除 |
| `bin/update-version.sh` | L185 | `mv "$_tmp_toml" .aidlc/config.toml` 削除 |
| `bin/update-version.sh` | L192 | 後始末 `_bak_toml` 削除 |
| `bin/update-version.sh` | L197 | 成功出力 `aidlc_toml:${VERSION}` 削除 |

**ヘッダコメント（L13-L17 周辺）**: Unit 003 が `bin/update-version.sh` の先頭コメントを排他所有しているため、本 Unit では編集しない。Unit 003 完了時に整合追従される。

### 追加テスト

#### 単体テスト: `bin/tests/test_update_version_no_toml_write.sh`（新規）

`bin/tests/` ディレクトリも新規作成。既存テストは `skills/aidlc/scripts/tests/` 配下のスタイルに倣う。

- **ケース1: dry-run 出力に aidlc_toml_* 行が含まれない**
  - 一時 dir に最小 fixture（`version.txt`、`.aidlc/config.toml`、`skills/aidlc/version.txt`、`skills/aidlc-setup/version.txt`）を準備
  - `bin/update-version.sh --version v9.9.9 --dry-run` 実行
  - 期待: stdout に `version_update:dry-run` / `version_txt_*` / `skill_*_version_*` 行は含まれるが、`aidlc_toml_*` パターンは 0 行
  - assertion: `grep -cE '^aidlc_toml_' <output>` が `0`
- **ケース2: 成功出力に aidlc_toml: 行が含まれない**
  - 同 fixture で `bin/update-version.sh --version v9.9.9` 実行（dry-run なし）
  - 期待: stdout に `version_update:success` / `version_txt:` / `skill_*_version:` 行は含まれるが、`aidlc_toml:` パターンは 0 行
  - assertion: `grep -cE '^aidlc_toml:' <output>` が `0`
  - 副次 assertion: `.aidlc/config.toml` の `starter_kit_version` が変更されていない（修正前の値を保持）
- **ケース3: .aidlc/config.toml 不在時のエラーチェックは維持**
  - 一時 dir に `.aidlc/config.toml` を含めない状態
  - 期待: `bin/update-version.sh --version v9.9.9 --dry-run` 実行時に `error:config-toml-not-found` を出力し exit 1
- **ケース4: メタ開発シナリオ（starter_kit_version != version.txt が許容される）**
  - 一時 dir に `version.txt=2.4.0`、`.aidlc/config.toml.starter_kit_version=2.3.6` を作成
  - `bin/update-version.sh --version v2.5.0` 実行
  - 期待: `version.txt` のみ `2.5.0` に更新、`.aidlc/config.toml.starter_kit_version` は `2.3.6` のまま保持
- **ケース5: 読み取り検証エラーの維持**（Unit 002 の P1 対応で追加）
  - サブケース 5a: `.aidlc/config.toml` の `starter_kit_version` 行を不正な書式（`starter_kit_version = ` 値なし、または重複定義）にした fixture
  - 期待: `bin/update-version.sh --version v9.9.9 --dry-run` が `error:invalid-config-toml-format` を出力し exit 1（既存契約維持）
  - サブケース 5b: `.aidlc/config.toml` を読み取り権限なし（`chmod 000`）にした fixture
  - 期待: `error:config-toml-read-failed` を出力し exit 1（root 権限テストや CI 環境差異で skip 可能）
- **ケース6: ロールバック整合性**（P2 対応で追加、サブケース分割）
  - 修正後の `mv` 反映順は `version.txt → skills/aidlc/version.txt → skills/aidlc-setup/version.txt` の 3 段階
  - サブケース 6a: 2 回目失敗（`skills/aidlc/version.txt` の mv 失敗）
    - `PATH` 先頭に偽 `mv` スクリプトを配置し、`skills/aidlc/version.txt` をターゲットとした 2 回目の mv 呼び出しで失敗させる
    - 期待: `version.txt` が元値に復元（既に mv 完了している分のロールバック検証）、`skills/aidlc/version.txt` および `skills/aidlc-setup/version.txt` は元値のまま（mv 未実施）、`.aidlc/config.toml` は無変更、`error:skill-aidlc-version-write-failed` を出力し exit 1
  - サブケース 6b: 3 回目失敗（`skills/aidlc-setup/version.txt` の mv 失敗）
    - `PATH` 先頭に偽 `mv` スクリプトを配置し、3 回目の mv 呼び出しで失敗させる
    - 期待: `version.txt` および `skills/aidlc/version.txt` が **両方とも元値に復元**（2 つの mv が完了済みでロールバック対象が増えるパス）、`skills/aidlc-setup/version.txt` は元値のまま、`.aidlc/config.toml` は無変更、`error:skill-setup-version-write-failed` を出力し exit 1
  - サブケース 6b が「他のロールバック対象への影響がない」要件の本質的な検証になる（複数ファイル更新済みからのロールバック経路）

#### 既存スクリプトの regression 確認

- `skills/aidlc/scripts/tests/test_read_starter_kit_version.sh`（PASS=既存実績）が引き続き通る
- `skills/aidlc/scripts/tests/test_pr_ops_get_related_issues_empty.sh`、`test_operations_release_pr_ready_no_related_issues.sh`（Unit 001 で追加）が引き続き通る

## 完了条件チェックリスト

### Unit 定義「責務」由来

- [ ] `bin/update-version.sh` の更新対象から `.aidlc/config.toml` 書き込みが削除されている（`version.txt` と `skills/*/version.txt` のみ更新）
- [ ] dry-run 出力から `aidlc_toml_current` / `aidlc_toml_new` 行が削除されている
- [ ] 成功出力から `aidlc_toml:${VERSION}` 行が削除されている
- [ ] `.aidlc/config.toml` 関連のテンポラリファイル / バックアップ / ロールバック処理が削除されている
- [ ] `.aidlc/config.toml` の存在チェック（`config-toml-not-found` エラー）は残置されている
- [ ] **`.aidlc/config.toml` の読み取り検証は妥当性検証専用として残置されている**（`error:config-toml-read-failed` / `error:invalid-config-toml-format` の検出契約維持）
- [ ] メタ開発リポジトリで `bin/update-version.sh --version v9.9.9 --dry-run` 実行時に `aidlc_toml_*` 行が含まれない
- [ ] 最小限の新規テストが追加されている（既存テスト不在のため新規追加判断）

### Unit 定義「境界」由来

- [ ] CHANGELOG / README / rules.md / docs/configuration.md への変更は本 Unit に含めない（Unit 003 で対応）
- [ ] `aidlc-setup` / `aidlc-migrate` 側の `starter_kit_version` 書き込み経路は変更しない
- [ ] バージョン番号フォーマット（semver）の変更を含まない

### 非機能要件（NFR）由来

- [ ] スクリプト実行時間が変更前と同等以下（書き込み処理削減で同等または微減）
- [ ] ファイルパーミッション・所有権の変更なし
- [ ] `set -euo pipefail` を維持
- [ ] **macOS `/bin/bash`（3.2.57）で新規テストを実行し pass する**
- [ ] 既存テスト（`test_read_starter_kit_version.sh`、Unit 001 追加分）が引き続き通る

### 技術的考慮事項由来

- [ ] ロールバック処理から `.aidlc/config.toml` のバックアップ・復元行を削除した際、他のロールバック対象への影響がない（**ケース 6 のロールバック整合性テストで自動検証**）
- [ ] `_bak_toml` / `_tmp_toml` 等の変数名と trap での参照箇所を一括で削除（残骸なし）
- [ ] 新規テストで `grep -E '^aidlc_toml_' <output>` が 0 行を assert する

### Unit 003 との境界

- [ ] `bin/update-version.sh` の先頭コメント（L1-L26 周辺）は本 Unit で編集しない（Unit 003 が排他所有）
- [ ] CHANGELOG / README / rules.md / docs/configuration.md への変更は本 Unit に含めない（Unit 003 で対応）

## 設計フェーズ計画

`depth_level=standard` のため Phase 1（設計）を実施。最小粒度:

- ドメインモデル: `.aidlc/cycles/v2.4.0/design-artifacts/domain-models/unit_002_update_version_script_change_domain_model.md`
  - 内容: `update-version.sh` のドメイン責務（更新対象集合の縮小: 4 ファイル → 3 ファイル）と `.aidlc/config.toml` の役割再定義（書き込み対象 → **妥当性検証専用の読み取り対象**、`read_starter_kit_version` の副作用としての unreadable / invalid format / duplicate key 検証エラーの維持を含む）
- 論理設計: `.aidlc/cycles/v2.4.0/design-artifacts/logical-designs/unit_002_update_version_script_change_logical_design.md`
  - 内容: 修正前後の出力形式（dry-run / success）の差分表、削除対象コード行の一覧、`.aidlc/config.toml` の **妥当性検証専用読み取り** の位置付け（存在チェック + read_starter_kit_version の検証副作用）の明示

## 実装フェーズ計画

1. `bin/update-version.sh` の修正（10 箇所、計画ファイルの「変更箇所サマリ」表に従う。先頭コメントは Unit 003 へ委譲）
2. テストディレクトリ作成: `mkdir -p bin/tests`
3. テストファイル `bin/tests/test_update_version_no_toml_write.sh` 新規作成（6 ケース）:
   - ケース 1-4: 出力フォーマット変更とエラーチェック維持
   - ケース 5: 読み取り検証エラー（unreadable / invalid format）の維持
   - ケース 6: ロールバック整合性（mv 失敗注入で version.txt / skills/*/version.txt が元値復元）
4. 新規テスト実行（GNU bash 5.3）:
   - `bash bin/tests/test_update_version_no_toml_write.sh`
5. **bash 3.2 実機互換性検証**: macOS `/bin/bash`（3.2.57）で同テスト実行:
   - `/bin/bash bin/tests/test_update_version_no_toml_write.sh`
6. 既存関連テストの regression 確認:
   - `bash skills/aidlc/scripts/tests/test_read_starter_kit_version.sh`
   - `bash skills/aidlc/scripts/tests/test_pr_ops_get_related_issues_empty.sh`
   - `bash skills/aidlc/scripts/tests/test_operations_release_pr_ready_no_related_issues.sh`
7. メタ開発シナリオ手動確認: `bin/update-version.sh --version v9.9.9 --dry-run` を本リポジトリで実行し、`aidlc_toml_*` 行が含まれないことを目視確認

## 完了処理計画

1. Unit 定義ファイル `002-update-version-script-change.md` の「実装状態」を「完了」（状態・完了日・担当・適格性）に更新
2. `.aidlc/cycles/v2.4.0/history/construction_unit02.md` への履歴追記（`/write-history` スキル経由）
3. `construction/progress.md` の以下 3 セクションを一貫更新:
   - Unit 一覧テーブル: Unit 002 行の「状態」を「完了」、「完了日」を記入
   - 「現在の Unit」セクション: Unit 002 完了 → 次の実行可能 Unit（003 / 004 / 005 / 006）の自動選択候補へ更新
   - 「完了済み Unit」セクション: Unit 002 を追記
4. squash 統合（中間コミット 0 件のため `squash:skipped:no-commits` の見込み）
5. PR #599 へのコミット push（Unit ブランチは無効: `unit_branch_enabled=false`）
6. Issue #596 ステータス更新方針: **Unit 003 完了後にサイクル PR マージ時 `Closes #596` で auto-close**（部分対応 Unit のため、Unit 002 完了時点では Issue ステータスを変更しない）

## リスク・注意事項

### 既存呼び出し元への影響（hidden breaking change リスク評価）

repo 内の参照を実調査した結果（`grep -rln "update-version" --include="*.sh" --include="*.md" --include="*.yml"` および `grep -rln "aidlc_toml"`）:

- **`.github/workflows/`**: `update-version.sh` の呼び出しなし（CI からの直接利用なし、auto-tag は `version.txt` から行う）
- **repo 内に `aidlc_toml_*` パーサなし**: stdout を grep / awk で parse している箇所は存在しない
- **既知の呼び出し元**: `.aidlc/operations.md` / `.aidlc/rules.md`（手順書記述）、`CHANGELOG.md`（履歴記述）、`skills/aidlc/guides/exit-code-convention.md`（exit code 規約参照）— いずれもドキュメントレベルの参照のみで、stdout を parse していない
- **残余リスク**: 利用者の外部 / private automation で `aidlc_toml_*` 行を parse しているケース。これは Unit 003 の CHANGELOG 周知で対応（hidden breaking change として明記）

### 実装時の注意

- **ロールバック処理の整合性**: `_bak_toml` 関連を削除する際、残った `_bak_version` / `_bak_skill_aidlc` / `_bak_skill_setup` の処理が壊れないよう変数参照を慎重に確認する。テストケース 6（ロールバック整合性）で自動検証
- **trap 文の構文**: `trap '\rm -f ...' EXIT` の引数リストから `_tmp_toml` / `_bak_toml` を抜く際、trap 構文の引用符バランスを保つ
- **読み取り検証コメント**: `_current_aidlc_toml` は値を出力に使わなくなるため、「妥当性検証専用、変数値は出力に使用しない」とコードコメントで明示する。これにより未使用変数として後続改修で削除されるリスクを抑える
- **`.aidlc/config.toml` 存在チェック残置の理由明示**: 削除する書き込み処理と区別するため、コメントで「リポジトリ整合性検証のための入力存在チェック」と明示する
- **bash 3.2 互換性**: 既存スクリプトは bash 3.2 互換構文を使用しており、本修正でも bash 3.2 専用構文の導入を行わない
