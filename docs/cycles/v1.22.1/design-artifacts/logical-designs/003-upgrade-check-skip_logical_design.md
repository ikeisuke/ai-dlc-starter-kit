# 論理設計: アップグレードチェックスキップ機能

## 変更1: docs/aidlc.toml

`[rules.feedback]` セクションの後に `[rules.upgrade_check]` セクションを追加:

```toml
[rules.upgrade_check]
# アップグレードチェック設定（v1.22.1で追加）
# enabled: true | false - Inception Phase開始時のバージョン確認を実行するか（デフォルト: true）
# - true: curlでスターターキットの最新バージョンを確認（従来の動作）
# - false: バージョン確認をスキップ（オフライン環境やCI利用時に有用）
enabled = true
```

## 変更2: rules.md

Depth Level仕様セクションの前（または適切な位置）に「アップグレードチェック設定」セクションを追加:

- 設定キー: `rules.upgrade_check.enabled`
- 読み込みコマンド: `docs/aidlc/bin/read-config.sh rules.upgrade_check.enabled --default "true"`
- 有効値: `true` / `false`
- デフォルト: `true`
- 読み取り失敗時（終了コード2）: 警告表示し `true` にフォールバック
- 非boolean値: 警告表示し `true` にフォールバック
- 警告文言パターン: 既存の `rules.cycle.mode` パターンと統一

## 変更3: inception.md

ステップ5（「スターターキットバージョン確認」）の冒頭に条件分岐を追加:

```markdown
**アップグレードチェック設定の確認**:

`rules.md` の「アップグレードチェック設定」セクションに従い、設定値を取得する。

`false` の場合:
- 以下を表示し、ステップ5.5（サイクルモード確認）へ進む:
  ```text
  アップグレードチェックはスキップされました（rules.upgrade_check.enabled = false）。
  ```

`true` の場合（デフォルト）:
- 以下の従来処理を実行
```
