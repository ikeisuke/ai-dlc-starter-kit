# 計画: Unit 002 - history.levelとdepth_level統合

## スコープとIntent要件の対応

本UnitはIntent全体のうち **#522（rules.historyとrules.depth_levelの統合）** のみを担当する。

## 関連Issue

- #522

## 変更対象ファイル

| ファイル | 変更内容 |
|---------|---------|
| `config/defaults.toml` | `[rules.depth_level]`に`history_level = ""`追加。`[rules.history]`セクションを削除 |
| `steps/common/preflight.md` | 手順4の設定値取得に`rules.depth_level.history_level`追加、`rules.history.level`除去。取得後にhistory_level解決ロジック（派生コンテキスト変数）を追加 |
| `config/config.toml.example` | 新キーの説明追加、旧キーのコメント更新 |

## 互換ポリシー

| 対象キー | 分類 | 互換ポリシー |
|---------|------|------------|
| `rules.history.level` → `rules.depth_level.history_level` | renamed | defaults.tomlから旧キー削除。ユーザーのconfig.tomlに旧キーが残っている場合のみフォールバック読み取り（preflight.md内で解決） |

## 解決責務

`history_level`はpreflight.mdでのみ解決される**派生コンテキスト変数**。read-config.shは変更しない。

### 解決フロー（preflight.md内）

1. `rules.depth_level.history_level`を`--keys`バッチで取得
2. 取得値が空文字でない → `history_level`に設定（明示オーバーライド）
3. 取得値が空文字 → `rules.history.level`を個別に取得（旧キーフォールバック）
   - 値あり（exit 0かつ非空）→ `history_level`に設定
   - 値なし（exit 1=キー不在）→ depth_levelから自動導出
4. 自動導出マッピング: minimal→minimal、standard→standard、comprehensive→detailed

### defaults.tomlから旧キー削除の理由

defaults.tomlに旧キー`rules.history.level`が残ると、read-config.shの4階層マージで常にexit 0（値: standard）を返すため、「旧キーも不在なら自動導出」の分岐に到達できない。defaults.tomlから削除することで、ユーザーがconfig.tomlに明示的に旧キーを設定した場合のみフォールバックが機能する。

## 完了条件チェックリスト

- [ ] defaults.tomlに`rules.depth_level.history_level = ""`が追加されていること
- [ ] defaults.tomlから`[rules.history]`セクションが削除されていること
- [ ] preflight.mdでhistory_level解決ロジックが実装されていること（派生コンテキスト変数）
- [ ] 旧キー`rules.history.level`がユーザーconfig.tomlに残っている場合に正常に読み取れること
- [ ] 新キーに明示値が設定されている場合、その値が優先されること
- [ ] depth_level=minimal/standard/comprehensiveの各値で正しいhistory_levelが導出されること
