# Intent（開発意図）

## プロジェクト名
AI-DLC Starter Kit v1.13.3

## 開発の目的
AI-DLCスターターキットの品質向上と企業利用時の安全性強化を目的とする。
具体的には以下の2点を改善する：

1. **Construction Phase のprogress.md更新タイミング修正** (#175): Unitブランチ使用時にprogress.md更新がマージ後になる問題を修正し、Operations Phaseで検証済みの「PR準備完了」パターンをConstruction Phaseにも適用する
2. **フィードバック送信機能のオン/オフ設定** (#174): 企業内利用時に機密情報がパブリックリポジトリに漏洩するリスクを軽減するため、フィードバック送信機能を設定で無効化できるようにする

## ターゲットユーザー
- AI-DLCスターターキットの利用者（個人・企業）
- 特に企業内でAI-DLCを利用するチーム（#174）

## ビジネス価値
- Construction Phaseの進捗管理の正確性向上（#175）
- 企業利用時のセキュリティリスク軽減により、導入障壁を下げる（#174）

## 成功基準
- #175: Construction PhaseでUnitブランチ使用時、Unit PR作成前（PR準備完了時点）にUnitブランチ上のprogress.mdが該当Unitのステータスを「完了」に更新済みであること
- #174: `[rules.feedback].enabled = false` 設定時に、`aidlc feedback` コマンド実行時およびURL案内表示がブロックされ、「この機能は無効化されています」と表示されること
- #174: `enabled = true`（デフォルト）時は既存動作が維持されること（`aidlc feedback` 実行で従来どおりIssue作成導線を表示）

## 期限とマイルストーン
パッチリリース（2 Unit構成、各Unitは小規模な変更）

## スコープ外
- Inception Phase / Operations Phase への横展開（#175は Construction Phase のみ対象）
- フィードバック送信先の変更（#174は送信機能のオン/オフのみ）
- `aidlc.toml` の設定キー体系の見直し
- UI文言の大幅な変更

## 制約事項
- メタ開発構造: `prompts/package/` を編集し、`docs/aidlc/` は直接編集しない
- Operations Phaseで検証済みのパターン（#175）を踏襲する
- 既存の設定構造（`docs/aidlc.toml`）との整合性を保つ

## 不明点と質問（Inception Phase中に記録）

[Question] #174 でブロック対象は「送信実行」のみか、「送信導線の提示」も含むか？
[Answer] Issue #174 の記載に基づき、`aidlc feedback` コマンド実行時の処理全体（CLIコマンド実行・URL案内表示）をブロック対象とする。`enabled = false` の場合は導線自体を提示しない。
