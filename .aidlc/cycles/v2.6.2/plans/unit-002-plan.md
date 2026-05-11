# Unit 002 計画: aidlc-migrate manifest 由来パスのトラバーサル検証

## 対象

- Unit 定義: `.aidlc/cycles/v2.6.2/story-artifacts/units/002-fix-aidlc-migrate-traversal.md`
- 関連 Issue: #680（type:security, type:defer-from-review, priority:high）
- 関連ストーリー: ストーリー 3
- 由来: v2.6.0 Unit 003 codex Round 1〜3 連続指摘 defer

## 目的

`skills/aidlc-migrate/scripts/` 配下の書き込み系スクリプトで manifest 由来の `path` / `destination` を検証し、細工された fork manifest によるリポジトリ外ファイルの読み書き・削除攻撃を構造的に予防する（fail-closed）。

## スコープ

### 含まれるもの

1. **共通検証ヘルパー** `skills/aidlc-migrate/scripts/lib/path-guard.sh` を新設し、manifest 由来パス検証を単一 SoT として実装する（呼び出し元はヘルパー戻り値の判定のみ）

   **関数シグネチャ（確定値）**:

   ```text
   _aidlc_migrate_validate_path <raw_path> <field_name> <script_id>

   引数:
     $1 raw_path   : manifest 由来の検証対象パス文字列（変更せず素通し / 正規化済みパス戻し無し）
     $2 field_name : 検証対象フィールド名（"path" / "destination" / "new_path" 等）
     $3 script_id  : 呼び出し元スクリプト識別子（"migrate-apply-config" / "migrate-apply-data" / "migrate-cleanup"）

   戻り値:
     0 : 検証成功（呼び出し元はそのまま raw_path を使用）
     1 : 検証失敗（呼び出し元は即 exit 1 で停止 / バリデーションエラー扱い）

   stdout: 何も出力しない（呼び出し元のフロー出力を汚さない）
   stderr: 検証失敗時のみ tab 区切り 4 フィールド出力（後述）
   副作用: なし（純粋関数 / ファイル参照は realpath 経由のみ）
   ```

   **拒否条件**:

   - 絶対パス（`/` で始まる）
   - `..` セグメント含有（path component として `..` を検出）
   - `realpath` 物理解決後に `AIDLC_PROJECT_ROOT` 配下外
   - シンボリックリンク経由の脱出（物理パス解決で配下外）

   **許容**: `AIDLC_PROJECT_ROOT` からの相対パスで、物理解決後も配下に収まるもの

2. **realpath shim** `_aidlc_migrate_realpath` を同 lib 内に実装（macOS BSD と GNU の挙動差を吸収）

   **採用方針（確定）**: (a) `realpath -m` 存在確認 + pure bash フォールバック

   - 第一選択: `realpath -m <path>` が利用可能ならそれを使用（GNU coreutils / 新しめの macOS Homebrew coreutils）
   - フォールバック: pure bash で `cd -P` ループによる物理パス解決（実体不在パスは親ディレクトリまで遡って解決）
   - **不採用理由**:
     - (b) `python3` 委譲: 既存スクリプトの依存（bash + git + jq）に python を追加するのを避けるため
     - (c) `perl` 委譲: 同上 + macOS の perl と Linux distribution の perl で path 差が生じる可能性

3. **検証フック挿入**（aidlc-migrate 配下の書き込み系3ファイル）:
   - `migrate-apply-config.sh`: `v1_config_move`（`path` / `destination`）と `config_update`（`path`）の各ループ先頭でヘルパー呼び出し（script_id=`migrate-apply-config`）
   - `migrate-apply-data.sh`: `v1_data_move`（`path` / `destination`）と `data_path_update`（`path`）の各ループ先頭でヘルパー呼び出し（および `mv "$old_path" "$new_path"` の `new_path` も検証）（script_id=`migrate-apply-data`）
   - `migrate-cleanup.sh`: `cleanup`（`path`）の各ループ先頭でヘルパー呼び出し（script_id=`migrate-cleanup`）

4. **エラー出力**（tab 区切り 4 フィールド固定 / stderr / スクリプト単位の識別子）:

   ```text
   error<TAB><script_id>:path-traversal<TAB><offending_path><TAB>reason=<code>
   ```

   - `<script_id>` は `migrate-apply-config` / `migrate-apply-data` / `migrate-cleanup` のいずれか（呼び出し元ヘルパー第3引数の値をそのまま展開）
   - `<code>` は `absolute_path` / `parent_traversal` / `outside_project_root` / `symlink_escape` のいずれか
5. **exit code**: 全拒否ケースで **`1` 固定**（`guides/exit-code-convention.md` 準拠 / バリデーションエラー扱い）。ヘルパー戻り値 1 を受けた呼び出し元は `exit 1` で停止。realpath shim が外部コマンド失敗（システムエラー）を返した場合のみ呼び出し元は `exit 2`
6. **bats テスト追加**:
   - `tests/migration/migrate-path-traversal.bats`（新規）: 4 拒否シナリオ × 3 スクリプト × `path` / `destination` 主要組合せ（最低 8〜12 ケース）
     - 絶対パス / `..` / realpath 解決後の配下外 / symlink 経由脱出
     - 各ケースで exit 1 + `<script_id>:path-traversal` + 該当 `reason=<code>` を stderr で検証
     - 副作用未発生（リポジトリ外ファイル変更がないこと）をアサート
   - 既存テスト（`tests/migration/migrate-apply-config.bats` / `migrate-apply-data.bats` / `migrate-cleanup.bats`）が pass し続けることを回帰確認
7. **realpath shim 単体テスト**: bats 内で macOS / Linux 両プラットフォーム挙動を検証（CI で両方走らせる）

### 含まれないもの

- `aidlc-migrate` 配下の **読み取り専用スクリプト**（`migrate-detect.sh` / `migrate-verify.sh`）の検証強化（出力先がない / `cat` / `grep` のみ）
- `aidlc-setup` / `aidlc` 等、他スキルの manifest 検証強化（Unit 定義 §境界より対象外）
- manifest スキーマ全体の strict validation（型・必須キー・enum 等）。本 Unit は `path` / `destination` 文字列レベルの検証のみ
- 信頼境界の前提（公式リポジトリ経由では発火しない）の文書整備は本 Unit のドキュメント記述に含めるが、専用ガイド整備は対象外

## スコープ拡張根拠（Unit 定義「責務」との差分）

Unit 定義「責務」は「`migrate-apply-config.sh` の `_apply_resource()` 系」と表現されているが、実コードでは `_apply_resource()` 関数化されておらず各ループ内に直接展開されている。実態調査の結果、同一脆弱パターンが書き込み系3ファイル（`migrate-apply-config.sh` / `migrate-apply-data.sh` / `migrate-cleanup.sh`）に存在することを確認した。

Unit 定義「境界」の「aidlc-migrate スコープに閉じる」と Issue #680 タイトル「aidlc-migrate: manifest 由来パスのトラバーサル検証を追加」がスコープ拡張を許容するため、defer 残骸ゼロ化のため3ファイル全てを対象とする（ユーザー承認済み: 2026-05-11）。

## 完了条件チェックリスト

### Unit 定義「責務」由来

- [x] `skills/aidlc-migrate/scripts/lib/path-guard.sh` が新設され、manifest 由来パス検証を単一 SoT として実装している
- [x] 検証ヘルパーが拒否条件 4 種（絶対パス / `..` / 配下外 / symlink 経由脱出）をすべて戻り値 1 で報告し、呼び出し元が exit 1 で停止する
- [x] `migrate-apply-config.sh` / `migrate-apply-data.sh` / `migrate-cleanup.sh` の manifest 由来 `path` / `destination` 抽出後、書き込み操作（`cp` / `rm` / `mkdir` / `mv` / `sed > $tmp && mv`）の前に検証ヘルパーが呼ばれている
- [x] エラー出力が tab 区切り 4 フィールド形式 `error\t<script_id>:path-traversal\t<offending_path>\treason=<code>;field=<name>` で stderr に出る（`<script_id>` がスクリプト単位で識別可能、`<name>` がフィールド単位で識別可能）
- [x] macOS BSD `realpath` と GNU `realpath` の双方で同じ判定結果（shim 動作 / bats `realpath -m fallback` テスト pass）

### Issue #680 期待結果

- [x] manifest 由来 `path` / `destination` が `AIDLC_PROJECT_ROOT` 配下にあることを検証
- [x] 配下外なら即 exit 1 で停止（バリデーションエラー / `guides/exit-code-convention.md` 準拠）
- [x] 絶対パス・`..` 含有を拒否
- [x] macOS BSD `realpath` と GNU `realpath` の挙動差を吸収
- [x] bats でパストラバーサル攻撃ケース（最低 4 種）を検証（migrate-path-traversal.bats 12 件 + migrate-cleanup.bats 拡張 3 件）

### 非機能要件（Unit 定義 §NFR）

- [x] セキュリティ: 攻撃 4 ケース全てが exit 1 で停止（fail-closed / バリデーションエラー）
- [x] パフォーマンス: `realpath` 呼び出しオーバーヘッドが manifest エントリあたり 10ms 未満（process substitution 経由 / 一時ファイル不使用 / init で root を 1 回解決し以降キャッシュ）
- [x] 可搬性: macOS BSD `realpath` と GNU `realpath` の双方で同一判定結果

### Intent 制約（Unit 定義 §Intent 制約適合）

- [x] 破壊的変更なし（既存正常 manifest が変更なしで動作することを既存 bats 37 件回帰で検証）
- [x] ドッグフーディング特殊処理なし（自リポジトリ判定で fail-closed/fail-open を切り替えない / 無条件 fail-closed）
- [x] `$(...)` 形式コマンド置換の新規導入なし（新規 `lib/path-guard.sh` は process substitution `<(...)` + `read` で全中間結果を受信）

## 実装方針（概略）

### Phase 1（設計）で詰める項目

主要 I/F（ヘルパーシグネチャ・realpath shim 方針・エラー出力形式・exit code）は本計画で**確定済み**（codex Round 1 指摘 #1 対応で承認条件に前倒し）。Phase 1 では以下の実装詳細のみ詰める:

1. pure bash `cd -P` ループ実装の具体アルゴリズム（実体不在 path の親遡り・末端結合・トレーリングスラッシュ正規化）
2. realpath shim の単体テスト fixture 設計（macOS / Linux 双方で同一判定結果を担保する観点で何を比較するか）
3. `tests/migration/helpers/setup.bash` への共通 fixture（攻撃 manifest テンプレート 4 種）追加方針
4. ドメインモデル / 論理設計成果物の表現（境界・責務・依存方向の図示形式）

### Phase 2（実装）の段階分け

1. `lib/path-guard.sh` 単体実装 + 単体 bats（拒否 4 種を独立検証）
2. `migrate-apply-config.sh` への組込（v1_config_move + config_update）
3. `migrate-apply-data.sh` への組込（v1_data_move + data_path_update）
4. `migrate-cleanup.sh` への組込（cleanup）
5. 統合 bats（攻撃 manifest を 3 スクリプトに食わせて exit 1 / 副作用なしをアサート）
6. 既存 bats 回帰確認

## 依存・前提

- bash + `realpath`（GNU/BSD どちらでも shim で吸収）
- bats 1.13+（既存環境）
- shellcheck / shellharden（既存 lint 環境）
- macOS / Linux 双方の CI（既存 GitHub Actions cross-platform マトリクス）

## リスクと緩和

| リスク | 影響 | 緩和策 |
|--------|------|--------|
| BSD `realpath` で `-m` / `--strict` 不在の古い macOS | 中 | shim 内で `command -v realpath` + バージョン判定し、フォールバック実装で対応 |
| 既存正常 manifest で偶発的に拒否される | 中 | 既存 `migrate-apply-config.bats` / `migrate-apply-data.bats` / `migrate-cleanup.bats` の全 pass を CI で確認 |
| `realpath` が実体不在 path を解決できない（`-m` 不在 BSD） | 中 | 親ディレクトリまで遡って解決（`cd -P` ループ）するフォールバックを shim に実装 |
| shellharden / shellcheck 違反増加 | 低 | 各 commit 前に `bin/check-bash-substitution.sh` と shellcheck をローカル実行 |
| symlink 経由脱出の検出漏れ | 高 | shim を `-P` 相当（物理パス解決）で固定し、bats fixture に symlink 経由脱出ケースを必ず含める |

## 想定タイムライン（Unit 定義「見積もり」より）

- Phase 1 設計: 〜0.5 日（shim 方針確定 + ヘルパーシグネチャ確定）
- Phase 2 実装: 〜0.5〜1 日（lib 実装 + 3 ファイル組込 + bats fixture 整備）
- 完了処理: 〜0.25 日

合計: 約 1〜1.5 日（Unit 見積もり内）
