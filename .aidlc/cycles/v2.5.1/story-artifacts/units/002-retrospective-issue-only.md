# Unit: retrospective Issue 一本化 + spool + mirror_state ラベル化

## 概要

`04-completion.md §1.5` の retrospective ローカルファイル生成を撤廃し、最初から GitHub Issue 起票で完結するフローに刷新する。`mirror_state` 状態を Issue ラベルで保持し、`gh` 不可時は `history/retrospective-spool.md` にスプール、`scripts/retrospective-resend.sh` で次回再送できる経路を提供する。v2.5.0 の YAML 互換は読み取り側で維持。

## 含まれるユーザーストーリー

- ストーリー 1: retrospective ローカルファイル撤廃と Issue 起票統合

## 責務

本 Unit は **`steps/operations/04-completion.md §1.5` ステップ記述の編集主体** であり、retrospective Issue 起票実体を実装する（Intent §「判断 6.5」参照）。共有契約（命名規約・本文構造）は Intent §「判断 6.1」「判断 6.2」を正本とし、本 Unit が初期実装する。

- `steps/operations/04-completion.md §1.5` の改修（ローカルファイル生成停止 + Issue 起票統合 + Unit 001 の wizard / 解決関数呼び出し + Unit 003 の下書きフック差し込み口の用意）
- retrospective Issue 起票時の本文構造（Intent §「判断 6.2」の構造に従う）
- `mirror_state` のラベル化（Intent §「判断 6.1」の命名規約に従う）
- `retrospective` ラベルの起票時付与（Intent §「判断 6.1」）
- `gh_status != available` 時のスプール処理（`history/retrospective-spool.md`）
- `scripts/retrospective-resend.sh` の新規実装
- 既存 `cycles/{{PREV_CYCLE}}/operations/retrospective.md` 読み取り経路の維持（v2.5.0 互換）
- `templates/retrospective_template.md` の改修（Issue 本文用テンプレへ転換 / 共有契約に整合）
- Unit 003 から受け取る LLM 下書き出力（Intent §「判断 6.3」スキーマ）を本文 prefilled として埋め込む処理

## 境界

- `feedback_mode` 解決 / wizard / cap 判定は Unit 001 の関数 I/F を呼び出す（本 Unit は config / wizard / cap 判定ロジック自体を持たない）
- 主因分類 LLM 下書きは Unit 003 が担う（本 Unit は Unit 003 から受け取る出力を Intent §「判断 6.3」スキーマに従って本文に埋め込むのみ）
- predecessor 検索は Unit 004 が担う

## 提供 I/F（他 Unit から呼び出される関数）

| I/F | 種別 | 利用 Unit | 戻り値 / 入出力 |
|-----|------|----------|----------------|
| Issue 起票関数 `retrospective_issue_create(body, mode)` | 関数 | Unit 003（LLM 下書き完了後の起票呼び出し） | (本文, モード) → 起票成功時 Issue URL / 失敗時スプールパス |
| 本文構築関数 `retrospective_body_compose(problem_drafts, kpt_sections)` | 関数 | Unit 003 | (LLM 下書き出力 + KPT) → Markdown 本文（共有契約準拠） |
| 命名規約定数 `RETROSPECTIVE_LABEL`, `MIRROR_STATE_LABEL_PREFIX` | 定数 | Unit 004（検索用） | 文字列定数 |

## 依存関係

### 依存する Unit

- Unit 001: feedback_mode 5 値拡張 + マイグレーション + 初回 wizard（依存理由: `feedback_mode` の値が決まらないと起票先（プロダクト / upstream / 両方 / disabled）が判断できないため）

### 外部依存

- `gh` CLI（Issue 起票・Milestone 紐付け・ラベル付与）
- 既存 `scripts/operations-release.sh`（completion 関連サブコマンド）

## 非機能要件（NFR）

- **冪等性**: 同一 Issue が二重起票されない（重複検出ロジック維持）
- **可用性**: `gh_status != available` でも振り返り内容が消失しない（スプール保証）
- **後方互換**: 旧 `retrospective.md` ファイルが残っていても新フローが正常動作

## 技術的考慮事項

- v2.5.0 の `mirror_state` YAML を Issue 本文にも残す（読み取り側互換）
- ラベル名は colon 区切り統一（YAML 値の `:` は `-` に変換: `mirror-state:skipped-duplicate`）
- スプールファイルは `history/` 配下のため cycle ブランチ削除後も main に保持される
- `feedback_max_per_cycle` cap 判定は Unit 001 で実装される判定ロジックを呼び出す

## 関連Issue

- #590 partial（retrospective テンプレ + Operations Phase 自動生成、v2.5.0 で導入済 → 本 Unit で一本化）
- #592 partial（Unit 007 主因切り分け 3 分類、v2.5.0 で導入済 → Issue 化対応）

## 実装優先度

High

## 見積もり

中〜大規模。04-completion.md §1.5 の刷新 + Issue 起票統合 + spool + resend スクリプト + mirror_state ラベル化 + テンプレ改修 + BATS テスト。

---
## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 完了
- **開始日**: 2026-05-05
- **完了日**: 2026-05-05
- **担当**: Construction Phase Unit 002
- **エクスプレス適格性**: -
- **適格性理由**: -
