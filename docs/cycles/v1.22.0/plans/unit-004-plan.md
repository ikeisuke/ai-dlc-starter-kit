# Unit 004 計画: validate_cycle() Git ref安全性修正

## 概要

validate_cycle()にGit ref安全性チェックを追加し、末尾ドットや.lock接尾辞のサイクル名を拒否する。
`git check-ref-format --branch "cycle/${cycle}"` を正とする方式を採用し、不足分のみパターンマッチで追加チェックする。

## 変更対象ファイル

- `prompts/package/lib/validate.sh` — validate_cycle()にGit ref安全性チェック追加
- テストファイル（既存テストファイルがあれば更新、なければ新規作成）

## 実装計画

### Phase 1: 設計

1. **ドメインモデル設計**: バリデーション拡張の構造定義
2. **論理設計**: チェック追加位置、既存バリデーションとの関係

### Phase 2: 実装

3. **コード生成**: validate_cycle()に以下を追加
   - `git check-ref-format --branch "cycle/${cycle}"` による検証
   - `.lock` 接尾辞の拒否チェック（git check-ref-formatがカバーしない場合）
   - 末尾ドットの拒否チェック（git check-ref-formatがカバーしない場合）
   - エラーメッセージ出力（emit_error使用）
4. **テスト**: 正常系・異常系のテストケース作成
5. **統合とレビュー**: AIレビュー実施

## 完了条件チェックリスト

- [ ] validate_cycle()への末尾ドット拒否チェック追加
- [ ] .lock接尾辞拒否チェック追加
- [ ] 拒否時のエラーメッセージ出力
- [ ] 既存の正当なサイクル名（v1.22.0、feature/v1.0.0等）に影響しないこと
