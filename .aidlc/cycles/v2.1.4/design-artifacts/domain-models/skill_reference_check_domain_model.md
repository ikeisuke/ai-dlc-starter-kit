# ドメインモデル: skills/直接参照チェック導入

## 概要

`skills/`配下のファイルからプロジェクトルート相対パス（`skills/aidlc/`）による参照違反を検出するCIスクリプトの構造を定義する。

## 値オブジェクト

### ViolationResult
- **属性**: file: string, line: number, content: string
- **不変性**: 検出後に変更されない

## ドメインサービス

### SkillReferenceChecker（bin/check-skill-references.sh）
- **責務**: `skills/`配下のファイルを走査し、`skills/aidlc/`パターンの違反を検出
- **自己完結**: config依存なし。`skills/`ディレクトリ存在で判定
- **操作**: check() → ViolationResult[]、exit code 0/1/2

## 不明点と質問

（なし）
