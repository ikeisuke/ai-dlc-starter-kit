# Unit: Tier 2 施策の統合（operations-release スクリプト化 + review-flow 簡略化）

## 概要

Tier 2 施策の2つ（`operations-release.md` のスクリプト化、`review-flow.md` の判定ロジック簡略化）を案Dのインデックス集約と整合する形で実装する。Intent で Tier 2/3 完遂がスコープ内と定義されているため、本 Unit は必達スコープ（High 優先度）。

## 含まれるユーザーストーリー

- ストーリー6: Tier 2 施策の統合適用（operations-release.md スクリプト化）
- ストーリー7: Tier 2 施策の統合適用（review-flow.md 判定ロジック簡略化）

## 責務

### operations-release.md スクリプト化

- `steps/operations/operations-release.md` の手順部分を `scripts/` 配下のシェルスクリプト（例: `scripts/operations-release.sh`）に移管する
- Operations フェーズインデックス（Unit 004 で作成）から「operations-release を実行する場合は `scripts/operations-release.sh` を呼ぶ」と参照させる
- スクリプト化前後で Operations の動作等価性を検証する（`CHANGELOG.md`、`version.txt`、`gh pr create/edit` 引数の一致）
- `operations-release.md` 自体のサイズが 50% 以上削減されていることを tiktoken で確認する

### review-flow.md 判定ロジック簡略化

- `review-flow.md` 内の条件分岐表（処理パス分岐、遷移判定、CallerContext マッピング等）を**共通参照ファイル `steps/common/review-routing.md` に集約する（移管先は1箇所に確定）**
- `review-flow.md` 本体は手順記述に特化させ、条件分岐ロジックは `review-routing.md` への参照形式のみにする
- 各フェーズインデックス（Inception / Construction / Operations）は `review-routing.md` を必要時にロードする
- 整理前後で Intent レビュー、ストーリーレビュー、Unit レビュー、コードレビュー、統合レビューの動作等価性を検証する（外部 CLI 選択、反復回数、自動承認フロー、指摘対応判断フロー）
- `review-flow.md` + `review-routing.md` の合計サイズが整理前の `review-flow.md` 単体以下に収まることを確認する

## 境界

- **含まない**: Tier 2 施策の3つ目「ステップファイル内 boilerplate 削減」— Intent で「案D化の過程で自動解消扱い」と定義。独立施策として実装せず、Unit 006 の計測時に達成状況を確認する
- **含まない**: インデックス構造自体の設計・実装（Unit 001-004）
- **含まない**: 新たな Reviewing スキルの追加・既存スキルの内部実装変更（Intent で除外済み）
- **含まない**: `review-flow.md` 内の「AIレビュー指摘の却下禁止」「外部入力検証」等の手順記述（本体に残す）

## 依存関係

### 依存する Unit

- Unit 001（Inception インデックスから `review-routing.md` を参照するため）
- Unit 003（Construction インデックスから `review-routing.md` を参照するため）
- Unit 004（Operations インデックスから `review-routing.md` を参照するため。operations-release スクリプトの参照元でもある）

### 外部依存

- `gh` CLI — 動作等価性検証（dry-run）
- tiktoken (cl100k_base) — サイズ削減確認

## 非機能要件（NFR）

- **可用性**: 整理前後で Operations リリース動作・AI レビュー動作が同一
- **保守性**: 条件分岐の変更時に1箇所のみ編集すれば足りる構造にする

## 技術的考慮事項

- **operations-release.sh の実装方針**: 既存 `steps/operations/operations-release.md` の手順を忠実にシェルスクリプト化する。新機能の追加は禁止（純粋なリファクタリング）
- **review-routing.md の配置**: `steps/common/` 配下に新設し、全フェーズインデックスから参照できるようにする
- **review-flow.md の残存部分**: 「レビュー完了時の共通処理」「レビューサマリファイル」「履歴記録」「AIレビュー指摘の却下禁止」「外部入力検証」等の手順記述は本体に残す
- **動作等価性の検証方法**: 検証サンプル A の Intent レビュー実行で、codex exec の引数・反復回数・分岐フローを整理前後で比較する

## 関連Issue

- #519: コンテキスト圧縮メイン Issue（Tier 2 施策）

## 実装優先度

High（Must-have、#519 Tier 2/3 完遂スコープに含まれる必達項目）

## 見積もり

中規模（2 日相当）。2 つのリファクタリング + 動作等価性検証。

---
## 実装状態

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
- **エクスプレス適格性**: -
- **適格性理由**: -
