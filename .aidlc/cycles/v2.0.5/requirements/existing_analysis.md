# 既存コードベース分析

## ディレクトリ構造・ファイル構成

v2.0.5スコープに関連するディレクトリ:

```
.
├── .claude/skills/        ← シンボリックリンク群（→ skills/）
│   ├── aidlc -> ../../skills/aidlc
│   ├── aidlc-setup -> ../../skills/aidlc-setup
│   ├── reviewing-* -> ../../skills/reviewing-*
│   └── squash-unit -> ../../skills/squash-unit
├── docs/aidlc/            ← v1残存（削除対象）
│   ├── guides/            ← 18ファイル（skills/に移動対象）
│   ├── prompts/           ← steps/と重複（削除対象）
│   ├── templates/         ← templates/と重複（削除対象）
│   ├── lib/validate.sh    ← scripts/lib/と重複（削除対象）
│   ├── tests/             ← 11テストファイル（移動対象）
│   └── kiro/              ← Kiro CLI設定（ルートに移動対象）
├── prompts/               ← v1セットアップインフラ（整理対象）
│   ├── setup-prompt.md    ← v1エントリポイント（誘導に簡略化）
│   ├── bin/sync-package.sh← rsync同期（削除対象）
│   ├── setup/             ← v1パスハードコード（更新対象）
│   ├── package/           ← v1パッケージング（確認要）
│   └── dev/, poc/         ← 開発用（影響なし）
├── skills/                ← プラグイン実体（正本）
│   └── aidlc/
│       ├── steps/         ← ステップファイル（正本）
│       ├── templates/     ← テンプレート（正本）
│       ├── scripts/       ← スクリプト（正本）
│       ├── config/        ← 設定（正本）
│       └── (guides/ なし) ← ここに移動する
└── .aidlc/config.toml     ← aidlc_dir=docs/aidlc（廃止対象）
```

## アーキテクチャ・パターン

- **プラグインモデル**: `.claude/skills/` のシンボリックリンクが `skills/` の実体を指す構造。Claude Codeがスキルを発見する仕組み
- **v1残存**: `docs/aidlc/` はv1時代にrsyncでコピーされていたファイル群。v2では `skills/aidlc/steps/` が正本だが、コピーが残存
- **パス参照**: ステップファイル内で `{{aidlc_dir}}/guides/...` 変数でガイドを参照。`aidlc_dir` は `config.toml` の設定値

## 技術スタック

| 項目 | 値 | 根拠ファイル |
|------|-----|-------------|
| 言語 | Bash, Markdown | scripts/*.sh, steps/**/*.md |
| 設定 | TOML | .aidlc/config.toml |
| パッケージ管理 | dasel (TOML操作) | scripts/read-config.sh |
| CI | GitHub Actions | .github/workflows/ |

## 依存関係

- `skills/aidlc/steps/*.md` → `{{aidlc_dir}}/guides/*.md` （パス参照、廃止対象）
- `skills/aidlc/scripts/*.sh` → `skills/aidlc/scripts/lib/validate.sh` （内部依存、維持）
- `.claude/skills/*` → `skills/*` （シンボリックリンク、維持）
- `prompts/setup/` → `docs/aidlc.toml` （v1パス、更新対象）

## 特記事項

- `prompts/package/` はv1時代のパッケージングディレクトリで、`docs/aidlc/` と同内容のコピー元。同様に整理が必要だが、影響範囲が大きいためUnit設計時に精査する
- `docs/aidlc/tests/` の11ファイルは `prompts/setup/` 関連のテストと `validate.sh` 関連のテストが混在。移動時に分類が必要
