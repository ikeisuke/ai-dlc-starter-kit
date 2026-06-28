---
name: aidlc-v3
description: >-
  AI-DLC v3（AI-Driven Development Lifecycle）のオーケストレーター骨組み。
  define / develop / release / reflect の 4 フェーズコマンドと status / doctor の
  補助コマンド、連続実行ラッパ express、旧名エイリアス（inception / construction /
  operations / retrospective）を統一的にルーティングする。
  define / develop（normal / risky 含む）/ release / reflect の各フェーズフローと status 出力を
  実装済み。doctor は後続 Phase（Phase 6）。
---

# AI-DLC v3 オーケストレーター（skeleton）

AI-DLC v3 は、フェーズ進行を会話履歴の推論ではなく、リポジトリ内の `state.json` +
work item frontmatter への**明示的な状態書き込みから導出**する（RFC DG-6）。

> **本ファイルの位置づけ（v3.0.0-alpha.7 / Phase 6）**: 本 SKILL.md は
> ルーティングの骨組みである。実体の手順ファイルとして `steps/define.md` / `steps/status.md` /
> `steps/develop.md`（`tiny` / `normal` / `risky`）/ `steps/release.md`（Step 1–4）/ `steps/reflect.md`（Step 0–4）が存在する。
> `doctor` は **予約**であり、手順ファイルは後続 Phase（Phase 6）で実装する
> （未作成ファイルへの参照は作らない）。`/aidlc-v3` 起動は `marketplace.json` 登録済みで有効。

## コマンド表記について（`/aidlc` と `/aidlc-v3` の区別）

設計正本 `docs/v3/workflow.md` は v3 の**最終的なコマンド表面**を `/aidlc`（例:
`/aidlc define`）で記述する。これは v3 が v2 を置き換えた後の end-state である。

一方、本 skeleton（v3.0.0-alpha.6 / Phase 5）は v2（`skills/aidlc` = `/aidlc`）と
**共存**し、`marketplace.json` へ登録済み（`/aidlc-v3` 起動有効化済み）。
そのため**現時点の起動表面は `/aidlc-v3`** であり、本 skeleton 内の
手順・出力例は `/aidlc-v3` 表記を用いる（現状の共存を反映）。最終表面 `/aidlc` への
切替（本流化 = `skills/aidlc-v3 → skills/aidlc` 置換）は後続 Phase（Phase 7）で行う
（正本のコマンド**名**（`define` / `develop`
等）は workflow.md / RFC DG-1 に準拠し、本区別は起動 prefix のみに関する）。

## コマンド体系

### フェーズコマンド

`define` / `develop` / `release` は状態を進行させ承認ゲートを持つ。`reflect` は例外で、**状態を変更せず
（`state.json` 非変更）明示の承認ゲートを持たない**（任意実行 / 人間関与は Step 2 KPT 編集・Step 3 Issue 化確認）。

| コマンド | 責務 | 旧フェーズ | 本 skeleton での扱い |
|---------|------|-----------|--------------------|
| `define` | 目的・スコープ・完了条件・作業単位（work item）を決める | Inception | `steps/define.md`（実在 / Unit 001 で実装） |
| `develop` | 次の work item を実装・検証・完了する（1 実行 = 1 work item） | Construction | `steps/develop.md`（実在 / `tiny` / `normal` / `risky`） |
| `release` | main に安全に取り込む（PR 整備・merge） | Operations | `steps/release.md`（実在 / Step 1–4） |
| `reflect` | 振り返り、改善 Issue を作る（任意実行 / state 非変更・ゲートなし） | Retrospective | `steps/reflect.md`（実在 / Unit 002 で実装） |

### 補助コマンド（状態を変更しない）

| コマンド | 責務 | 本 skeleton での扱い |
|---------|------|--------------------|
| `status` | `state.json` + frontmatter からフェーズを導出し現在地・次アクションを表示（**読み取り専用**） | `steps/status.md`（実在 / Unit 001 で実装） |
| `doctor` | config / git / gh / state / work-items / trace の問題を診断（**自動修正しない**） | 予約（後続 Phase で実装） |

### コマンド名規約（RFC DG-1）

- Construction 相当のコマンド名は **`develop`** で確定する。`build` / `implement` は
  採用せず、**エイリアスにもしない**（`build` は compile を連想させるため不採用）。

## 旧名エイリアス（後方互換 / RFC DG-1）

旧フルネームのみを後方互換エイリアスとして維持する。

| 旧名 | v3 コマンド |
|------|-----------|
| `inception` | `define` |
| `construction` | `develop` |
| `operations` | `release` |
| `retrospective` | `reflect` |

不採用動詞（`build` / `implement` 等）はエイリアスに含めない。

## express（連続実行ラッパ）

`express` は独立コマンドではなく、フェーズコマンドの連続実行ラッパである。

- define で生成される work item が **1 つ（`tiny` または `normal`）の場合のみ**、
  `define` → `develop` → `release` を連続実行する。
- work item が **複数**になった場合は define 完了後に終了し、`develop` / `release`
  を個別実行するよう案内する。
- **`risky` work item を含む場合は連続実行しない**（承認・レビューの厚みが必要なため
  個別実行へ案内）。

## 引数なし実行のルーティング

`/aidlc-v3`（引数なし）は `state.json` + work item frontmatter から**フェーズを導出**し、
対応するフェーズコマンドへ自動ルーティングする。

```text
/aidlc-v3（引数なし）
  ├─ state.json 不在        → define
  └─ state.json 存在        → フェーズ導出（正本: docs/v3/data-model.md §5）
        ├─ define 未完了     → define
        ├─ work item 残あり  → develop
        ├─ 全 work item 完了 → release
        └─ merged + 承認済   → reflect（任意）
```

> **フェーズ導出ロジックの正本（SoT）は `docs/v3/data-model.md` §5**。本 SKILL.md は
> 導出**結果**を参照してルーティングを記述し、導出規則そのものを再定義しない（上図は
> 非規範サマリであり、評価順序・`complete` 最優先などの正確な規則は data-model §5 を参照）。

## コアルール参照

v3 の共通開発ルール（コミット規約・レビューフロー・終了コード規約等）への参照ポイント。
v3 専用の rules 実体（`steps/rules.md` 等）は後続 Phase で追加する。本 skeleton では
参照ポイントの宣言に留める。

## パス解決

`scripts/` / `templates/` / `steps/` で始まるパスは、本 SKILL.md と同じ**スキルベース
ディレクトリ**からの相対パスとして解決する（例: `scripts/state-read.sh`、
`templates/work-item.md`、`steps/define.md`）。step ファイルからの単純相対参照
（`steps/templates/...` のような解釈）は行わない。

- `scripts/`: `state-read.sh` / `state-write.sh` / `state-validate.sh`（state.json 操作）/ `work-item-next.sh`（選定）/ `work-item-validate.sh`（work item 検証）/ `work-item-status.sh`（work item frontmatter status の read / 遷移）
- `templates/`: `intent.md` / `work-item.md` / `journal.md` / `release.md` / `reflect.md`（成果物テンプレート）
- `steps/`: `define.md` / `status.md` / `develop.md` / `release.md` / `reflect.md`
