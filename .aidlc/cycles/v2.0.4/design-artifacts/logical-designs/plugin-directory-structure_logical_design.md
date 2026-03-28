# 論理設計: プラグインディレクトリ構造構築

## 概要

正本（`skills/aidlc/steps/`）から配布パッケージ（`prompts/package/prompts/`）への一方向同期を確立し、旧モノリシックパス参照を更新する。

**重要**: このドキュメントでは実装コードは書きません。

## スコープ

### In Scope（Unit 001）

- 正本→ミラー→利用側の同期経路確立（ステップツリー + 付帯設定ファイル）
- 旧モノリシックパス参照の棚卸しと更新（配布物・ガイド・セットアッププロンプト全体）
- marketplace.json のバージョン更新

### Out of Scope

- SKILL.md の意味変更・ARGUMENTSパーシング仕様変更 → Unit 002
- v1残存資産の全面削除（rsync処理本体、defaults.tomlパス修正、スターターキットパス判定）→ Unit 003
- レビュー系スキルの仕様変更 → 対象外

## コンポーネント構成

### 1. 同期コンポーネント（SyncToDistribution）

**責務**: `skills/aidlc/steps/` → `prompts/package/prompts/` の一方向コピー

**手順**:

1. `prompts/package/prompts/` から旧モノリシックファイルを削除:
   - `construction.md`, `inception.md`, `operations.md`, `operations-release.md`, `setup.md`
2. `skills/aidlc/steps/` のディレクトリ構造をミラーコピー:
   - `common/` → `prompts/package/prompts/common/`（差分のみ: task-management.md 追加）
   - `construction/` → `prompts/package/prompts/construction/`
   - `inception/` → `prompts/package/prompts/inception/`
   - `operations/` → `prompts/package/prompts/operations/`
   - `setup/` → `prompts/package/prompts/setup/`
   - `migrate/` → `prompts/package/prompts/migrate/`（新規ディレクトリ）
3. 付帯設定ファイルのコピー（ステップツリーとは別管理）:
   - `skills/aidlc/AGENTS.md` → `prompts/package/prompts/AGENTS.md`
   - `skills/aidlc/CLAUDE.md` → `prompts/package/prompts/CLAUDE.md`

**コピー方式**: ステップツリーは `rsync -a --delete` で各サブディレクトリを同期（ファイル追加・削除の両方を反映）。付帯設定ファイルは個別コピー。

### 2. 配布同期コンポーネント（SyncToDeployed）

**責務**: `prompts/package/` → `docs/aidlc/` の同期

**手順**:

1. **必須**: `prompts/bin/sync-package.sh --delete` を実行（`--delete` は必須。削除伝播なしではミラー整合性が崩れるため）
2. `--delete` オプションが未実装の場合: rsync を直接使用して `--delete` 付きで同期
3. 検証: `docs/aidlc/prompts/` から旧モノリシックファイルが削除されていること

### 3. パス参照更新コンポーネント（PathReferenceUpdater）

**責務**: 旧モノリシックパス参照を新モジュラーパスに更新

**スキャン対象ディレクトリ**（配布物・利用者向け参照を持つ全ファイル）:

- `prompts/package/guides/` - 配布パッケージのガイド群
- `prompts/package/prompts/` - 配布パッケージのプロンプト群
- `prompts/setup-prompt.md` - セットアッププロンプト
- `README.md` - リポジトリルートのREADME
- `docs/aidlc/guides/` - sync-package.sh で prompts/package/guides/ から自動反映

**対象ファイルと変更内容**:

#### prompts/package/guides/glossary.md

旧パス参照を `/aidlc <phase>` コマンドに更新:

| 旧参照 | 新参照 |
|--------|--------|
| `prompts/construction.md` | `/aidlc construction`（`steps/construction/`） |
| `prompts/inception.md` | `/aidlc inception`（`steps/inception/`） |
| `prompts/operations.md` | `/aidlc operations`（`steps/operations/`） |

#### prompts/package/prompts/operations-release.md → operations/operations-release.md

旧参照を新パスに更新:

| 旧参照 | 新参照 |
|--------|--------|
| `prompts/package/prompts/operations.md` | `steps/operations/01-setup.md`（またはスキル環境では `/aidlc operations`） |

#### prompts/setup-prompt.md

旧参照を新パスに更新:

| 旧参照 | 新参照 |
|--------|--------|
| `package/prompts/inception.md` | `/aidlc inception`（スキル対応環境）/ `package/prompts/inception/01-setup.md` ～ `05-completion.md`（非スキル環境） |
| `prompts/inception.md` 等のファイル一覧 | `prompts/inception/`, `prompts/construction/`, `prompts/operations/`, `prompts/setup/` のディレクトリ構造に更新 |

#### docs/aidlc/guides/ は sync-package.sh で自動反映

`prompts/package/guides/` を修正すれば同期で反映されるため、直接編集不要。

### 4. マニフェスト更新コンポーネント

**責務**: `.claude-plugin/marketplace.json` のバージョン更新

**変更内容**: `"version": "1.22.1"` → `"version": "2.0.4"`

## 実行順序

```
1. 旧パス参照の棚卸し（確認のみ）         ← 上記で完了済み
2. prompts/package/prompts/ のモジュラー化  ← SyncToDistribution
3. 旧パス参照の更新                        ← PathReferenceUpdater
4. marketplace.json のバージョン更新        ← マニフェスト更新
5. docs/aidlc/ の同期                      ← SyncToDeployed
6. 差分確認・検証                           ← validateSync
```

**順序の根拠**:
- ステップ2で構造変更を先に行い、ステップ3でパス参照を修正（構造確定後に参照先を更新するため）
- ステップ5のsync-package.shはステップ2,3の変更がすべて完了してから実行（1回の同期で完了させるため）

## 検証計画

### ステップツリーのミラー一致検証

1. **構造検証**: `diff -rq skills/aidlc/steps/ prompts/package/prompts/` でステップツリー部分（common/, construction/, inception/, operations/, setup/, migrate/）の差分がないことを確認
2. **旧ファイル削除検証**: `prompts/package/prompts/` に旧モノリシックファイル（construction.md, inception.md, operations.md, operations-release.md, setup.md）が存在しないこと

### 付帯設定ファイルの同期確認

3. **設定ファイル検証**: `prompts/package/prompts/AGENTS.md` と `skills/aidlc/AGENTS.md`、`prompts/package/prompts/CLAUDE.md` と `skills/aidlc/CLAUDE.md` が一致すること

### パス参照・同期検証

4. **パス参照検証**: `grep -r 'prompts/(construction|inception|operations|setup)\.md'` で旧パス参照が残っていないこと（migration-v1-to-v2.md の説明文を除く）
5. **同期検証**: `docs/aidlc/prompts/` の構造が `prompts/package/prompts/` と一致すること
