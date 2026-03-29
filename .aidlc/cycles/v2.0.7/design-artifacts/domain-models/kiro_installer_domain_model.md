# ドメインモデル: KiroCLIインストーラー

## 概要

KiroCLIエージェント設定ファイル（`aidlc.json`）をユーザー環境（`~/.kiro/agents/`）に配置するインストーラー。SKILL.md（オーケストレーション層）とシェルスクリプト（実行層）の2層構造。

**重要**: このドメインモデル設計では**コードは書かず**、構造と責務の定義のみを行います。

## 値オブジェクト（Value Object）

### SourceTemplate

- **属性**: path: string - テンプレートファイルのパス（`skills/aidlc/templates/kiro/agents/aidlc.json`）
- **不変性**: プロジェクトに同梱される静的ファイル。インストーラーは読み取りのみ
- **等価性**: ファイルパスで判定

### TargetFile

- **属性**: path: string - 配置先パス（`~/.kiro/agents/aidlc.json`）
- **不変性**: 配置先は固定（KiroCLIの規約に従う）
- **等価性**: ファイルパスで判定

### InstallResult

- **属性**:
  - status: enum - `success` / `warning` / `skipped`
  - message: string - 結果メッセージ
- **不変性**: 処理結果は不変
- **等価性**: status + message で判定

## ドメインサービス

### InstallService（install-kiro-agent.sh）

- **責務**: ファイル配置の副作用処理。対話制御は行わない
- **操作**:
  - install(source, target_dir, force) → InstallResult
    1. source の存在確認 → 不在: exit 1
    2. target_dir の作成（不在時）→ 作成失敗: exit 2
    3. 冪等性チェック（既存ファイルとの diff）
       - 同一内容: `status:skipped` → exit 0
       - 差分あり + force=false: exit 1（上書き拒否）
       - 差分あり + force=true: 一意バックアップ（`.bak.<timestamp>`）作成 → コピー
    4. ファイルコピー → 失敗: exit 2
    5. kiro 存在確認（任意のpost-install verify、`command -v kiro`）
       - 導入済み: `status:success`
       - 未導入: `status:warning`（verify失敗はwarningでありインストール成功を覆さない）

### OrchestratorService（SKILL.md）

- **責務**: 対話制御、エラーメッセージの案内、手動コマンド表示
- **操作**:
  - run():
    1. InstallService を実行
    2. 結果に応じた案内表示
       - exit 0: 成功メッセージ（warning時はkiro未導入の旨を追記）
       - exit 1（上書き拒否）: 差分表示 → ユーザーに確認 → `--force` で再実行
       - exit 2: 手動コピーコマンドを表示

## エラーケース一覧

| ケース | 層 | 終了コード | 対応 |
|-------|-----|-----------|------|
| テンプレート不存在 | スクリプト | 1 | エラーメッセージ表示 |
| 配置先ディレクトリ作成失敗 | スクリプト | 2 | 手動コマンド案内（SKILL.md） |
| 既存ファイルあり（差分あり、force=false） | スクリプト | 1 + `reason:overwrite_required` | 差分表示・上書き確認（SKILL.md） |
| ファイルコピー失敗（権限不足等） | スクリプト | 2 | 手動コマンド案内（SKILL.md） |
| kiro未導入 | スクリプト | 0（warning） | 「配置済みだがCLI未検証」案内（SKILL.md） |

## ユビキタス言語

- **テンプレート**: プロジェクトに同梱されるエージェント設定ファイルの雛形
- **配置先**: ユーザーのホームディレクトリ配下の KiroCLI エージェント設定ディレクトリ
- **冪等性**: 同じ操作を複数回実行しても結果が変わらない性質
- **post-install verify**: 配置後に KiroCLI が設定を認識できるか確認する検証ステップ
