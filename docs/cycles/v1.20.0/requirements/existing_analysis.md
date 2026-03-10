# 既存コードベース分析

## ディレクトリ構造・ファイル構成

今回の変更対象に関連する構成のみ記載。

```
prompts/package/
├── bin/
│   ├── suggest-version.sh      # バージョン提案
│   ├── init-cycle-dir.sh       # サイクルディレクトリ初期化
│   ├── setup-branch.sh         # ブランチ/worktree作成
│   ├── squash-unit.sh          # Unit完了時squash（1235行）
│   ├── aidlc-cycle-info.sh     # サイクル情報検出
│   ├── write-history.sh        # 履歴記録
│   └── post-merge-cleanup.sh   # マージ後クリーンアップ
├── prompts/
│   ├── inception.md            # Inception Phaseプロンプト
│   └── common/
│       └── commit-flow.md      # コミット/squashフロー定義
└── skills/
    ├── session-title/          # スキル例（シンプル）
    │   ├── SKILL.md
    │   └── bin/
    ├── reviewing-code/         # スキル例（外部ツール連携）
    │   ├── SKILL.md
    │   └── references/
    └── upgrading-aidlc/        # スキル例（複合フロー）
        └── bin/

bin/
└── post-merge-sync.sh          # マージ後同期（メインリポジトリ向け）

.claude/skills/                 # docs/aidlc/skills/ へのシンボリックリンク群
```

## アーキテクチャ・パターン

### サイクルパス構築パターン
- 全スクリプトが `docs/cycles/${version}` で動的にパス構築（根拠: init-cycle-dir.sh L265、write-history.sh L134）
- テンプレート変数 `{{CYCLE}}` をAIが解決してからスクリプトに渡す方式

### スキル定義パターン
- SKILL.md: YAML front matter（name, description, argument-hint）+ Markdown本文
- bin/: 実行スクリプト（オプション）
- references/: 参照ドキュメント（オプション）
- デュアルパス探索: `prompts/package/skills/` → `docs/aidlc/skills/` の順で検索
- `.claude/skills/` → `docs/aidlc/skills/` へのシンボリックリンク

### squash-unit.sh の設計
- 構造化出力: `key:value` 形式（squash:success, squash:error 等）
- 引数バリデーション: revsetインジェクション防止、パストラバーサル防止
- VCS抽象化: git/jj を `--vcs` で切り替え
- 自動検出: `--base` 省略時にコミットメッセージパターンから起点を推定

## 技術スタック

| 項目 | 値 | 根拠ファイル |
|------|-----|-------------|
| 言語 | Bash (POSIX互換シェルスクリプト) | prompts/package/bin/*.sh |
| 設定 | TOML (docs/aidlc.toml) | docs/aidlc.toml |
| VCS | git (jjは非推奨) | rules.md |
| CI | なし（GitHub Actions未使用） | .github/ |

## 依存関係

### 名前付きサイクル関連のスクリプト互換性

| スクリプト | 現状 | 制約箇所 | 対応要否 |
|-----------|------|---------|---------|
| suggest-version.sh | 非SemVer名を入力として受容 | L24: `^cycle/v(...)` ブランチパース、L34: `docs/cycles/v*/` ディレクトリスキャン | 要対応 |
| init-cycle-dir.sh | スラッシュを含む識別子を拒否 | L99-103: スラッシュ含有チェック（`*/*` で拒否） | 要対応 |
| setup-branch.sh | SemVerのみ | L137: `^v[0-9]+\.[0-9]+\.[0-9]+` | 要対応 |
| post-merge-cleanup.sh | SemVerのみ | L393: `^v[0-9]+\.[0-9]+\.[0-9]+` | 要対応 |
| aidlc-cycle-info.sh | SemVerのみ | L42: `^cycle/(v[0-9]+...)$`, L57: grep SemVerフィルタ | 要対応 |
| write-history.sh | 任意の識別子を受容 | なし | 不要 |

### squash-unit.sh の呼び出し元
- `commit-flow.md` のSquash統合フロー（5箇所）
  - Unit完了squash、Inception完了squash、retroactive squash（dry-run/実行/--from--to）
- 呼び出し手順: Writeツールでメッセージファイル作成 → squash-unit.sh実行 → 一時ファイル削除

## 特記事項

- 名前付きサイクルで `cycles/[name]/vX.X.X` 構造にする場合、既存の `docs/cycles/vX.X.X` とは異なるネストレベルになる。スクリプトの `docs/cycles/${version}` パターンを `docs/cycles/${name}/${version}` に拡張するか、`${cycle_path}` として一括管理するかの設計判断が必要
- `aidlc-cycle-info.sh` はブランチ名 `cycle/vX.X.X` からサイクルを検出する。`cycle/[name]/vX.X.X` の場合、名前とバージョンの両方を抽出するロジックが必要
- squash-unit.sh は既にスキル化に必要な要素（構造化出力、引数バリデーション、dry-run）を備えている。スキルは主にコンテキストからの引数自動解決を担う
