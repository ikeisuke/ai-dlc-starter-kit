# Unit: AI エージェント Bash プロンプト経由の zsh OOM クラス予防

## 概要

#688（v2.6.1 で `/aidlc v` 経路の `read_marketplace_version` 呼び出しを CLI モード化で個別解決済）の **兄弟バグ #697** に対応する。根本原因クラスは「AI エージェントが Bash ツール経由で long-text を bash 引数文字列として直接渡し、その中の backtick / `$(...)` がコマンド置換として展開され、未定義コマンドへの zsh `command_not_found_handler` 無限再帰で OOM クラッシュする」全経路。v2.6.2 Inception Phase 中（codex Round 2 レビュー時）に実発生したため、本サイクル内で予防策（規約改訂 + 推奨経路明文化）を確立する。

## 含まれるユーザーストーリー

- ストーリー 6: AI エージェント Bash プロンプト経由の zsh OOM クラス予防

## 責務

- CLAUDE.md「`$(...)` 絶対禁止」セクションを「コマンド置換全般（`$(...)` および backtick `` ` ``）絶対禁止」に拡張、対象範囲を「全 Bash ツール呼び出し引数文字列」に明文化
- CLAUDE.md / AGENTS.md / 関連 SKILL.md に「AI エージェント向け Bash ツール経由 long-text 渡し時の安全パターン」を追記
- `skills/write-history/SKILL.md` / `skills/aidlc/SKILL.md` 等で `--content` / `--content-file` のうち file-based 経路を AI 第一推奨に位置付け（既存仕様の表現更新のみ）
- `skills/aidlc/SKILL.md` の `/aidlc v` 経路の zsh OOM 注意書きを「Bash ツール経由のあらゆる外部スクリプト呼び出しに共通する zsh OOM 回避ルール」として一般化
- 関連箇所（`steps/common/commit-flow.md` / `steps/common/review-flow.md` 等）にクロスリファレンス追記
- CHANGELOG.md v2.6.2 セクションに「規約改訂」項目追加

## 境界

- **本体動作変更なし**: スクリプト API（`--content` 引数等）は廃止しない。後方互換性完全維持
- **強制ブロック実装は対象外**: PreToolUse hook での backtick / `$(...)` 検出 + ブロックは技術的制約（hook が許可ダイアログ後に実行される）のため本サイクル対象外
- **#688 自体の再オープンはしない**: #688 は v2.6.1 で `/aidlc v` 経路を CLI モード化で個別解決済。本 Unit は #697 として独立 Issue 化し、#688 注意書きの一般化のみを実施

## 依存関係

### 依存する Unit

- なし

### 外部依存

- markdownlint-cli2（CLAUDE.md / SKILL.md / docs の lint 検証）
- shellcheck / shellharden（既存スクリプトの安全性検証）

## 非機能要件（NFR）

- **可読性**: 規約改訂後の CLAUDE.md / AGENTS.md / SKILL.md が AI エージェントにとって解釈一意で曖昧でないこと
- **互換性**: 既存スクリプトの動作・引数仕様を一切変更しない
- **検証可能性**: 規約遵守が PR コードレビューで判定可能（手動 + lint）

## 技術的考慮事項

- backtick はシェル解析でコマンド置換として扱われるため、AI エージェントが Markdown 文体（inline code 等）でプロンプトを構築すると容易に混入する。安全パターンは「Write ツールで一時ファイル作成 + wrapper script で読み込み」が最も堅牢
- 同等の long-text 受領インターフェースを持つスクリプト候補（更新検討対象）:
  - `skills/aidlc/scripts/write-history.sh`（`--content` / `--content-file`、既に file-based 経路あり）
  - `skills/aidlc/scripts/operations-release.sh pr-ready`（`--body-file`、Unit 001 と整合）
  - `gh pr create / edit`（`--body-file`、GitHub CLI 経由）
  - `codex exec` / `claude -p`（外部 CLI、wrapper script 経由でファイル → 引数展開）
- #688 注意書きの一般化箇所:
  - `skills/aidlc/SKILL.md` の version アクション section（v2.6.1 で記載済）
  - 同セクションを「Bash ツール経由の外部スクリプト呼び出しに共通する zsh OOM 回避ルール」として `steps/common/` 配下にも参照可能な共通ガイドへ移設するかは Construction 設計レビューで判断

## Unit 006 vs 他 Unit の責務境界

- **Unit 006 の Done 条件**: 規約改訂 + 推奨経路明文化 + 注意書き一般化。スクリプト API 変更なし
- **Unit 001（#678 pr-ready）との関係**: Unit 001 は `pr-ready --body-file` の検証ロジック追加（コード変更）。Unit 006 は SKILL.md / docs の「`--body-file` を AI 第一推奨」記述（ドキュメント変更）。コード変更とドキュメント変更が並行する形で連携
- **本サイクル中の AI レビュー安全性向上効果**: Unit 006 を早期に完了することで、後続 Unit の Construction Phase AI レビュー（codex 等）を改訂後の推奨経路（wrapper script 経由）で安全に実施できる

## Intent 制約適合

- **破壊的変更なし**: スクリプト本体動作・引数仕様は変更しない。規約 / 推奨経路の文書記述のみ更新
- **ドッグフーディング特殊処理禁止**: 規約改訂内容は consumer プロジェクトの AI エージェント運用にも自然に適用される（自リポジトリ判定なし）
- **コマンド置換禁止**: 本 Unit は規約自体を強化する対象であり、改訂後の規約に沿って書き直す

## 関連Issue

- #697（type:chore, priority:high, feedback / v2.6.1 Inception Phase 実発生）
- 関連: #688（CLOSED / v2.6.1 で個別解決済、本 Unit で注意書きを一般化）

## 実装優先度

High（AI 運用安全化、早期実施で本サイクル中の安全性向上）

## 見積もり

0.5 日。規約 / SKILL.md / docs 改訂中心、コード変更なし。markdownlint-cli2 / shellcheck の通過確認とクロスリファレンス整合性確認が大半。

---
## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
- **エクスプレス適格性**: -
- **適格性理由**: -
