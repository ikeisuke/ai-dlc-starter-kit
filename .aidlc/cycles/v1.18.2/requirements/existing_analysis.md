# 既存コード分析 - v1.18.2

## 1. $()パターン分析

### プロンプトファイル（prompts/package/prompts/）

**30+箇所、9ファイル**に`$()`が存在。すべてコードブロック内（Claude Codeが実行する例）。

| パターン | 件数 | 対象ファイル | 対策方針 |
|---------|------|------------|---------|
| `git commit -m "$(cat <<'EOF'...)"` | 14 | commit-flow.md | Writeツールで一時ファイル作成 → `git commit -F` 方式に変更 |
| `write-history.sh --content "$(cat <<'CONTENT_EOF'...)"` | 9+ | review-flow.md, rules.md, inception.md他 | `--content-file` オプション追加、Writeツール+`--content-file`方式に変更 |
| `gh pr create/edit --body "$(cat <<'EOF'...)"` | 5+ | inception.md, construction.md, operations-release.md | Writeツールで一時ファイル作成 → `gh pr create --body-file` 方式に変更 |
| `$(git branch --show-current)` inline | 2 | inception.md:782, operations.md:419 | 2コマンドに分割（変数代入はAI側で管理） |
| `$(awk '...')` inline | 1 | construction.md:617 | スクリプト化を検討 |
| `$(ghq root)` in prose | 2 | operations.md:7,672 | リテラルテキスト（実行されない）だが曖昧。パス解決スクリプトに統一 |

### シェルスクリプト（prompts/package/bin/）

**100+箇所、32ファイル**すべて内部ロジック。Claude Codeの許可には影響しない。対策不要。

## 2. upgrading-aidlcスキル分析

### 現状構造

- **SKILL.md**: `.claude/skills/upgrading-aidlc/` → `../../docs/aidlc/skills/upgrading-aidlc` (シンボリックリンク)
- **正本**: `prompts/package/skills/upgrading-aidlc/SKILL.md`
- **動作**: setup-prompt.mdを読み込んで対話的にステップ実行（AIが全ステップを手動実行）

### $()パターン（SKILL.md内）

```bash
GHQ_ROOT=$(ghq root)
RAW_REPO=$(docs/aidlc/bin/read-config.sh project.starter_kit_repo --default "ghq:github.com/ikeisuke/ai-dlc-starter-kit")
```

### setup-prompt.md（1,257行）の主要処理

1. `check-setup-type.sh` でセットアップ種別判定
2. `docs/aidlc.toml` の `starter_kit_version` 更新
3. `migrate-config.sh` で設定マイグレーション
4. `sync-package.sh` で rsync同期（prompts/package/ → docs/aidlc/）
5. Git コミット

### スクリプト化対象

| 処理 | 現状 | スクリプト化 |
|-----|------|------------|
| パス解決 | `$(ghq root)` + `$(read-config.sh)` | `resolve-starter-kit-path.sh`（既存）を活用 |
| 種別判定 | `check-setup-type.sh`（既存） | そのまま利用 |
| バージョン更新 | AIが手動でsed/dasel実行 | 新スクリプトに統合 |
| 設定マイグレーション | `migrate-config.sh`（既存） | そのまま利用 |
| rsync同期 | `sync-package.sh`（既存） | そのまま利用 |
| ブランチ作成・PR | 未実装 | 新規追加 |

## 3. AIレビューフロー機密情報分析

### review-flow.mdの現状

- L142等でAIレビュー実行時にファイルパスを直接渡している
- 機密情報スキャン・除外のステップなし
- `target_files` をそのまま外部ツール（codex等）に送信

### 追加が必要なもの

- レビュー前の機密情報スキャンステップ
- 除外パターン定義（`.env`, `*.key`, `credentials.*`, etc.）
- 許可リスト方式（`docs/**`, `prompts/**` のみ許可）or 拒否リスト方式

## 4. セッションタイトル表示分析

### 現状

- `env-info.sh` が `project.name`, `current_branch`, `latest_cycle` を出力
- ブランチ名からサイクルバージョンを判定可能
- フェーズ情報は progress.md やプロンプト読み込み時に判明

### 実装方式候補

- 各フェーズプロンプトの冒頭で `printf '\033]0;%s\007'` でターミナルタイトルを設定
- `env-info.sh` の出力を利用してタイトル文字列を生成

## 5. update-version.sh分析

### 現状

- **場所**: `prompts/package/bin/update-version.sh` → rsyncで `docs/aidlc/bin/` にコピー
- **参照元**: `docs/cycles/rules.md` (L48, L54), `.claude/settings.local.json` (L77, L87)
- **移動先候補**: `bin/`（リポジトリルート直下、既に `check-size.sh` が存在）

### 必要な変更

1. `prompts/package/bin/update-version.sh` を `bin/update-version.sh` に移動
2. `docs/cycles/rules.md` のパス参照を `bin/update-version.sh` に更新
3. `.claude/settings.local.json` のパス参照を更新
4. rsync後に `docs/aidlc/bin/update-version.sh` が残らないことを確認
