# Unit 001 計画: Git関連設定キーの統合

## 概要

Git関連の設定キーが `rules.branch`, `rules.worktree`, `rules.unit_branch`, `rules.squash`, `rules.commit` の5セクションに分散している問題を解消し、`[rules.git]` セクションに統合する。

## 関連Issue

- #521

## 変更対象ファイル

### 1. defaults.toml（スキル側 + aidlc-setup側）

**変更内容**: `[rules.git]` セクションに新キーを追加。旧セクションは defaults.toml から除去し、フォールバックは `read-config.sh` のエイリアス解決で担保する。

| 旧キー | 新キー | デフォルト値 |
|--------|--------|------------|
| `rules.branch.mode` | `rules.git.branch_mode` | "ask" |
| `rules.unit_branch.enabled` | `rules.git.unit_branch_enabled` | false |
| `rules.squash.enabled` | `rules.git.squash_enabled` | false |
| `rules.commit.ai_author` | `rules.git.ai_author` | "" |
| `rules.commit.ai_author_auto_detect` | `rules.git.ai_author_auto_detect` | true |

> **廃止**: `rules.worktree.enabled` は `rules.git.branch_mode = "worktree"` で代替。エイリアス統合ではなく廃止扱い。

既存の `rules.git.commit_on_unit_complete` / `rules.git.commit_on_phase_complete` はそのまま維持。

### 2. read-config.sh

**変更内容**: 公開キー名を canonical key に正規化してから解決するエイリアス解決ロジック追加。

エイリアスマップ（双方向）:
- `rules.branch.mode` ↔ `rules.git.branch_mode`
- `rules.worktree.enabled` ↔ `rules.git.worktree_enabled`
- `rules.unit_branch.enabled` ↔ `rules.git.unit_branch_enabled`
- `rules.squash.enabled` ↔ `rules.git.squash_enabled`
- `rules.commit.ai_author` ↔ `rules.git.ai_author`
- `rules.commit.ai_author_auto_detect` ↔ `rules.git.ai_author_auto_detect`

canonical key（新キー）を優先読み取り → 不在時に旧キーを読み取り。旧キーで問い合わせた場合もcanonical keyに正規化してから解決。

### 3. preflight.md

**変更内容**: バッチ取得キーリスト更新

- `rules.squash.enabled` → `rules.git.squash_enabled`
- `rules.unit_branch.enabled` → `rules.git.unit_branch_enabled`
- コンテキスト変数名（`squash_enabled`, `unit_branch_enabled`）は変更なし
- 旧キーフォールバック解決ロジックの追記

### 4. ステップファイルの参照更新

| ファイル | 変更箇所 |
|---------|---------|
| `steps/inception/01-setup.md` | `rules.branch.mode` → `rules.git.branch_mode`, `rules.worktree.enabled` → `rules.git.worktree_enabled` |
| `steps/construction/01-setup.md` | `rules.unit_branch.enabled` → `rules.git.unit_branch_enabled` |
| `steps/common/commit-flow.md` | `rules.squash.enabled` → `rules.git.squash_enabled`, `rules.commit.ai_author` → `rules.git.ai_author` |

### 5. detect-missing-keys.sh

**変更内容**: 旧セクションを defaults.toml から除去するため、欠落検出は新キーのみを正本とする。スクリプト自体の変更は不要（defaults.toml のリーフキー列挙で自動対応）。

### 6. テンプレート・サンプル・ドキュメント更新

| ファイル | 変更内容 |
|---------|---------|
| `skills/aidlc-setup/templates/config.toml.template` | 新キー（`[rules.git]`）を正本として生成。旧セクションは除去 |
| `skills/aidlc/config/config.toml.example` | 新キー構成に更新 |
| `docs/configuration.md` | 設定リファレンスを新キーに更新。旧キーは「互換用エイリアス」として記載 |

### 7. aidlc-setup/config/defaults.toml 同期

スキル側 defaults.toml の変更を aidlc-setup 側にも反映。

## 完了条件チェックリスト

- [ ] `defaults.toml`（スキル側）に新キー定義追加、旧セクション除去
- [ ] `read-config.sh` にエイリアス解決ロジック追加
- [ ] `preflight.md` のバッチ取得キーリスト更新
- [ ] `inception/01-setup.md` の設定キー参照更新
- [ ] `construction/01-setup.md` の設定キー参照更新
- [ ] `common/commit-flow.md` の設定キー参照更新
- [ ] `aidlc-setup/config/defaults.toml` の同期
- [ ] `config.toml.template` の新キー構成更新
- [ ] `config.toml.example` の新キー構成更新
- [ ] `docs/configuration.md` の設定リファレンス更新
- [ ] 検証: 新キー問い合わせ + 旧config → 正常動作
- [ ] 検証: 旧キー問い合わせ + 新config → 正常動作
- [ ] 検証: 新旧混在config → 新キー優先
- [ ] 検証: `/aidlc setup` 生成直後 → 新キーのみ
- [ ] 検証: `detect-missing-keys.sh` で旧キーが欠落候補に出ないこと

## リスク

- **低**: エイリアス解決により後方互換性を維持。既存の `config.toml` は旧キーで定義されているが、`read-config.sh` のエイリアス解決で新キーとして正規化されるため影響なし
