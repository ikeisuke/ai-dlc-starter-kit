# Unit 001 計画: パス参照の抽象化

## 概要

ステップファイル・スクリプト内の物理パス `docs/aidlc/` 直接参照を抽象化し、config.toml の `[paths]` セクション経由のパス解決に統一する。

## 現状分析

### ステップファイル内の `docs/aidlc/` 参照（約50箇所）

主にガイド参照リンクとして使用されている:
- `docs/aidlc/guides/backlog-management.md`（7箇所）
- `docs/aidlc/guides/config-merge.md`（3箇所）
- `docs/aidlc/guides/issue-management.md`（2箇所）
- `docs/aidlc/guides/worktree-usage.md`（2箇所）
- `docs/aidlc/bug-response-flow.md`（2箇所）
- `docs/aidlc/guides/subagent-usage.md`（1箇所）
- `docs/aidlc/guides/skill-usage-guide.md`（1箇所）
- `docs/aidlc/guides/ios-version-update.md`（1箇所）
- setup関連（v1移行説明、rsync同期説明等）

### スクリプト内の参照（2箇所）

- `scripts/check-setup-type.sh:32`: `PROJECT_TOML="docs/aidlc/project.toml"`
- `scripts/migrate-config.sh:317`: エラーメッセージ内の参照

### 既存の抽象化メカニズム

- `lib/bootstrap.sh`: `AIDLC_PROJECT_ROOT`, `AIDLC_PLUGIN_ROOT`, `AIDLC_CONFIG`, `AIDLC_CYCLES`, `AIDLC_DEFAULTS` を提供
- `read-config.sh`: config.toml から値を取得するバッチ対応スクリプト（`bootstrap.sh` を source している）
- config.toml `[paths]`: `aidlc_dir = "docs/aidlc"`, `cycles_dir = ".aidlc/cycles"`, `setup_prompt = "prompts/setup-prompt.md"`

**不足**: `AIDLC_DOCS_DIR`（`docs/aidlc/` に対応する環境変数）が bootstrap.sh にない

## 変更対象ファイル

### Phase 1: パス解決メカニズムの整備

1. **`skills/aidlc/scripts/lib/bootstrap.sh`** — `AIDLC_DOCS_DIR` 環境変数を追加
2. **`skills/aidlc/config/defaults.toml`** — `[paths]` セクションに `aidlc_dir` デフォルト値を追加

### Phase 2: スクリプトの物理パス参照を抽象化

3. **`skills/aidlc/scripts/check-setup-type.sh`** — `docs/aidlc/` を `AIDLC_DOCS_DIR` 変数に置換
4. **`skills/aidlc/scripts/migrate-config.sh`** — エラーメッセージ内の参照を変数化

### Phase 3: ステップファイルの物理パス参照を置換

5. **ステップファイル群** — `docs/aidlc/` を `{{aidlc_dir}}/` プレースホルダーに置換
   - `steps/common/rules.md`
   - `steps/common/review-flow.md`
   - `steps/common/project-info.md`
   - `steps/common/ai-tools.md`
   - `steps/construction/01-setup.md`
   - `steps/construction/04-completion.md`
   - `steps/inception/01-setup.md`
   - `steps/inception/02-preparation.md`
   - `steps/inception/05-completion.md`
   - `steps/inception/06-backtrack.md`
   - `steps/operations/01-setup.md`
   - `steps/operations/02-deploy.md`
   - `steps/operations/04-completion.md`
   - `steps/setup/01-detect.md`
   - `steps/setup/02-generate-config.md`
   - `steps/setup/03-migrate.md`

### Phase 4: テスト更新

6. **`prompts/package/tests/test_resolve_starter_kit_path.sh`** — 必要に応じて更新

## 実装計画

### 設計方針

**スクリプト（Shell）**: `bootstrap.sh` に `AIDLC_DOCS_DIR` を追加。**循環依存を避けるため**、`read-config.sh` は呼ばず、`bootstrap.sh` 内で直接 `dasel` を使って `paths.aidlc_dir` を取得する（`AIDLC_CONFIG` のパスは bootstrap.sh 自身が既に確定済みのため）。取得失敗時は `"docs/aidlc"` にフォールバック。

**ステップファイル（Markdown）**: AIエージェントが読み込むドキュメント。`docs/aidlc/` を `{{aidlc_dir}}/` に置換。

**`{{aidlc_dir}}` の解決契約**:
- **解決タイミング**: AIエージェントがステップファイルを読み込む際に、コンテキスト変数 `aidlc_dir` で即時解決する
- **コンテキスト変数の供給元**: プリフライトチェックのステップ4（設定値取得）で `paths.aidlc_dir` を `read-config.sh` 経由で取得し、`aidlc_dir` コンテキスト変数に格納する
- **未解決時の挙動**: `aidlc_dir` が未設定（preflight未実行等）の場合、AIエージェントはデフォルト値 `"docs/aidlc"` を使用する。これは `defaults.toml` に定義されたデフォルト値と一致する
- **preflight非依存性**: `defaults.toml` にデフォルト値が定義されているため、`read-config.sh` 単体でも値が取得可能。preflight は一括取得の効率化手段であり、`{{aidlc_dir}}` 解決の唯一の経路ではない

**デフォルト値とエラーハンドリング**:
- `defaults.toml` に `[paths].aidlc_dir = "docs/aidlc"` を追加（必須）
- `bootstrap.sh` での取得失敗時: `"docs/aidlc"` にフォールバック（警告出力あり）
- `read-config.sh` での取得失敗時: `defaults.toml` のフォールバック（既存の仕組み）

**直接参照を許可する例外条件**:

以下のカテゴリに該当する箇所は物理パス直接参照を維持する:

| カテゴリ | 説明 | 例 |
|---------|------|-----|
| rsync同期先 | `prompts/package/` → `docs/aidlc/` のファイル同期コマンド | setup/02-generate-config.md のrsyncセクション |
| v1移行パス | v1→v2移行時の旧パス参照（移行元として固定） | setup/02-generate-config.md の移行テーブル、setup/01-detect.md の検出ロジック |
| git addパス | コミット対象のパス指定 | setup/03-migrate.md の `git add` コマンド |

例外箇所には `<!-- AIDLC-PATH: physical-path-required (reason: rsync-target|v1-migration|git-add) -->` コメントを付与し、grep で一覧管理可能にする。

### ステップ

1. `defaults.toml` に `[paths].aidlc_dir = "docs/aidlc"` を追加
2. `bootstrap.sh` に `AIDLC_DOCS_DIR` を追加（dasel で直接取得、フォールバック付き）
3. スクリプト2ファイルの `docs/aidlc/` 参照を `${AIDLC_DOCS_DIR}` に置換
4. プリフライトチェック（`preflight.md`）のステップ4に `paths.aidlc_dir` の取得を追加
5. ステップファイルの `docs/aidlc/` 参照を `{{aidlc_dir}}/` に置換（例外箇所にはコメント付与）
6. テスト更新・動作確認
7. markdownlint実行

## 完了条件チェックリスト

- [ ] ステップファイル内の `docs/aidlc/` 物理パス直接参照が `{{aidlc_dir}}/` に置換されている（例外箇所はコメント付きで管理）
- [ ] `skills/aidlc/scripts/` 内のスクリプトの物理パス参照が `AIDLC_DOCS_DIR` 変数経由に抽象化されている
- [ ] パス解決メカニズムが整備されている（bootstrap.sh で dasel 直接取得、循環依存なし）
- [ ] `defaults.toml` に `[paths].aidlc_dir = "docs/aidlc"` が定義されている
- [ ] 既存パス解決テスト（`test_resolve_starter_kit_path.sh`）が更新されている
- [ ] config.toml `[paths].aidlc_dir` の値を変更した場合に、ステップファイル・スクリプトが追従する構造になっている
- [ ] 例外箇所が `AIDLC-PATH` コメントで一覧管理されている

## AIレビュー対応

Codex レビュー（セッション: 019d3000-47a0-7753-8563-e06b57ce6f44）の指摘4件に対応済み:

1. **高: 循環依存** → bootstrap.sh で dasel 直接取得に変更（read-config.sh を呼ばない）
2. **高: {{aidlc_dir}} 解決契約** → 解決タイミング・未解決時挙動・preflight非依存性を明文化
3. **中: defaults.toml 未定義** → `[paths].aidlc_dir` のデフォルト値追加を必須化、エラーハンドリング方針を明記
4. **低: 例外境界の曖昧さ** → 例外カテゴリを定義し、コメントタグによる一覧管理を導入
