# Unit 001 計画: v3 state スクリプト基盤

- **Unit**: 001-v3-state-scripts（v3 state スクリプト基盤）
- **サイクル**: v3.0.0-alpha.2（Phase 2: aidlc-v3 skeleton）
- **depth_level**: standard（Phase 1 設計あり）
- **automation_mode**: semi_auto / **review_mode**: required
- **関連 Issue**: なし

## 1. 目的

`skills/aidlc-v3/scripts/` に state.json を操作する 3 本のスクリプトを作成し、v3 の cycle state（`state.json`）に対する最小 I/O API を確立する。設計正本は `docs/v3/data-model.md` §3（state.json schema）。

- `state-read.sh`: state.json から指定フィールドを抽出（read-only）
- `state-write.sh`: state.json を atomic（temp file + mv）に書き込み（schema validation + 許可フィールド更新に限定）
- `state-validate.sh`: 必須フィールド・型・JSON 妥当性を検証し exit code で結果を返す

## 2. スコープ

### 含むもの

- `skills/aidlc-v3/scripts/state-read.sh`
- `skills/aidlc-v3/scripts/state-write.sh`
- `skills/aidlc-v3/scripts/state-validate.sh`
- 上記 3 本の動作確認テスト（正常系・異常系）

### 含まないもの（後続フェーズへ defer）

- 許可/禁止状態遷移ルールの具体化（Phase 3 / flow 実装）。本 Unit は schema validation + atomic write + 許可フィールド更新まで
- define / status / develop / release フロー本体の実装（Phase 3 以降）
- テンプレート（Unit 002）・SKILL.md / steps（Unit 003）
- `skills/aidlc`（v2）への一切の変更（クリーンカット / 共存）

## 3. 設計方針（Phase 1 で詳細化）

### 3.1 state.json schema（`docs/v3/data-model.md` §3 準拠）

| フィールド | 型 | 必須 |
|-----------|---|------|
| `schema_version` | string | Yes |
| `current_cycle` | string | Yes |
| `define_completed` | boolean | Yes |
| `release` | object | Yes |
| `release.pr_number` | integer or null | Yes |
| `release.ready` | boolean | Yes |
| `release.merge_approved` | boolean | Yes |
| `updated_at` | string (ISO 8601) | Yes |

### 3.2 各スクリプト I/F（論理設計で確定）

- **state-read.sh**: 引数で対象フィールドキー（`schema_version` / `current_cycle` / `define_completed` / `release.pr_number` / `release.ready` / `release.merge_approved` / `updated_at`）とファイルパスを受け取り、jq で値を stdout に出力。キー不在・ファイル不在は exit code で区別
- **state-write.sh**: 許可フィールドのみ更新可能とし、temp file へ jq で書き込み → `state-validate.sh` で検証 → 検証成功時のみ `mv` で atomic 反映。検証失敗時は temp を破棄し元ファイルを保持。**論理設計で確定する項目**: 更新可能キーの完全リスト（`define_completed` / `release.pr_number` / `release.ready` / `release.merge_approved`）/ `updated_at` を自動付与するか入力で受けるか / CLI 引数形式 / 初期 state 作成と既存 state 更新の境界
- **state-validate.sh**: JSON parse 妥当性 → 必須トップレベルフィールドの存在・型 → `release` サブフィールド（`pr_number`: integer or null / `ready`: boolean / `merge_approved`: boolean）の存在・型を検証。1 つでも欠落/型不正なら無効。`updated_at` は string 型に加え **ISO 8601 形式の妥当性も検証**し、形式不正は無効とする（許容する形式の厳密な範囲は論理設計で確定）。exit code で結果を返す

### 3.3 終了コード規約（`skills/aidlc/guides/exit-code-convention.md` 照合）

- 設計レビュー時に `skills/aidlc/guides/exit-code-convention.md` と照合する（v1.27.3 の規約違反再発防止）
- 規約準拠の分類で確定する（詳細は論理設計）:
  - `0` = 成功（正常完了 / 有効。警告付き完了を含む）
  - `1` = バリデーションエラー（引数不正、入力ファイル不存在・空、キー不在、schema invalid／検証失敗）
  - `2` = システムエラー（jq 未導入、ファイル読み取り不能、外部コマンド失敗）

### 3.4 共通方針

- ツール: `jq`（環境に存在を確認済み: `/opt/homebrew/bin/jq`）
- `set -euo pipefail` を設定
- 実 `.sh` 内では `$(...)` 使用可（コマンド置換禁止規約は Markdown プロンプト `*.md` が対象。`bin/check-bash-substitution.sh` の対象は `skills/aidlc/steps/*.md`）。ただし Bash ツール経由実行時のハザード（Issue #697）に留意し、スクリプト自体は適切に記述する

## 4. 完了条件チェックリスト

Unit 定義「責務」+ Intent 受け入れ基準（state スクリプト該当分）から抽出。

- [ ] `skills/aidlc-v3/scripts/state-read.sh` が存在し、指定フィールド（`schema_version` / `current_cycle` / `define_completed` / `release.*` / `updated_at`）を抽出できる
- [ ] `skills/aidlc-v3/scripts/state-write.sh` が存在し、atomic（temp file + mv）に書き込み、許可フィールド更新に限定されている
- [ ] `state-write.sh` が書き込み前に schema validation を行い、検証失敗時は元ファイルを保持する
- [ ] `skills/aidlc-v3/scripts/state-validate.sh` が存在し、必須フィールド（`schema_version` / `current_cycle` / `define_completed` / `release` / `updated_at`）+ `release` サブフィールド（`pr_number` / `ready` / `merge_approved`）の存在・型・JSON 妥当性を検証する
- [ ] `state-validate.sh` が `updated_at` の欠落・型不正・ISO 8601 形式不正、および `release` サブフィールド欠落/型不正も無効と判定する
- [ ] 3 本すべてが `bash -n` を通過する
- [ ] shellcheck（利用可能時）で重大警告がない
- [ ] macOS / Linux 両対応（BSD/GNU 差を踏まえた記述）
- [ ] 有効な state.json / 無効な state.json をテストで正しく判定できる
- [ ] **v2 非影響**: `skills/aidlc/` 配下に変更がない（`git diff` で確認）
- [ ] スコープ逸脱がない（成果物が `skills/aidlc-v3/scripts/` および `.aidlc/cycles/` 配下に限定、フロー実行実装を含まない）
- [ ] markdownlint を通過する（本計画・履歴等の Markdown 成果物）

## 5. 想定リスク

- **終了コード規約違反**: 警告付き完了を exit 2 にする等の既知のアンチパターン → 設計レビューで `skills/aidlc/guides/exit-code-convention.md` 照合
- **macOS/Linux 差異**: `mktemp` / `mv` 等の BSD/GNU フラグ差 → 可搬性のあるオプションのみ使用
- **atomic 性の取りこぼし**: temp file を同一ファイルシステム（同一ディレクトリ）に作成し `mv` の atomic 性を担保

## 6. 進め方

1. Phase 1（設計）: ドメインモデル → 論理設計 → 設計 AI レビュー → 設計承認
2. Phase 2（実装）: コード生成 → コード AI レビュー → テスト生成 → ビルド・テスト実行（Self-Healing）→ 統合 AI レビュー → 実装承認
3. 完了処理: 完了条件チェック → 整合性チェック → Unit 定義状態更新 → 履歴記録 → markdownlint → squash → コミット
