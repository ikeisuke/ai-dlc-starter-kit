# ドメインモデル: アップグレードパスフォールバック

## 概要

セットアップ・アップグレード時のスクリプトパス解決において、同期済み環境（docs/aidlc/bin/）とスターターキット側（prompts/package/bin/）のフォールバック関係を定義する。

## エンティティ

### ScriptReference（値オブジェクト相当）

- **属性**:
  - script_name: String - スクリプト名（例: setup-ai-tools.sh）
  - primary_path: String - 優先パス（同期済み環境）
  - fallback_path: String - フォールバックパス（スターターキット側）
- **不変性**: パスの優先順位は primary → fallback の順（変更不可）

## ドメインサービス

### ScriptPathResolver（パス解決ロジック）

- **責務**: 実行環境に応じて適切なスクリプトパスを返す（ログ出力は呼び出し元の責務）
- **操作**: resolve(primary_path, fallback_path) → ResolveResult
- **戻り値**: ResolveResult = { resolved_path: String, source: "primary" | "fallback" | "not_found" }
- **解決順序**:
  1. primary_path が実行可能(-x)なら source=primary で返す
  2. fallback_path が実行可能(-x)なら source=fallback で返す
  3. 両方不在なら source=not_found で返す（resolved_path は空）
- **失敗時の動作**: not_found を返すのみ。継続/中断の判断は呼び出し元が行う

## ユビキタス言語

- **primary_path**: sync後に利用可能になるdocs/aidlc/bin/配下のスクリプト
- **fallback_path**: sync前でも利用可能なスターターキット側のスクリプト
- **resolve**: primary/fallbackの順で実行可能なスクリプトを選択する処理
- **source**: 解決結果がどのパスから得られたかを示す識別子
