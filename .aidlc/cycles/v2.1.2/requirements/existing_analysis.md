# 既存コードベース分析

## ディレクトリ構造・ファイル構成

変更対象となる主要ディレクトリ:

```
skills/aidlc/
├── steps/
│   ├── common/
│   │   ├── task-management.md      # タスクテンプレート定義
│   │   ├── context-reset.md        # 中断時のリセット対応
│   │   ├── session-continuity.md   # session-state.md生成
│   │   └── rules.md                # アップグレードチェック設定
│   ├── inception/
│   │   ├── 01-setup.md             # ステップ6: バージョン比較（変更対象）
│   │   ├── 02-preparation.md       # ステップ17-3: タスク作成、ステップ18: progress.md
│   │   └── 05-completion.md        # コンテキストリセット提示
│   ├── construction/
│   │   ├── 01-setup.md             # タスク作成（ステップ12）
│   │   └── 04-completion.md        # コンテキストリセット提示
│   └── operations/
│       ├── 01-setup.md             # タスク作成（ステップ10b）、progress.md（ステップ7）
│       └── 04-completion.md        # コンテキストリセット提示
├── scripts/
│   ├── env-info.sh                 # バージョン取得（starter_kit_version）
│   └── read-config.sh              # 設定読み込み
├── config/
│   └── defaults.toml               # デフォルト設定
└── version.txt                     # スキルバージョン

.aidlc/
└── rules.md                        # aidlc-setup同期カスタムワークフロー（廃止対象）
```

## アーキテクチャ・パターン

- **プロンプト駆動型**: バージョン比較ロジックはスクリプトではなくプロンプト（01-setup.md ステップ6）内でAIが実行
- **設定階層マージ**: defaults.toml → config.toml → config.local.toml の順でマージ（read-config.sh）
- **カスタムワークフロー**: `.aidlc/rules.md` にプロジェクト固有の追加処理を定義

## 技術スタック

| 項目 | 値 | 根拠ファイル |
|------|-----|-------------|
| 言語 | Bash (スクリプト), Markdown (プロンプト) | scripts/*.sh, steps/**/*.md |
| 設定管理 | TOML + dasel | config/defaults.toml, scripts/read-config.sh |
| バージョン管理 | セマンティックバージョニング | scripts/suggest-version.sh |

## 依存関係

### バージョン比較の現在のデータフロー（2点間）
1. リモート: `curl` → GitHub main/version.txt
2. ローカル設定: `read-config.sh` → .aidlc/config.toml の starter_kit_version
3. 比較: AIがプロンプト内で判定（LATEST > CURRENT）

### 三角モデルで追加が必要なデータソース
- インストール済みスキル: プラグインキャッシュ内の version.txt（パス解決が必要）

### 変更対象ファイル一覧

| ファイル | 変更内容 |
|---------|---------|
| `steps/inception/01-setup.md` | ステップ6: 三角モデル比較ロジック実装 |
| `steps/inception/02-preparation.md` | ステップ17-3→Part 1直後に移動、ステップ18→init-cycle-dir直後に移動 |
| `steps/inception/05-completion.md` | 対応内容サマリ追加 |
| `steps/construction/01-setup.md` | タスク作成タイミング前倒し |
| `steps/construction/04-completion.md` | 対応内容サマリ追加 |
| `steps/operations/01-setup.md` | タスク作成タイミング前倒し |
| `steps/operations/04-completion.md` | 対応内容サマリ追加 |
| `steps/common/task-management.md` | テンプレート更新（タイミング説明修正） |
| `.aidlc/rules.md` | aidlc-setup同期カスタムワークフロー削除 |

## 特記事項

- バージョン比較はプロンプト駆動（スクリプトではない）のため、ステップファイルの修正で対応可能
- インストール済みスキルのバージョンは `skills/aidlc/version.txt` に存在するが、プラグインキャッシュ経由のパス解決方法を設計する必要あり
- aidlc-setup同期はメタ開発リポジトリ固有のカスタムワークフローで、外部プロジェクトには影響なし
