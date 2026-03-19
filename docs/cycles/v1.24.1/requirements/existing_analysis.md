# 既存コードベース分析

## ディレクトリ構造・ファイル構成

```
prompts/
├── package/              # スターターキット本体（正本）
│   ├── bin/              # シェルスクリプト
│   ├── prompts/          # フェーズプロンプト・共通プロンプト
│   │   ├── common/       # 共通ルール・フロー
│   │   ├── inception.md
│   │   ├── construction.md
│   │   └── operations-release.md
│   ├── templates/        # テンプレート
│   └── skills/           # スキル定義
│       └── aidlc-setup/  # aidlc-setupスキル
│           └── bin/aidlc-setup.sh
docs/
├── aidlc/                # デプロイ済みコピー（rsync同期先、直接編集禁止）
├── aidlc.toml            # プロジェクト設定
└── cycles/
    ├── operations.md     # 運用引き継ぎ情報
    └── rules.md          # 追加ルール
```

## アーキテクチャ・パターン

- **メタ開発構造**: `prompts/package/` が正本、`docs/aidlc/` がrsyncコピー
- **シェルスクリプト中心**: bin/ 配下のシェルスクリプトでCI/ツール操作を実行
- **プロンプト駆動**: AIエージェントがプロンプトを読み込みフローを実行

## 技術スタック

| 項目 | 値 | 根拠ファイル |
|------|-----|-------------|
| 言語 | Bash (シェルスクリプト) | prompts/package/bin/*.sh |
| フレームワーク | AI-DLC | docs/aidlc.toml |
| 主要ライブラリ | dasel, gh CLI, rsync | docs/aidlc/bin/env-info.sh |

## 依存関係

- `aidlc-setup.sh` → `sync-package.sh`（rsync同期）
- `inception.md` → `common/rules.md`（テンポラリファイル規約参照）
- `operations-release.md` → `rules.md`（PRマージ前レビューコメント確認）
- 循環依存: なし

## 特記事項

### Issue #362: aidlc-setup.sh同期スキップバグ
- **場所**: `prompts/package/skills/aidlc-setup/bin/aidlc-setup.sh` L254-262
- **原因**: `cycle_start` 時に `--force` なしだとバージョン比較前に `skip:already-current` で早期終了
- **既存機構**: `--force` フラグ、`--dry-run` フラグは存在するが、早期終了により到達しない

### Issue #361: PRマージ前レビューツール指定
- **場所**: `prompts/package/prompts/operations-release.md` L492-571（7.13節）
- **内容**: `/review`（Claude Code固有）、`codex review`（Codex固有）、Codex PRレビュー完了待機が具体的に定義
- **対応**: ツール名を抽象化し、汎用的な「PRマージ前レビュー」ステップに変更

### Issue #365: operations.mdスリム化
- **場所**: `docs/cycles/operations.md`（178行）、`prompts/package/templates/operations_handover_template.md`（60行）
- **削減候補**: プロジェクト概要（aidlc.tomlから取得可）、CI/CD設定（workflowから読める）、更新履歴（git logと重複）、メタ開発手順（rules.mdに移動済み）
- **残すべき**: デプロイ方針、監視設定、既知の問題

### Issue #363: rules.md再読み込み
- **場所**: `prompts/package/prompts/inception.md` ステップ5（L218-220）でrules.md読み込み、ステップ11（L540-700）でブランチ切り替え
- **ギャップ**: 320行・6ステップ分の距離があり、ブランチ切り替え後の再読み込みなし

### Issue #341: テンポラリファイル規約
- **場所**: `prompts/package/prompts/common/rules.md` L419-425（使用手順）
- **現在の手順**: 1.パス生成 → 2.書き込み → 3.使用 → 4.削除
- **不足**: mktemp後のReadツール呼び出しステップがない
