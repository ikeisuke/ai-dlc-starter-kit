# Intent（開発意図）

## プロジェクト名

ai-dlc-starter-kit v2.6.3（patch サイクル）

## 開発の目的

v2.6.2 サイクルの振り返り・Codex レビュー指摘・実運用フィードバックから抽出された 7 件のバックログ Issue を解決し、AI-DLC スターターキットの「規約 SoT の網羅性」「AI エージェント実行の再現性」「セキュリティ」「保守性」を patch レベルで底上げする。新機能追加は行わず、既知の欠陥・潜在リスク・属人化したフローの構造的解消に焦点を当てる。

## ターゲットユーザー

- AI-DLC スターターキットを利用する開発者（consumer プロジェクト）
- スターターキット自体をドッグフーディングで開発するメンテナ
- AI エージェント（Claude Code / Codex CLI 等）— 規約・手順の SoT を参照する実行主体

## ビジネス価値

- **再発防止**: v2.6.2 で CI を停止させた bash dynamic scope shadowing バグと同類リスクを規約化＋予防リファクタで構造的に封じる（#706）
- **レビュー品質の安定化**: codex exec の stdin ハングによる「セルフレビューへの無自覚な降格」を防ぐ（#703）
- **セキュリティ強化**: パストラバーサル文字列による参照先逸脱を `validate_cycle` 導入で防ぐ（#701）
- **プロセスの SoT 化**: 属人的だったマージ前 CI 通過確認・修復フローを明文化し、サイクル横断で再現可能にする（#694）
- **AI 実行の再現性向上**: `/aidlc v` 経路のバージョン誤推測バグを構造的に解消する（#698）
- **保守性向上**: 既存 lint 違反の解消（#705）とコード重複の共通ヘルパ化（#702）

## 含まれるもの

本サイクルで対応する 7 件のバックログ Issue:

| Issue | 種別 | 内容 |
|-------|------|------|
| #706 | chore | `printf -v` 系 result-out 関数の local 命名規約を規約 SoT に追記 + `path-guard.sh` の result-out 関数群を namespace 統一する予防的リファクタ |
| #703 | docs | `codex exec` / `codex exec resume` の `</dev/null` 必須運用を `reviewing-common-base.md` 等の SoT に明文化、横断ルール追記 |
| #701 | bugfix/security | `operations-release.sh` の `cmd_squash_712` 全体への `--cycle` バリデーション（`validate_cycle`）導入 + bats テスト追加 |
| #694 | docs | Operations Phase マージ前ステップに「CI 通過確認 + 失敗時修復経路」フローを SoT 化 |
| #698 | feedback | `/aidlc v` 経路の再現性向上 — SKILL.md「バージョン表示」節の文言追加（A 案）+ `version.sh` 自己解決化（C 案） |
| #705 | chore | `review-flow.md` の既存 MD038/no-space-in-code 違反 3 件の修正 |
| #702 | refactor | `write-history.sh` の symlink 解決＋repo-root 取得ロジックの共通ヘルパ化 + bats 回帰確認 |

各 Issue の完了判定は対応する GitHub Issue 本文の「受け入れ基準 / 期待する対応」を Single Source of Truth とする。本 Intent では各 Issue の対応内容を上表で 1 行ずつ要約するに留め、受け入れ基準の細目化・チェック項目の確定は Inception Phase のユーザーストーリー / Unit 定義および Construction Phase の実装計画で行う（AI-DLC のフェーズ分業に従う）。

## 明示的に除外するもの

- 新機能追加（feature 系 Issue: #700 / #685 / #666 / #664 等）は minor 相当のため対象外
- #699（区切り判断での AskUserQuestion 禁止ルール追加）は現行 SKILL.md に既に該当節が存在し対応済みのため対象外（別途クローズ）
- #704（jailrun mirror の retrospective Issue）は別リポジトリ由来のため対象外
- 各 Issue で「別 Issue 分離」と判断される拡張範囲（例: #701 の `record-release-prep-commit` 等への波及対応は要否判断のうえ別 Issue 化を許容）。**分離判定基準**: 以下のいずれかに該当する波及変更は、本サイクルでは扱わず別 Issue 化する — (a) 当該 Issue の受け入れ基準を満たすために必須でない変更、(b) patch スコープ（バグ修正・規約整備・docs・refactor）を超える変更、(c) 影響範囲が当該 Issue の責務境界（対象ファイル群）を越え、他 Issue の受け入れ基準に影響する変更

## 成功基準

- 7 件すべての Issue の受け入れ基準を満たす変更が完了している
- `tests/migration` の既存 bats（49 件）が引き続き pass する（#706 関連）
- `operations-release.sh` / `write-history.sh` の新規 bats テストが pass する（#701 / #702）
- markdownlint で新規エラー 0 件
- **互換性の観測点**: リファクタ系 Issue（#706 / #698 / #702）について既存呼び出し経路が壊れていないことを確認する — `path-guard.sh` の公開関数シグネチャ不変（#706）、`/aidlc v` の既存呼び出し経路で同一バージョン出力（#698）、`write-history.sh` の既存 bats 回帰なし（#702）
- 各 Issue が PR で参照・クローズされる

## 期限とマイルストーン

- 単一サイクル（v2.6.3）内で完結
- Inception → Construction → Operations の標準フロー
- Milestone: v2.6.3（`05-completion` で作成・7 Issue を紐付け）

## 制約事項

- **配布物 baseline 規約の遵守**: 規約追記（#706 / #703）は CLAUDE.md / `bash-tool-safety.md` 等の Single Source of Truth セクションを正本とし、他ドキュメントは参照に留める
- **ドッグフーディング特殊処理の禁止**: 本体スクリプト・ライブラリに「starter kit 自身か consumer か」を判定する分岐を埋め込まない（CLAUDE.md 設計原則）
- **後方互換性**: `version.sh` 自己解決化（#698 C 案）は引数渡しを test override として残す。`path-guard.sh` リファクタ（#706）は外部インターフェースを変えない
- **SKILL.md 本文 500 行制限**: #698 の SKILL.md 改訂は本文行数制限を超えないこと（不要な経緯情報は退避を検討）
- **AI エージェント Bash ツール経由の安全パターン**: 全作業でコマンド置換（`$(...)` / backtick）を Bash ツール引数文字列に含めない

## 不明点と質問（Inception Phase中に記録）

（現時点で対話による未解決の不明点なし。各 Issue の受け入れ基準・推奨対応が明確なため、Construction Phase の Unit 設計時に詳細を確定する）
