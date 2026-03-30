# Unit 003 計画: upgrading-aidlcスキル簡略化

## 概要

`upgrading-aidlc` スキルの `SKILL.md` から、ローカル探索ステップ（`prompts/setup-prompt.md` の存在確認）を削除し、常に `docs/aidlc.toml` の `starter_kit_repo` 経由でパスを解決するフローに簡略化する。

## 変更対象ファイル

| ファイル | 変更内容 |
|---------|---------|
| `prompts/package/skills/upgrading-aidlc/SKILL.md` | ローカル探索ステップの削除、フロー説明の簡略化 |

## 実装計画

### Phase 1: 設計

このUnitは純粋なMarkdownテキスト編集（削除・整理）のため、ドメインモデル・論理設計は該当しない。

**現在のフロー（2ステップ）**:
1. `prompts/setup-prompt.md` の存在を確認する（1回のみ）
2. 存在する場合: そのまま読み込む
3. 存在しない場合: `docs/aidlc.toml` + `ghq root` 経由でパスを解決

**変更後のフロー**:
1. `docs/aidlc.toml` の `[project]` セクションから `starter_kit_repo` を取得し、`ghq root` 経由でパスを解決する
2. 解決したパスのファイルを読み込む

**具体的な変更点**:
- ステップ1（ローカル確認）とステップ2（存在する場合の読み込み指示）を削除
- ステップ3（存在しない場合）の条件分岐を解除し、メインフローとする
- 「重要」注記の「2ステップ（ローカル確認 → toml経由解決）」をtoml経由解決のみに更新
- フロー説明テキストの整合性を維持

### Phase 2: 実装

1. `prompts/package/skills/upgrading-aidlc/SKILL.md` を編集
2. テスト: 変更後のSKILL.mdの内容が論理的に整合していることを確認

## 完了条件チェックリスト

- [ ] `SKILL.md` からローカル探索ステップ（ステップ1）が削除されている
- [ ] スターターキットリポジトリ解決（旧ステップ3）のみ残っている
- [ ] フロー説明テキストの整合性が維持されている
