# 既存コードベース分析

## ディレクトリ構造・ファイル構成

エクスプレスモード・終了コード・外部依存に関連するファイル構成:

```
prompts/package/prompts/
├── common/
│   └── rules.md          # エクスプレスモード仕様（正本）
├── inception.md           # ステップ4b（エクスプレスモード判定）、エクスプレスモード完了処理
└── construction.md        # エクスプレスモード遷移先

bin/
├── squash-unit.sh         # 終了コード規約逆転（CRITICAL）
├── post-merge-sync.sh     # COMPLIANT
├── post-merge-cleanup.sh  # 終了コード欠如（HIGH）
└── update-version.sh      # COMPLIANT

docs/aidlc/bin/
├── migrate-config.sh      # COMPLIANT（ゴールドスタンダード: exit 2 を正しく使用）
├── issue-ops.sh           # COMPLIANT
├── pr-ops.sh              # COMPLIANT
├── check-issue-templates.sh # COMPLIANT
├── migrate-backlog.sh     # COMPLIANT
└── setup-ai-tools.sh      # （aidlc-setup.sh 経由で呼び出し）

docs/aidlc/skills/aidlc-setup/bin/
└── aidlc-setup.sh         # COMPLIANT（子スクリプトの exit 2 を正しくハンドリング）

README.md                  # 外部依存の記載なし
```

## アーキテクチャ・パターン

### エクスプレスモードの現在の設計

**起動条件**（`rules.md` エクスプレスモード仕様セクション）:
1. `depth_level=minimal` であること（必須）
2. Unit 数がちょうど1であること（必須）

**depth_level=minimal との結合箇所**:
- `rules.md`: 「`depth_level=minimal` 時に適用条件を満たす場合」— エクスプレスモードの定義自体が minimal に依存
- `rules.md`: 「エクスプレスモードは minimal の**拡張**」— 設計思想として minimal の上位概念
- `inception.md` ステップ4b: スキップ条件が `depth_level が minimal でない場合`
- `inception.md` ステップ14b: `start express` コマンドで `depth_level=minimal` をオーバーライド

**判定フロー**:
1. `inception.md` ステップ14b: `start express` コマンド検出 → `depth_level=minimal` をセット
2. `inception.md` ステップ4b: `depth_level=minimal` の場合のみ判定実行
3. Unit 数カウント → ちょうど1なら有効化、0または2以上はフォールバック

**フェーズ間遷移の仕組み**:
- コンテキストリセット提示をスキップ
- Inception 完了処理（ラベル作成・履歴記録・squash・コミット）を実行
- `construction.md` のフローに自動遷移

### 終了コード規約のパターン

**ゴールドスタンダード**: `migrate-config.sh`
- `_has_warnings=false` で初期化
- 非致命的条件で `_has_warnings=true` をセット
- 最終的に `_has_warnings=true` なら `exit 2`

**規約逆転（CRITICAL）**: `squash-unit.sh`
- 引数バリデーション（72-259行）: `exit 2` を使用（規約では `exit 1` が正しい）
- 操作エラー（197行以降）: `exit 1` を使用（これは正しい）
- 22箇所の `exit 2` を `exit 1` に修正が必要

## 技術スタック

| 項目 | 値 | 根拠ファイル |
|------|-----|-------------|
| 言語 | Bash (シェルスクリプト)、Markdown (プロンプト) | bin/*.sh, prompts/**/*.md |
| ツール | dasel (TOML解析)、gh (GitHub CLI)、git | docs/aidlc/bin/read-config.sh, env-info.sh |
| 外部スキル | claude-skills リポジトリ（9スキル） | .claude/settings.json |

## 依存関係

### 外部スキル依存（claude-skills リポジトリ）

| スキル | 区分 | 参照箇所 |
|--------|------|----------|
| aidlc-setup | 必須 | .claude/settings.json, rules.md |
| reviewing-code | レビュー統合 | .claude/settings.json, construction phase |
| reviewing-architecture | レビュー統合 | .claude/settings.json, construction phase |
| reviewing-security | レビュー統合 | .claude/settings.json, operations phase |
| reviewing-inception | レビュー統合 | .claude/settings.json, inception phase |
| codex-review | レビュー統合 | .claude/settings.json, operations phase |
| squash-unit | オプション | .claude/settings.json, construction phase |
| session-title | オプション | construction.md（「スターターキット同梱ではない」と明記） |
| suggest-permissions | オプション | rules.md（v1.26.1で追加） |

### README の現在のセクション構成

1. 概要 / 2. リポジトリ構成 / 3. クイックスタート / 4. 主要な機能 / 5. ドキュメント / 6. 設計原則 / 7. 関連リンク / 8. ライセンス / 9. コントリビューション / 10. フィードバック

**欠落**: 外部スキル・ツール依存のセクションが存在しない

## 特記事項

- Issue #397 では多数のスクリプトが「exit 2 未対応」として報告されているが、実際の解析では **2スクリプトのみ修正が必要**（squash-unit.sh: CRITICAL、post-merge-cleanup.sh: HIGH）。他の7スクリプトは現時点で規約に準拠している
- `migrate-config.sh` が終了コード規約のゴールドスタンダード実装。新規スクリプトや修正時のリファレンスとして使用可能
- エクスプレスモードの `start express` コマンドは `depth_level=minimal` のオーバーライドを行うため、再設計時にこのコマンドの意味づけも見直しが必要
