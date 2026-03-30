# Unit 001 計画: スキルリソース移設・重複削除

## 概要

`docs/aidlc/` から `skills/aidlc/` へのリソース移設、非スキルリソースの再配置、および重複ファイル・ディレクトリの削除を一括で行う。

## AIレビュー指摘への対応

| 指摘 | 重要度 | 対応方針 |
|------|--------|---------|
| #1: aidlc_dir設定やbin/check-*.shのデフォルトパスが壊れる | 高 | Unit 001はファイル移動・削除のみ。aidlc_dir設定はUnit 002、スクリプトデフォルトパスはUnit 003で更新。同一cycleブランチで連続実行されるためリリース前に整合する |
| #2: 一部ファイルに差分がある | 高 | 差分確認済み。skills/aidlc/ が正本。docs側は旧版のコピーのため差分を許容して削除する（詳細: 差分確認結果セクション参照） |
| #3: .agents/・.kiro/skills/ のシンボリックリンクが壊れる | 高 | 調査の結果、既に壊れているリンク（docs/aidlc/skills/ が存在しない）。本Unit内で正しいパスに修正する |
| #4: 履歴追跡の経路選択 | 中 | docs/aidlc/ からgit mvする。prompts/package/ は docs/aidlc/ のパッケージングコピーであり、どちらから移動しても等価。docs/aidlc/ はユーザー環境で直接参照されてきた経路のため、こちらの履歴を保持する |

### 差分確認結果

skills/aidlc/（正本）と docs/aidlc/（旧コピー）の差分:

| ファイル | 差分内容 | 判定 |
|---------|---------|------|
| templates/inception_progress_template.md | skills側が最新 | docs側を削除 |
| templates/index.md | skills側が最新 | docs側を削除 |
| templates/operations_progress_template.md | skills側が最新 | docs側を削除 |
| prompts/setup/02-generate-config.md | skills側が最新 | docs側を削除 |
| .github/ISSUE_TEMPLATE/backlog.yml | placeholder文言の軽微な差分 | docs側を削除（ルート.github/が正本） |
| lib/validate.sh | 完全一致 | docs側を削除 |

## 変更対象ファイル

### 移動（git mv）

| 移動元 | 移動先 | ファイル数 |
|--------|--------|-----------|
| `docs/aidlc/guides/*.md` | `skills/aidlc/guides/` | 18ファイル |
| `docs/aidlc/tests/*.sh` | `skills/aidlc/scripts/tests/` | 11ファイル |
| `docs/aidlc/kiro/` | `kiro/` | 1ファイル（agents/aidlc.json） |

### 削除（旧コピー���

| 対象 | 理由 |
|------|------|
| `docs/aidlc/prompts/` | `skills/aidlc/steps/` の旧コピー（1ファイル差分あり、skills側が正本） |
| `docs/aidlc/templates/` | `skills/aidlc/templates/` の旧コピー（3ファイル差分��り、skills��が正本） |
| `docs/aidlc/lib/validate.sh` | `skills/aidlc/scripts/lib/validate.sh` と完全一致 |
| `docs/aidlc/.github/` | ルー��� `.github/ISSUE_TEMPLATE/` の旧コピー（1ファイル軽微差分） |
| `docs/aidlc/` ディレクトリ���体 | 上記移動・削除完了後に空になる |
| `prompts/package/` | `docs/aidlc/` のパッケージングコピー（96ファイ���） |

### シンボリックリンク更新

| リンク | 現在のターゲット | 新ターゲット | 状態 |
|--------|----------------|-------------|------|
| `.kiro/agents/aidlc.json` | `../../docs/aidlc/kiro/agents/aidlc.json` | `../../kiro/agents/aidlc.json` | 壊れる（移動のため） |
| `.agents/skills/aidlc-setup` | `../../docs/aidlc/skills/aidlc-setup` | `../../skills/aidlc-setup` | 既に壊れている |
| `.agents/skills/reviewing-*` (4件) | `../../docs/aidlc/skills/reviewing-*` | `../../skills/reviewing-*` | 既に壊れている |
| `.agents/skills/squash-unit` | `../../docs/aidlc/skills/squash-unit` | `../../skills/squash-unit` | 既に壊れている |
| `.kiro/skills/aidlc-setup` | `../../docs/aidlc/skills/aidlc-setup` | `../../skills/aidlc-setup` | 既に壊れている |
| `.kiro/skills/reviewing-*` (4件) | `../../docs/aidlc/skills/reviewing-*` | `../../skills/reviewing-*` | 既に壊れている |
| `.kiro/skills/squash-unit` | `../../docs/aidlc/skills/squash-unit` | `../../skills/squash-unit` | 既に壊れている |

注: `.agents/skills/aidlc` と `.claude/skills/aidlc` は既に `../../skills/aidlc` を指しており変更不要。

## 実装計画

### Step 1: 移動先ディレクトリ作成

```bash
mkdir -p skills/aidlc/guides/
mkdir -p kiro/agents/
```

### Step 2: guides/ の移動

```bash
git mv docs/aidlc/guides/*.md skills/aidlc/guides/
```

### Step 3: tests/ の移動

```bash
git mv docs/aidlc/tests/*.sh skills/aidlc/scripts/tests/
```

既存の `test_wildcard_detection.sh` との重複はなし（確認済み）。

### Step 4: kiro/ の移動

```bash
git mv docs/aidlc/kiro/agents/aidlc.json kiro/agents/aidlc.json
```

### Step 5: シ��ボリックリンク一括更新

```bash
# .kiro/agents
ln -sf ../../kiro/agents/aidlc.json .kiro/agents/aidlc.json

# .agents/skills（既に壊れているリンクを修正）
ln -sf ../../skills/aidlc-setup .agents/skills/aidlc-setup
ln -sf ../../skills/reviewing-architecture .agents/skills/reviewing-architecture
ln -sf ../../skills/reviewing-code .agents/skills/reviewing-code
ln -sf ../../skills/reviewing-inception .agents/skills/reviewing-inception
ln -sf ../../skills/reviewing-security .agents/skills/reviewing-security
ln -sf ../../skills/squash-unit .agents/skills/squash-unit

# .kiro/skills（既に壊れているリンクを修正）
ln -sf ../../skills/aidlc-setup .kiro/skills/aidlc-setup
ln -sf ../../skills/reviewing-architecture .kiro/skills/reviewing-architecture
ln -sf ../../skills/reviewing-code .kiro/skills/reviewing-code
ln -sf ../../skills/reviewing-inception .kiro/skills/reviewing-inception
ln -sf ../../skills/reviewing-security .kiro/skills/reviewing-security
ln -sf ../../skills/squash-unit .kiro/skills/squash-unit
```

### Step 6: 重複ファイル・ディレクトリの削除

```bash
git rm -r docs/aidlc/prompts/
git rm -r docs/aidlc/templates/
git rm docs/aidlc/lib/validate.sh
git rm -r docs/aidlc/.github/
git rm -r prompts/package/
```

### Step 7: docs/aidlc/ ディレクトリの削除

残存ファイルがないことを確認後:

```bash
git rm -r docs/aidlc/
```

### Step 8: 動作確認

- `skills/aidlc/guides/` に18ファイ��存在確認
- `skills/aidlc/scripts/tests/` に12ファイル（既存1 + 移動11）存在確認
- `kiro/agents/aidlc.json` 存在確認
- 全シンボリックリンクが有効な先を指していること確認
- `docs/aidlc/` が存在しないことを確認
- `prompts/package/` が存在しないことを確認

## 完了条件チェックリスト

- [ ] `docs/aidlc/guides/` → `skills/aidlc/guides/` への移動完了
- [ ] `docs/aidlc/tests/` → `skills/aidlc/scripts/tests/` への移動完了
- [ ] `docs/aidlc/kiro/` → `kiro/` への移動完了
- [ ] `docs/aidlc/prompts/`, `docs/aidlc/templates/`, `docs/aidlc/lib/` の削除完了
- [ ] `docs/aidlc/.github/` の削除完了
- [ ] `prompts/package/` の削除完了
- [ ] `docs/aidlc/` ディレクトリ自体の削除完了
- [ ] `.kiro/agents/aidlc.json` シンボリ���クリンク更新完了
- [ ] `.agents/skills/` のシンボリックリンク修正完了（6件）
- [ ] `.kiro/skills/` のシンボリックリンク修���完了（6件）

## 注意事項

- `git mv` を��用して履歴追跡を維持
- ��ス参照の更新は行わ���い（Unit 002の責務）
- `prompts/setup/` 配下の変更は行わない（Unit 003の責務���
- `aidlc_dir` 設定の廃止は行わない（Unit 002の責務）
- `bin/check-*.sh` のデフォルトパス変更は行わな��（Unit 003の責務）
