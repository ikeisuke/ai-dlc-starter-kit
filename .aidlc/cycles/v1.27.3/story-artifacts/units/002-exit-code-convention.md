# Unit: 終了コード規約統一

## 概要
シェルスクリプトの終了コード（0: 成功 / 1: バリデーションエラー / 2: システムエラー）の使い分けを統一し、規約をガイド文書として整備する。

## 含まれるユーザーストーリー
- ストーリー 4: squash-unit.sh の終了コード規約逆転修正
- ストーリー 5: post-merge-cleanup.sh の警告時 exit 2 追加
- ストーリー 6: 終了コード規約ガイド文書の作成

## 責務
- `bin/squash-unit.sh` の引数バリデーション部（22箇所）の exit 2 → exit 1 修正
- `docs/aidlc/bin/post-merge-cleanup.sh` の警告時 exit 2 追加
- 終了コード規約ガイド文書の新規作成（`prompts/package/guides/` 配下）
- 既存ガイド一覧（`prompts/package/guides/README.md` 等）からのリンク追加（Unit 002 内で完結）
- 呼び出し元プロンプトとの整合性確認

## 境界
- 規約に準拠済みの7スクリプト（post-merge-sync.sh、update-version.sh、migrate-config.sh、issue-ops.sh、migrate-backlog.sh、pr-ops.sh、check-issue-templates.sh、aidlc-setup.sh）は変更しない
- 新規スクリプト作成は含まない

## 依存関係

### 依存する Unit
- なし

### 外部依存
- なし

## 非機能要件（NFR）
- **整合性**: 呼び出し元プロンプトの終了コードハンドリングと矛盾しないこと

## 技術的考慮事項
- squash-unit.sh: 引数パースセクション（72-259行）の exit 2 を一括で exit 1 に変更
- post-merge-cleanup.sh: `migrate-config.sh` のゴールドスタンダード（`_has_warnings` フラグ）パターンを参考に実装
- ガイド文書は `prompts/package/guides/` に作成（`docs/aidlc/` は直接編集禁止）

## 関連Issue
- #397

## 実装優先度
Medium

## 見積もり
スクリプト修正（2ファイル）+ ガイド文書作成（1ファイル）+ 整合性確認

---
## 実装状態

- **状態**: 完了
- **開始日**: 2026-03-24
- **完了日**: 2026-03-24
- **担当**: -
