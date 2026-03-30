# Unit 003 計画: inception.mdサイズ最適化

## 概要

`prompts/package/prompts/inception.md` の行数が閾値（1000行）を超過している問題に対応する。

**現状**（計測: `wc -l prompts/package/prompts/inception.md`）:
- 行数: 1215行（閾値: 1000行）
- バイト数: 45545バイト（閾値: 150000バイト以内 ✓）

**パス構成の説明**:
- `prompts/package/`: スターターキットのソースコード（変更対象）
- `docs/aidlc/`: デプロイ先（`prompts/setup-prompt.md` 実行時に rsync でコピー）
- プロンプト内の参照は `docs/aidlc/` を使用（デプロイ後のパス）
- rsync時に `-a` オプションで実行可能属性が保持される（既存スクリプトと同様）

## 変更対象ファイル

| ファイル | 変更内容 |
|----------|----------|
| `prompts/package/prompts/inception.md` | サイズ削減 |
| `prompts/package/bin/suggest-version.sh` | 新規作成 |
| `prompts/package/bin/setup-branch.sh` | 新規作成 |
| `prompts/package/bin/migrate-backlog.sh` | 新規作成 |
| `prompts/package/guides/worktree-usage.md` | 新規作成 |

## 削減対象と見積もり

| 対象 | 現在行数 | 変更後 | 削減行数 | 対応方法 |
|------|---------|--------|---------|----------|
| AI-DLC手法の要約 | 19行 | 0行 | 19行 | 削除（`common/intro.md`と重複） |
| ステップ6: バージョン決定 | 70行 | 15行 | 55行 | `suggest-version.sh`へ移動 |
| ステップ7: ブランチ確認 | 189行 | 25行 | 164行 | `setup-branch.sh`へ移動 |
| ステップ10: バックログ移行 | 105行 | 10行 | 95行 | `migrate-backlog.sh`へ移動 |
| worktree補足説明 | 52行 | 3行 | 49行 | `worktree-usage.md`へ外部化 |

**合計削減**: 約382行 → 1215 - 382 = **833行**（閾値以下達成）

## 新規スクリプト仕様

### 1. `suggest-version.sh`

**目的**: サイクルバージョンの推測・提案

**機能**:
- ブランチ名からバージョン推測（`git branch --show-current` で取得、`cycle/vX.Y.Z` パターンを解析）
- 既存サイクルの一覧取得（`docs/cycles/v*` ディレクトリを `sort -V` で取得、最新を判定）
- 次バージョンの候補を提案（セマンティックバージョニングに基づく）

**出力形式**（機械読み取り前提、値がない場合は空文字）:
```text
branch_version:v1.12.1
latest_cycle:v1.12.0
suggested_patch:v1.12.1
suggested_minor:v1.13.0
suggested_major:v2.0.0
```

**値がない場合の例**:
```text
branch_version:
latest_cycle:
suggested_patch:v1.0.0
suggested_minor:v1.0.0
suggested_major:v1.0.0
```

**inception.mdでの記述（置き換え後）**:
```markdown
#### 6. サイクルバージョンの決定

```bash
docs/aidlc/bin/suggest-version.sh
```

AIが出力を解釈し、ユーザーに提案:
- `branch_version` が設定されている場合: そのバージョンを提案
- そうでない場合: `suggested_*` から選択肢を提示
```

### 2. `setup-branch.sh`

**目的**: ブランチ/worktree作成

**引数**:
- `$1`: サイクルバージョン（例: v1.12.1）
- `$2`: モード（`branch` または `worktree`）

**機能**:
- ブランチ存在確認（`git show-ref --verify`）
- ブランチ作成または切り替え（`git checkout -b` または `git checkout`）
- worktree作成（モードがworktreeの場合、`git worktree add`）

**worktreeパス決定ルール**:
- パス: `.worktree/cycle-{バージョン}`（例: `.worktree/cycle-v1.12.1`）
- ディレクトリが存在しない場合は `mkdir -p .worktree` で作成

**競合時の挙動**:
- ブランチが既に存在: `status:already_exists` を返し、既存ブランチに切り替え
- worktreeが既に存在: `status:already_exists` を返し、既存パスを `worktree_path` に出力
- 作成失敗: `status:error` を返し、`message` にエラー内容を出力（後始末は行わない）

**出力形式**:
```text
status:success
branch:cycle/v1.12.1
worktree_path:.worktree/cycle-v1.12.1
message:worktreeを作成しました
```

**inception.mdでの記述（置き換え後）**:
```markdown
#### 7. ブランチ確認【推奨】

AIが現在のブランチを確認し、main/masterの場合はユーザーに選択を求める:
1. worktreeを使用
2. ブランチを作成
3. 続行

選択に応じてスクリプトを実行:
```bash
# ブランチ作成の場合
docs/aidlc/bin/setup-branch.sh {{CYCLE}} branch

# worktree作成の場合
docs/aidlc/bin/setup-branch.sh {{CYCLE}} worktree
```
```

### 3. `migrate-backlog.sh`

**目的**: 旧形式バックログの移行

**オプション**:
- `--dry-run`: 実際の変更を行わず、移行予定の内容を表示
- `--no-delete`: 移行後も元ファイルを削除しない

**機能**:
- `docs/cycles/backlog.md` の存在確認
- 項目の解析と新形式ファイルへの変換
- 元ファイルの削除（`--no-delete` 指定時はスキップ）

**削除条件**:
- 全項目の移行が完了した場合のみ削除
- エラーが発生した場合は削除しない
- gitで履歴が残るためバックアップは不要

**確認フロー**:
- スクリプト自体は確認プロンプトを出さない（AIが事前にユーザーに確認）
- inception.md側で「移行を実行しますか？（Y/n）」と確認する指示を記載

**出力形式**:
```text
status:migrated
migrated_count:3
skipped_completed:1
skipped_duplicate:0
deleted:true
```

**status値**:
- `migrated`: 移行完了
- `no_file`: `docs/cycles/backlog.md` が存在しない
- `error`: エラー発生（`message` にエラー内容）

**inception.mdでの記述（置き換え後）**:
```markdown
#### 10. 旧形式バックログ移行（該当する場合）

> **DEPRECATED (v1.9.0)**: v2.0.0 で削除予定

```bash
docs/aidlc/bin/migrate-backlog.sh
```

- `status:no_file`: スキップ
- `status:migrated`: 移行完了を表示
```

## 実装計画

### Phase 1: 設計

1. ✓ スクリプト化対象の特定
2. ✓ 削減見積もり
3. ✓ スクリプト仕様の定義

### Phase 2: 実装

1. `suggest-version.sh` の作成
2. `setup-branch.sh` の作成
3. `migrate-backlog.sh` の作成
4. `worktree-usage.md` の作成
5. `inception.md` の修正
   - AI-DLC手法の要約を削除
   - ステップ6をスクリプト呼び出しに置き換え
   - ステップ7をスクリプト呼び出しに置き換え
   - ステップ10をスクリプト呼び出しに置き換え
   - worktree補足説明を参照リンクに置き換え
6. 動作確認（テストケース）:
   - `suggest-version.sh`: サイクルブランチから実行、mainから実行、サイクルなしから実行
   - `setup-branch.sh`: 新規ブランチ作成、既存ブランチ切り替え、worktree作成、既存worktree
   - `migrate-backlog.sh`: ファイルなし、dry-run、通常移行
7. 行数確認（目標: 1000行以下）

## 完了条件チェックリスト

- [ ] サイズチェック（`wc -l prompts/package/prompts/inception.md`）で1000行以下
- [ ] `suggest-version.sh` が正常動作する
- [ ] `setup-branch.sh` が正常動作する
- [ ] `migrate-backlog.sh` が正常動作する
- [ ] `worktree-usage.md` が作成され、inception.mdから参照されている
- [ ] プロンプトの機能に影響がない
- [ ] リンク切れがない
