# Intent（開発意図）

## プロジェクト名
AI-DLC Starter Kit

## 開発の目的
Operations Phaseのリリース品質保証を強化し、ツール基盤のデフォルト値管理を整理する。具体的には、PRオープン前のパーミッション監査・ローカルレビュー手順の標準化、suggest-permissionsステップの追加、リポジトリ固有処理の適切な配置（Bash Substitution Checkの移動）、およびread-config.shの--default廃止とバッチモード化によるプリフライト設定取得の簡素化を行う。

## 対象外（Out of Scope）
- Construction Phaseの実装方針変更
- 新規機能の追加（既存ワークフローの改善・整理のみ）
- CI/CDパイプラインの新規導入
- Inception Phase / Construction Phaseプロンプトの構造的変更

## ターゲットユーザー
AI-DLCスターターキットを使用する開発者（自プロジェクト含む）

## ビジネス価値
- リリース前の品質チェックが体系化され、パーミッション設定の漏れや危険な設定を事前に検出できる
- ローカルレビュー手順の標準化により、外部レビューツールが利用できない場合でも品質チェックが確実に実行される
- read-config.shのデフォルト値管理がdefaults.tomlに一元化され、プロンプトの保守性が向上する
- リポジトリ固有処理が共通プロンプトから分離され、他プロジェクトへの適用時のエラーが防止される

## 成功基準
- Operations Phase（operations-release.md）にローカルレビュー手順が標準ステップとして組み込まれている
- rules.mdにパーミッション監査・suggest-permissions・Bash Substitution Checkのカスタムワークフローが追加されている
- operations-release.mdから7.6 Bash Substitution Checkが削除され、後続ステップ番号が繰り上げられている
- read-config.shから--defaultオプションが削除されている
- defaults.tomlに全デフォルト値が集約されている
- preflight.mdの設定取得が--keysバッチモード1回に集約されている
- 全プロンプト・ドキュメントから--default使用箇所が除去されている

## 期限とマイルストーン
patchリリースのため、短期間での完了を想定

## 制約事項
- `docs/aidlc/` は直接編集禁止（`prompts/package/` を編集し、Operations Phaseでrsync同期）
- 後方互換性: --default廃止に伴い、既存の全呼び出し箇所を更新する必要がある
- operations-release.mdのステップ番号繰り上げに伴い、関連する参照箇所の更新が必要

## --default廃止の移行方針
- **互換期間**: 設けない（patchリリースで一括移行）
- **移行手順**: defaults.tomlにデフォルト値を追加した後、全プロンプト・スクリプトから--default使用箇所を一括除去する
- **影響範囲の検出**: `grep -r "\-\-default" prompts/package/` で使用箇所を網羅的に検出
- **回避策**: 問題発生時は `git revert` でコミット単位でロールバック可能

## 不明点と質問（Inception Phase中に記録）

（対話を通じて不明点を明確化し、このセクションに記録していく）
