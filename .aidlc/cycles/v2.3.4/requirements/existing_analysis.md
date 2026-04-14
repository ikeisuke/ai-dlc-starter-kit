# 既存コードベース分析

## ディレクトリ構造・ファイル構成

```
skills/aidlc/
├── SKILL.md                    # メインオーケストレータースキル
├── version.txt                 # スキルバージョン (2.3.3)
├── config/
│   └── defaults.toml           # デフォルト設定値
├── steps/
│   ├── common/                 # 全フェーズ共通
│   │   ├── preflight.md        # プリフライトチェック ← #569, #570 修正対象
│   │   ├── rules-core.md       # 共通ルール
│   │   ├── rules-automation.md # セミオートゲート仕様
│   │   └── ...
│   ├── inception/
│   │   ├── 01-setup.md         # セットアップ ← #570 修正対象
│   │   └── ...
│   ├── construction/
│   └── operations/             # ← #571 調査対象
│       ├── index.md
│       ├── 01-setup.md
│       ├── 02-deploy.md
│       ├── 03-release.md       # verify-git でリモート同期チェック実装済み
│       └── 04-completion.md
├── scripts/
│   ├── operations-release.sh   # verify-git サブコマンド
│   └── ...
└── templates/
```

## アーキテクチャ・パターン

- **スキルプラグイン構成**: `skills/aidlc/` 配下にスキルリソースを集約
- **フェーズインデックスパターン**: 各フェーズに `index.md` を持ち、分岐ロジック・チェックポイント・ステップ読み込み契約を一元管理
- **Materialized Binding**: `phase-recovery-spec.md` の規範仕様をフェーズインデックスに具象化

## 技術スタック

| 項目 | 値 | 根拠ファイル |
|------|-----|-------------|
| 言語 | Bash, Markdown | scripts/*.sh, steps/**/*.md |
| 設定形式 | TOML | .aidlc/config.toml, config/defaults.toml |
| CLIツール | gh, dasel, codex | scripts/env-info.sh |

## 依存関係

- SKILL.md → steps/common/*.md → steps/{phase}/*.md（ステップ読み込み契約経由）
- steps/common/preflight.md → scripts/read-config.sh, scripts/env-info.sh
- steps/operations/03-release.md → scripts/operations-release.sh（verify-git）

## 特記事項

### #569: defaults.toml チェックの現状

`steps/common/preflight.md` の以下の箇所が修正対象:
- 117行目: `config/defaults.toml` 不在時の警告テーブル行。存在チェックコマンドが明記されておらず、AIエージェントがプロジェクトルート相対で `ls config/defaults.toml` と実行してしまう
- 131行目: 結果提示テンプレートの defaults.toml 行

### #570: 投げっぱなしパターンの現状

1. **`steps/inception/01-setup.md` ステップ9-3**: `behind` 状態で推奨メッセージを表示するがユーザー応答フローがない
2. **`steps/common/preflight.md`**: 「続行可能（警告N件）」表示後に自動継続。警告内容確認の対話フローが不在
3. **SKILL.md「実行判断・対話規約」**: 推奨・提案メッセージの分類（ゲート承認/ユーザー選択/情報提示のどれか）が未定義

### #571: Operations Phase のリモート同期チェック現状

- **ステップ7（03-release.md）**: `operations-release.sh verify-git` でリモート同期チェックが**実装済み**。`remote-sync` の結果を出力
- **ステップ1（01-setup.md）**: Operations Phase 開始時のリモート同期チェックは**未実装**
- **ステップ5（04-completion.md）**: PRマージ後に `git pull origin main` で最新取得

**調査結論**: リモート同期チェックはリリース直前（ステップ7）にのみ存在し、Operations Phase 開始時に欠落。開始時に古い状態で作業を進め、リリース直前で初めて差分に気づくリスクがある
