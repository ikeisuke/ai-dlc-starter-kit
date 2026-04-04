# 論理設計: history.levelとdepth_level統合

## 概要

defaults.tomlに新キーを追加し旧キーを削除。preflight.mdでhistory_levelを派生コンテキスト変数として解決する。read-config.shは変更しない。

## コンポーネント構成

| ファイル | 変更内容 |
|---------|---------|
| `config/defaults.toml` | `[rules.depth_level]`に`history_level = ""`追加。`[rules.history]`セクション削除 |
| `steps/common/preflight.md` | 手順4: `rules.depth_level.history_level`追加、`rules.history.level`除去。解決ロジック追加 |
| `config/config.toml.example` | 新キーの説明・コメント追加 |

## 解決責務の集約

`history_level`はpreflight.mdでのみ解決される派生コンテキスト変数。read-config.shは汎用のキー解決APIとして維持し、フォールバックロジックは持たせない。

## preflight.mdでの解決ロジック

手順4の設定値取得後、以下を実行:

1. `rules.depth_level.history_level`の取得値を確認
2. 空文字でない → `history_level`コンテキスト変数に設定
3. 空文字 → 旧キーフォールバック:
   ```bash
   scripts/read-config.sh rules.history.level
   ```
   - exit 0かつ非空 → `history_level`に設定
   - exit 1（キー不在）→ depth_levelから自動導出
4. 自動導出マッピング適用

### defaults.tomlから旧キー削除の根拠

read-config.shは4階層マージ（defaults→home→project→local）で値を解決する。defaults.tomlに旧キーが残ると常にexit 0を返すため、「旧キーも不在なら自動導出」に到達できない。旧キーをdefaults.tomlから削除することで、ユーザーconfig.tomlに明示的に記載されている場合のみフォールバックが機能する。

## 後方互換性

- 旧config.tomlに`rules.history.level = "standard"`のみ → preflightフォールバックで読み取り
- 新旧両方指定 → 新キー優先（空文字でなければ）
- どちらも未指定 → depth_levelから自動導出
