# 既存コードベース分析

## ディレクトリ構造・ファイル構成

```
.
├── bin/                          # トップレベル実行スクリプト
├── docs/
│   ├── aidlc/                   # フレームワークインスタンス（rsyncコピー、直接編集禁止）
│   │   ├── bin/                 # 実行スクリプト
│   │   ├── config/              # 設定ファイル（defaults.toml）
│   │   ├── prompts/common/      # 共通プロンプト（rules.md等）
│   │   ├── skills/              # スキル定義
│   │   └── templates/           # 成果物テンプレート
│   ├── cycles/                  # サイクル成果物（v1.0.1〜v1.27.4）
│   └── aidlc.toml              # インスタンス設定（プロジェクト固有）
├── prompts/
│   ├── package/                 # テンプレートレイヤー（編集対象の正本）
│   │   ├── bin/                 # migrate-config.sh等
│   │   ├── prompts/common/      # rules.md等（正本）
│   │   └── skills/              # aidlc-setup等（正本）
│   └── setup-prompt.md          # セットアップエントリポイント
```

メタ開発構造: `prompts/package/` が正本、`docs/aidlc/` はrsyncコピー。

## アーキテクチャ・パターン

- **テンプレート-インスタンス分離**: `prompts/package/`（テンプレート）→ `docs/aidlc/`（インスタンス）
  - 根拠: `aidlc-setup.sh` の rsync 同期ロジック（Step 6）
- **TOML駆動設定**: `docs/aidlc.toml` + `defaults.toml` でフレームワーク挙動を宣言的に制御
  - 根拠: `read-config.sh` による設定読み込み、`defaults.toml` のフォールバック
- **プロンプトベース制約**: AIエージェントの振る舞いはプロンプト（`.md`）内のルールで制御
  - 根拠: `rules.md` のバックログ登録ルール、セミオートゲート仕様

## 技術スタック

| 項目 | 値 | 根拠ファイル |
|------|-----|-------------|
| 言語 | Bash (シェルスクリプト), Markdown (プロンプト) | `bin/`, `prompts/package/bin/` |
| フレームワーク | AI-DLC (独自開発手法) | `docs/aidlc.toml` |
| 主要ライブラリ | dasel (TOML解析), gh (GitHub CLI) | `env-info.sh`, `read-config.sh` |

## 依存関係

### 変更対象の依存関係マッピング

**#402 aidlc-setup.sh migrate-config警告検出**:
- `prompts/package/skills/aidlc-setup/bin/aidlc-setup.sh` (L390-401)
  - `migrate-config.sh` を呼び出し、終了コード `$MIGRATE_EXIT` で判定
  - `case 0` → 正常、`case 2` → `warn:migrate-warnings`、`case *` → `error:migrate-failed`
  - 問題: v1.27.3で `migrate-config.sh` が終了コード規約に準拠し exit 0 を返すようになったが、aidlc-setup.sh は exit 2 で警告を検出している
  - 修正方針: stdout出力を解析して警告有無を判定する方式に変更

**#401 バックログ登録時のスコープガード**:
- `prompts/package/prompts/common/rules.md` (L585-644)
  - 「改善提案のバックログ登録ルール」セクション: バックログ登録の義務ルールを定義
  - 現状: スコープ内/外を区別せず一律バックログ登録を要求
  - 修正方針: 登録前にintent.mdのスコープを確認し、スコープ内項目は現サイクル内で対応するよう指示を追加

**#400 semi_autoゲート review_not_executed追加**:
- `prompts/package/prompts/common/rules.md` (L429-448)
  - フォールバック条件テーブル: 4段階（error, review_issues, incomplete_conditions, decision_required）
  - 現状: AIレビュー未実施を検知する条件がない
  - 修正方針: 優先度0（最優先）で `review_not_executed` 条件を追加

### 循環依存の有無
循環依存なし。変更は3つの独立した箇所に限定される。

## 特記事項

- `aidlc-setup.sh` は `prompts/package/skills/aidlc-setup/bin/aidlc-setup.sh` と `docs/aidlc/skills/aidlc-setup/bin/aidlc-setup.sh` の両方に存在するが、rsyncコピーのため同一内容。編集は `prompts/package/` 側のみ行う
- `rules.md` も同様に `prompts/package/prompts/common/rules.md` が正本
- #401 と #400 はプロンプト（Markdown）の修正が主体で、シェルスクリプトの変更は不要
