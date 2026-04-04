# 既存コードベース分析

## ディレクトリ構造・ファイル構成

設定関連ファイルの構成:

```
skills/aidlc/
  config/defaults.toml          # デフォルト設定（71行）
  scripts/read-config.sh        # 設定読み取りスクリプト（318行）
  steps/common/preflight.md     # プリフライトチェック（218行）
  steps/inception/01-setup.md   # Inceptionセットアップ（313行）
.aidlc/
  config.toml                   # プロジェクト設定（186行）
  config.local.toml             # 個人設定（gitignore対象）
```

## アーキテクチャ・パターン

### 設定読み取りの4階層マージ
read-config.sh（L18-22）で以下の優先度順にマージ:
1. defaults.toml（スキル内）
2. ~/.aidlc/config.toml（ユーザーグローバル）
3. .aidlc/config.toml（プロジェクト）
4. .aidlc/config.local.toml（個人ローカル）

### フォールバックパターン
version_check ↔ upgrade_check の互換ロジック（01-setup.md L100-111）が参考実装として存在。新キー → 旧キーの順で読み取り、両方失敗時にデフォルト値を使用。

## 技術スタック

| 項目 | 値 | 根拠ファイル |
|------|-----|-------------|
| 設定ファイル形式 | TOML | config.toml, defaults.toml |
| 設定読み取り | dasel（CLI） | read-config.sh |
| スクリプト言語 | Bash | scripts/*.sh |

## 依存関係

### スコープ対象キーの参照マップ

| 設定キー | defaults.toml | config.toml | 読み取り箇所 | 参照プロンプト | スコープ |
|---------|---|---|---|---|---|
| rules.preflight.enabled | L39 | L175 | preflight.md L61,88 | inception/setup | #520-1 |
| rules.preflight.checks | L40 | L180 | preflight.md L61,89 | inception/setup | #520-1 |
| rules.cycle.named_enabled | なし | L126(コメント) | 01-setup.md L187 | inception/setup ステップ7 | #520-2 |
| rules.cycle.mode | L57 | L126(コメント) | 01-setup.md L203 | inception/setup ステップ7 | #520-2 |
| rules.size_check.* | L46 | L135-147 | 直接参照なし（bin/check-size.shで使用） | - | #520-3 |
| rules.history.level | L20 | L91 | preflight.md L61,86 | preflight 手順4-6 | #522 |
| rules.linting.markdown_lint | L43 | L110 | preflight.md L61,84 | preflight 手順4-6 | #523 |
| cycles_git_tracked | なし | なし | 未実装 | - | #434 |

## 特記事項

- **preflight設定（#520-1）**: 削除後はpreflight.mdのオプションチェック分岐ロジックを簡素化する必要がある（enabled/checksの読み取り・分岐を除去し、常時実行化）
- **named_enabled（#520-2）**: config.tomlではコメントアウト状態。cycle.modeの3値（default/named/ask）のみで制御する方式に移行可能
- **size_check（#520-3）**: defaults.tomlから除外後もconfig.tomlに直接記載すればread-config.shで読み取り可能（メタ開発専用）
- **旧キーフォールバック（#522, #523）**: read-config.sh内での実装が必要。version_check/upgrade_checkの互換ロジックが参考実装
- **cycles_git_tracked（#434）**: 設定キー・参照処理共に新規実装が必要。aidlc-setupスキルでの案内ロジック追加
