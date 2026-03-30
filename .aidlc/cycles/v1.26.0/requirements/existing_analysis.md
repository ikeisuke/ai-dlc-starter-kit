# 既存コードベース分析

## ディレクトリ構造・ファイル構成

```
ai-dlc-starter-kit/
├── docs/
│   ├── aidlc/
│   │   ├── bin/              # ユーティリティスクリプト群（30種）
│   │   ├── prompts/          # フェーズプロンプト・共有ルール（rsyncコピー）
│   │   │   ├── common/       # 共通ルール（rules.md, preflight.md等）
│   │   │   ├── inception.md
│   │   │   ├── construction.md
│   │   │   └── operations.md
│   │   └── templates/        # 成果物テンプレート
│   ├── cycles/               # サイクル別成果物
│   ├── aidlc.toml            # プロジェクト中央設定
│   └── aidlc.local.toml      # ローカル上書き設定（.gitignore）
├── prompts/
│   └── package/              # プロンプト正本（docs/aidlc/の同期元）
│       ├── prompts/
│       │   ├── common/
│       │   │   ├── rules.md  # ★変更対象: バリデーションルール追加
│       │   │   └── preflight.md # ★変更対象: チェック項目設定化
│       │   └── construction.md  # ★変更対象: Self-Healing設定化
│       └── bin/
└── bin/                      # プロジェクト固有スクリプト
```

## アーキテクチャ・パターン

- **3段階フェーズモデル**: Inception → Construction → Operations（根拠: AGENTS.md）
- **SSOT原則**: `common/rules.md` が開発ルールの唯一の正本。各フェーズプロンプトは参照のみ（根拠: rules.md内のコメント）
- **設定階層マージ**: `read-config.sh` が aidlc.toml → aidlc.local.toml の優先度でマージ（根拠: read-config.sh実装）
- **プロンプト同期パターン**: `prompts/package/` が正本、`docs/aidlc/` はrsyncコピー。直接編集禁止（根拠: rules.md）
- **コンテキスト変数フロー**: preflight.md で設定値を取得 → 各フェーズプロンプトで参照（根拠: preflight.md）

## 技術スタック

| 項目 | 値 | 根拠ファイル |
|------|-----|-------------|
| 言語 | Markdown（プロンプト）、Bash（スクリプト） | prompts/package/prompts/*.md, docs/aidlc/bin/*.sh |
| 設定形式 | TOML | docs/aidlc.toml |
| TOML解析 | dasel v2/v3 | docs/aidlc/bin/read-config.sh |
| VCS | Git | .git |
| Issue管理 | GitHub CLI (gh) | construction.md バックログ登録処理 |

## 依存関係

### 変更対象ファイル間の依存

```
docs/aidlc.toml（設定追加先）
    ↓ [read-config.sh経由で読取]
preflight.md（チェック項目設定化 #323）
    ↓ [コンテキスト変数生成]
construction.md（Self-Healing設定化 #322、バリデーション強化 #315）
    ↓ [backlog_mode参照]
rules.md（バリデーションルール追加 #315）
```

### Issue別の影響ファイル

| Issue | 正本（編集対象） | 参照元 |
|-------|----------------|--------|
| #315 | prompts/package/prompts/common/rules.md | construction.md, inception.md |
| #323 | prompts/package/prompts/common/preflight.md, docs/aidlc.toml | 全フェーズプロンプト |
| #322 | prompts/package/prompts/construction.md, docs/aidlc.toml | preflight.md |

### 循環依存の有無

循環依存なし。設定読取は一方向（aidlc.toml → read-config.sh → preflight.md → フェーズプロンプト）。

## 特記事項

- `docs/aidlc/` は直接編集禁止。変更は `prompts/package/` を編集し、Operations Phase で rsync 同期
- Self-Healing の "最大3回" は construction.md の複数箇所（L555, L569, L577, L596等）にハードコード
- preflight.md の設定キー8個（L66-74）もハードコード。バッチモード（`--keys`）での一括取得は read-config.sh が既にサポート
- backlog_mode のバリデーションは rules.md のバックログセクション（L526-548）に暗黙的な制約のみ。排他的制約の明示が必要
