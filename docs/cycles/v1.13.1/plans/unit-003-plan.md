# Unit 003 計画: setup-prompt.md関連の変更

## 概要

setup-prompt.mdを改善し、旧形式バックログ移行をInception Phaseから移動し、アップグレード完了メッセージを更新する。

## 変更対象ファイル

| ファイル | 変更内容 |
|----------|----------|
| `prompts/package/prompts/inception.md` | 旧形式バックログ移行ステップ（ステップ10）を削除 |
| `prompts/setup-prompt.md` | アップグレードセクションに移行処理を追加 + 完了メッセージを「start inception」に更新 |

## 実装計画

### Phase 1: 設計

このUnitはドキュメント変更のみのため、設計フェーズは簡略化して進める。

- ドメインモデル設計: 省略（プロンプト修正のみのため）
- 論理設計: 省略（プロンプト修正のみのため）

### Phase 2: 実装

#### ステップ1: inception.mdの変更

`prompts/package/prompts/inception.md` から以下のセクションを削除:
- 「#### 10. 旧形式バックログ移行（該当する場合）」セクション全体（行373-397付近）
- DEPRECATEDコメントと移行スクリプト実行の説明

#### ステップ2: setup-prompt.mdの変更

1. **旧形式バックログ移行の追加**
   - セクション7.5「廃止設定の移行」の後に、セクション7.6「旧形式バックログ移行」を新設
   - inception.mdから移動した内容を適切に調整して配置

2. **完了メッセージの更新**
   - 「アップグレードの場合」セクション（行1447-1465付近）の完了メッセージを更新
   - 「start setup」を「start inception」に変更

## 完了条件チェックリスト

- [ ] inception.mdから旧形式バックログ移行ステップを削除
- [ ] setup-prompt.mdのアップグレードセクションに移行処理を追加
- [ ] setup-prompt.mdの完了メッセージを「start inception」に更新

## 関連Issue

- #163: 旧形式バックログ移行のアップグレード処理への移動
- #160: アップグレード完了メッセージの更新

## 技術的考慮事項

- `docs/aidlc/` 配下は `prompts/package/` の rsync コピーであるため、編集は `prompts/package/` で行う
- `prompts/setup-prompt.md` は同期対象外（ルート直下のセットアップ専用ファイル）
- DEPRECATED注記は維持（v2.0.0で削除予定）
