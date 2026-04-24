# ドメインモデル: Unit 006 Operations Phase へ Milestone close + 紐付け確認 + fallback 作成を組込み

## 概要

GitHub Milestone 運用本採用（#597）の Operations Phase 側 Unit。Operations Phase の Markdown ステップに、サイクル開始時の Milestone 紐付け確認・fallback 判定（5 ケース判定）と、PR マージ後の Milestone close 手順を追加する。本 Unit は Markdown 編集のみのため、**手順の責任分離（Inception 補完 vs Operations 完了）と冪等補完原則（不足時のみ PATCH、付け替えなし）と マージ前完結ルール準拠（GitHub 側操作のみ）** を中心に定義する。

**重要**: このドメインモデル設計では**コードは書かず**、責務の定義のみを行う。実装は Phase 2 で行う。

## ドメイン責務

### Unit 006: Operations Phase Milestone close + 紐付け確認 + fallback

- **責務**: Operations Phase の各ステップに Milestone close + 紐付け確認 + fallback 作成手順を追加し、必要なユーザー確認（持ち越し時の付け替え判断など）を除き、AI/人間が `gh api` を順次実行できる状態を作る
- **入力**: 既存 Markdown ステップ（`01-setup.md` ステップ10 後 / `04-completion.md` ステップ5 末尾）+ Unit 005 で導入済みの Inception Phase Milestone 作成・紐付け仕組み
- **出力**:
  - Markdown 更新後ステップ（5 ケース判定 + Issue/PR 紐付け補完 3 分岐 + Milestone close + 失敗時手動コマンド案内）

## 手順の責任分離

| ステップ | 責務 | 配置 | 5 ケース判定での open=0 closed=0 動作 |
|---------|------|------|--------------------------------------|
| `01-setup.md` ステップ11-1 | **Operations 開始時の Milestone 状態確認・fallback 救済**: Inception スキップ漏れ時に新規作成 | 新規追加（ステップ10 直後） | **fallback 作成** + 警告 |
| `01-setup.md` ステップ11-2 | **関連 Issue 紐付け補完**: 3 分岐（empty / {{CYCLE}} / 他 Milestone） | 同上 | - |
| `01-setup.md` ステップ11-3 | **PR 紐付け補完**: 同様の 3 分岐 | 同上 | - |
| `04-completion.md` ステップ5.5 | **PR マージ後の Milestone close**: 5 ケース判定で `open=1 && closed=0` のみ close 実行 | PR マージ後手順の末尾（ステップ5 末尾、ステップ6 完了サマリの直前） | **エラー停止**（運用異常） |

責任分離の根拠:

- Operations 開始時 (01-setup ステップ11) は「Inception で漏れた可能性のある Milestone を救済」する責務。fallback 作成で運用継続性を確保
- Operations 完了時 (04-completion ステップ5.5) は「サイクル完了の確定処理」。Milestone 不在は運用異常として停止（誤った成功扱いを避ける NFR 可用性要件）
- マージ前完結契約準拠: 04-completion ステップ5.5 は GitHub 側操作のみで `.aidlc/cycles/{{CYCLE}}/**` 配下を更新しない

## 冪等補完原則（Issue/PR 紐付け）

Operations 開始時の Issue/PR 紐付け補完は **3 分岐** で処理し、**不足時のみ PATCH、付け替えは行わない**:

| 現在の Milestone | 動作 | 出力 |
|-----------------|------|------|
| empty（未紐付け） | PATCH で {{CYCLE}} を追加紐付け | `linked:milestone={{CYCLE}}:via-api` |
| `{{CYCLE}}`（既に紐付け済み） | 何もしない（冪等、二重紐付け回避） | `already-linked:milestone={{CYCLE}}` |
| 他 Milestone | 警告のみ（付け替えは Inception 持ち越し判断、Operations 担当者に委ねる） | `WARNING + other-milestone:current=<title>:skip-overwrite` |

**根拠**: Unit 定義 NFR「1 Issue = 1 Milestone 制約に整合」を厳守。他 Milestone への付け替えは `(a) 新サイクルへ付け替え / (b) Backlog に戻して保持` の 2 択判断（Unit 005 の Inception 持ち越しフロー）に委譲。

## 5 ケース判定マトリクス（Unit 005 / Unit 006 共通基盤）

判定基盤は Unit 005（05-completion 1-1）/ Unit 006（01-setup 11-1 / 04-completion 5.5）の 3 配置で同一。配置ごとに 2 ケース（`open=0,closed=0` / `open=0,closed=1`）の動作が異なる:

| ケース | Unit 005（Inception 完了, 1-1） | Unit 006 setup 11-1（Operations 開始） | Unit 006 completion 5.5（Operations 完了） |
|--------|-------------------------------|--------------------------------------|------------------------------------------|
| open=0 closed=0 | 通常作成 (`:created`) | **fallback 作成** (`:fallback-created` + 警告) | **エラー停止** (`ERROR + exit 1`) |
| open=0 closed=1 | エラー停止（誤再オープン防止） | エラー停止（誤再オープン防止） | **already-closed 成功扱い** (`:already-closed:number=N`、二重 close 回避) |
| open=1 closed=0 | 既存再利用 | 既存再利用 | close 実行 (`:closed:number=N`) |
| open≥2 / 混在 / closed≥2 | エラー停止 | エラー停止 | エラー停止 |

## ファイル所有関係

| ファイル | Unit 006 所有範囲 | 他 Unit との関係 |
|---------|----------------|---------------|
| `skills/aidlc/steps/operations/01-setup.md` | ステップ11「Milestone 紐付け確認・fallback 判定」新規追加（**排他所有**） | 既存ステップ 10 / 12 等は本 Unit 範囲外 |
| `skills/aidlc/steps/operations/04-completion.md` | ステップ5.5「Milestone close」新規追加（**排他所有**、ステップ5 末尾とステップ6 完了サマリの間） | 既存マージ前完結ルール記述・worktreeフロー・通常環境フローは本 Unit 範囲外 |
| `CHANGELOG.md` | **対象外**（Unit 007 へ委譲） | Unit 007 が `#597` 節に Unit 006 関連の deprecation/追加記載を追加 |
| `skills/aidlc/guides/issue-management.md` / `guides/backlog-management.md` | **対象外**（Unit 007 所有） | Unit 007 が更新 |

## 境界

- **Inception Phase 側 Milestone 作成**: Unit 005（完了済み）の責務
- **ドキュメント側（docs/configuration.md / README.md / guides / rules.md）の更新**: Unit 007 の責務
- **過去 v2 サイクル（v2.0.0〜v2.3.5）の遡及 Milestone 化**: 本サイクル対象外（Unit D）
- **CHANGELOG `#597` 節の本 Unit 関連記載**: Unit 007 の責務（CHANGELOG `#597` 節は Unit 007 が排他所有）
- **v2.4.0 自身の Milestone close**: 本サイクルの Operations Phase 実施時（自然検証、本 Unit の完了基準には含めない）

## ユビキタス言語

- **fallback 作成**: Operations 開始時に Milestone 不在を検出した場合の救済作成。Inception スキップ漏れを救済する。出力サフィックス `:fallback-created` で通常作成（`:created`）と区別
- **冪等補完**: Issue/PR の Milestone 紐付け状態が既に正しい場合は何もしない原則。empty の場合のみ追加紐付け
- **マージ前完結契約準拠**: PR マージ後の cycle ブランチ配下ファイル更新を行わず、GitHub 側操作のみで完結する原則（Unit 002 / v2.3.5 由来）
- **5 ケース判定**: open/closed Milestone 件数の 5 種組み合わせ（≥2&0, 1&0, 0&0, 0&≥1, ≥1&≥1）に対応する判定ロジック。3 配置（Unit 005 1-1 / Unit 006 11-1 / Unit 006 5.5）で同一基盤、配置ごとに 2 ケースの動作が分岐

## 不明点と質問

なし（plan 段階で codex AI レビュー 3 反復を経て 5 ケース判定 / 冪等補完原則 / マージ前完結契約準拠を確定済み）。
