# Unit 001 計画: rules.md MD040 違反修正

## 概要

`.aidlc/rules.md` の L107（`/tools:suggest-permissions` を含む fenced code block）と L122（`/tools:suggest-permissions --review all` を含む fenced code block）に言語指定を追加し、`markdownlint-cli2` の MD040 違反を 0 件にする。両ブロックは Slack/IDE 等のシンタックスハイライトを必要としないコマンド表記のみのため、言語指定は `text` を採用する。

## 関連 Issue

- #614

## スコープ境界

| 範囲 | 含む / 含まない |
|------|----------------|
| `.aidlc/rules.md` L107 / L122 の fenced code block の開きフェンスに `text` 言語指定を追加 | 含む |
| `markdownlint-cli2` で MD040 違反 0 件確認 | 含む |
| 他の lint ルール違反（MD013 / MD024 等）の修正 | 含まない |
| `.aidlc/rules.md` の他箇所（L107 / L122 以外）の fenced code block 言語指定の見直し | 含まない |
| `.markdownlint.json` / `markdownlint-cli2` 設定ファイルの変更 | 含まない |
| 文章本体・コマンド文字列・指示文の意味的変更 | 含まない |

## 変更対象ファイル

| ファイル | 操作 | 概要 |
|---------|------|------|
| `.aidlc/rules.md` | 編集 | L107 / L122 の `` ``` `` を `` ```text `` に置換 |
| `.aidlc/cycles/v2.6.0/history/construction_unit01.md` | 新規作成 | Unit 001 の進捗履歴（write-history スキル経由） |

## 実装計画

### Phase 1（設計）

`depth_level=standard` のため Phase 1 を実施するが、本 Unit は単一ファイル 2 行の言語指定追加であり設計成果物は最小化する。

- ドメインモデル: 不要（ドメインロジックを伴わない lint fix）
- 論理設計（同 Unit ごく小規模のため簡略）:
  - 対象 2 ブロックは Slack の slash command 文字列を含むためシンタックスハイライト不要 → 言語指定 `text` を選択
  - 編集方針: 開きフェンス `` ``` `` のみを `` ```text `` に置換、閉じフェンスは変更しない（markdownlint MD040 は開きフェンスのみを検査するため）
  - 行番号は固定値ではなく文脈マッチで識別する（編集後に他箇所の行番号がズレない単純編集）

> **設計レビューのスキップ判断**: depth_level=standard では原則実施するが、本 Unit は変更が 2 行・選択肢が 1 つに絞れているため、設計フェーズの AI レビューは「計画 AI レビュー」と統合する（review-flow.md のルーティングは計画承認前レビューを使用）。

### Phase 2（実装）

実装順序:

1. `.aidlc/rules.md` L107 / L122 の開きフェンスを `` ```text `` に編集
2. **必須ゲート**: `npx markdownlint-cli2 .aidlc/rules.md` を実行し MD040 違反 0 件を確認（fail 時は構造を再確認）
3. **参考確認（任意）**: `npx markdownlint-cli2 .` でリポジトリ全体 lint を実行。本 Unit のスコープ外（他ファイル）の既存違反による失敗は本 Unit の完了条件に含めず、検出された場合はバックログ化（GitHub Issue）して別課題で処理する
4. AI レビュー（`reviewing-construction-code`）→ 統合レビュー（`reviewing-construction-integration`）
5. 履歴記録（`/aidlc:write-history` スキル）

## エラーハンドリング / 異常系

| 状況 | 対応 |
|------|------|
| 編集後に MD040 違反が残存 | 対象行を再確認（コードブロック構造のミス）→ 再編集 |
| 編集後に他の lint ルール違反が新規発生 | 編集ミスとして調査・修正（言語指定追加だけで他違反は発生しない想定） |
| `.aidlc/rules.md` 全体の MD040 違反が 2 件以外で検知 | スコープ拡大検討（本 Unit は L107/L122 の 2 件のみが対象、それ以外はバックログ化） |

## NFR

- **可読性**: 編集後の rendered markdown が従来の見え方と同等であること（`text` 指定はシンタックスハイライトなし）
- **互換性**: rules.md の意味的内容（指示文・コマンド・手順）が一切変化しないこと（言語指定追加のみ）

## 完了条件チェックリスト

### 機能整合

- [ ] `.aidlc/rules.md` L107 の fenced code block 開きフェンスに `text` 言語指定が追加されている
- [ ] `.aidlc/rules.md` L122 の fenced code block 開きフェンスに `text` 言語指定が追加されている
- [ ] L107 / L122 のコードブロック内容（`/tools:suggest-permissions` 等）が変化していない
- [ ] L107 / L122 以外の rules.md 編集が含まれていない

### テスト / lint

- [ ] **必須**: `npx markdownlint-cli2 .aidlc/rules.md` が MD040 違反 0 件で終了する
- [ ] **必須**: 編集前後で `.aidlc/rules.md` 単独の lint 出力に MD040 以外の新規違反が発生していない
- [ ] **参考**: `npx markdownlint-cli2 .` でリポジトリ全体 lint を実行し、本 Unit のスコープ外既存違反は完了条件に含めない（検出された場合はバックログ化して別課題で処理）

### 履歴

- [ ] `.aidlc/cycles/v2.6.0/history/construction_unit01.md` が新規作成され、変更ファイル一覧 / 検証結果 / レビュー round が記録される
- [ ] 履歴ファイルに **AI レビューの実施証跡**（codex セッション利用の有無、各 round の指摘件数とラウンド結果、最終判定）を明記し、品質ゲートの達成を追跡可能にする

### 品質ゲート

- [ ] AI レビュー（`reviewing-construction-code` / `reviewing-construction-integration`）が完了条件（1R clean 特例または直近 round clean）を満たす

## 見積もり

- 設計フェーズ: 0.05 日（本計画ファイル + 簡易論理設計を計画ファイル内に統合）
- 実装フェーズ: 0.05 日（編集 + lint 確認 + AI レビュー + 履歴記録）
- 合計: **0.1 日（10〜15 分、Unit 定義見積もりと一致）**
