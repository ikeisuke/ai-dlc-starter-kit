# Intent（開発意図）

## プロジェクト名
AI-DLC Starter Kit v1.16.4 - ツールチェーンのバグ修正と改善

## 開発の目的
AI-DLCツールチェーン（シェルスクリプト群・プロンプト）に存在するバグの修正と、利便性向上のための改善を行う。具体的には、dasel v3環境での設定読み取り失敗、issue-ops.shの認証判定バグ、古い呼び出し方式の残存、誤案内メッセージの修正、およびClaude Code許可設定のベストプラクティス策定を対応する。

## ターゲットユーザー
AI-DLCスターターキットを使用する開発者（自身を含む）

## ビジネス価値
- dasel v3環境でのブランチ設定読み取りが正常に動作し、ユーザー体験が改善される
- issue-ops.shの認証バグ修正により、Issue駆動ワークフローが正常動作する
- 古いread-config.sh呼び出しの更新により、保守性と一貫性が向上する
- 完了メッセージの修正により、次フェーズへの案内が明確になる
- Claude Code許可設定の推奨パターンが明文化され、新規セットアップ時の混乱が軽減される

## 成功基準
- dasel v3環境で `docs/aidlc/bin/read-config.sh rules.branch.mode` を実行し、終了コード0で期待値（例: `ask`）が返ること。dasel v2環境でも同様に動作すること
- `docs/aidlc/bin/issue-ops.sh set-status <issue-number> <status>` を認証済みgh環境で実行し、`issue:<number>:status:<status>` が返ること。gh未認証時は従来通り `gh-not-authenticated` エラーが返ること
- read-config.shの古い呼び出しパターン（旧インターフェースの引数形式など）が `prompts/package/` 配下に残存しないこと。具体的な旧パターンはConstruction Phaseの既存コード分析で特定し、検索コマンドと期待結果（0件）を定義する
- `prompts/package/prompts/operations.md` の完了メッセージが「start inception」に修正されていること（`docs/aidlc/` への反映はOperations Phase時のrsyncで行われる）
- `.claude/settings.local.json` の推奨allowedToolsパターンが `prompts/package/guides/ai-agent-allowlist.md` のClaude Codeセクションに追記・整理されていること

## 期限とマイルストーン
パッチリリース - 単一サイクル内でOperations Phaseまで完了する

## 制約事項
- パッチリリースのため、破壊的変更は含めない
- プロンプト・テンプレートの修正は `prompts/package/` を編集すること（`docs/aidlc/` 直接編集禁止。`docs/aidlc/` への反映はOperations Phase時のrsyncで行われる）
- dasel v2との後方互換性を維持すること
- #219は推奨設定の策定・ドキュメント化までとし、自動設定の仕組みは含めない

## 影響範囲と回帰確認
- **#223 read-config.sh修正**: dasel v2/v3両環境での全設定キー読み取りが正常動作すること。既存スクリプトからの呼び出しに影響がないこと
- **#225 issue-ops.sh修正**: gh未認証環境での挙動が従来と同じであること。認証済み環境でのみ動作が改善されること
- **#224 read-config.sh呼び出し更新**: 更新したプロンプト・スクリプトが正常に設定値を取得できること
- **#229 メッセージ修正**: 該当箇所のみの変更であり、他の案内メッセージに影響がないこと
- **#219 許可設定ドキュメント**: ドキュメント追加のみであり、既存機能への影響なし

## 不明点と質問（Inception Phase中に記録）

[Question] Intentの方向性として「AI-DLCツールチェーンのバグ修正と改善」で進めてよいか
[Answer] その方向でOK

[Question] #219のスコープをどこまでにするか
[Answer] 推奨設定の策定まで（調査して推奨allowedToolsパターンをドキュメント化する）

## 関連Issue
- #229: サイクル完了メッセージの「start setup」を「start inception」に修正
- #225: issue-ops.sh が認証済み環境でも gh-not-authenticated エラーを返す
- #224: read-config.sh の古い使い方を更新
- #223: dasel v3 予約語 'branch' による rules.branch.mode 読み取り失敗
- #219: 各リポジトリの .claude/settings.local.json の許可設定ルールを整理
