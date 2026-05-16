# Inception Phase 意思決定記録 - v2.6.4

Inception Phase で行った重要な意思決定を時系列で記録する。Construction / Operations Phase での参照用。

---

## DR-001: サイクルバージョンを v2.6.4（patch）に決定

- **日時**: 2026-05-16
- **判断者**: ユーザー（明示選択）
- **背景**: 前サイクル v2.6.3 完了直後。候補は patch (v2.6.4) / minor (v2.7.0) / major (v3.0.0)
- **意思決定**: v2.6.4 (patch) を採用
- **理由**:
  - 対象 4 Issue のうち #694 / #708 / #709 はいずれも patch 相当（バグ修正・規約整備・docs・refactor・security）
  - 唯一 #710 のみ「minor リリース想定」と Issue 本文に明記されていたが、これは段階的改修の前段として patch スコープ内に収まる範囲（opt-in 基盤導入 + 後方互換確保まで）に限定する DR-002 と組み合わせて patch 採用
- **影響**: Milestone は `v2.6.4` で作成。破壊的変更は本サイクル除外
- **関連**: DR-002

---

## DR-002: #710 を patch サイクルに含める判断（minor 想定 Issue のサブセット適用）

- **日時**: 2026-05-16
- **判断者**: ユーザー（Issue 選択時の明示選択）+ Intent でサブセット適用を AI 設計
- **背景**: #710 本文「対応時期: minor リリース（v2.7.0 以降）を想定。現行ガード（対話必須トークン / cap / mirror）の動作を壊さない範囲での段階的改修が望ましい」
- **意思決定**: #710 を v2.6.4 に含めるが、対象は **opt-in 基盤の導入 + `predecessor_resolve_issue` の 5 経路後方互換確保まで** に限定。破壊的変更（自動起票完全廃止 / `Retrospective:` タイトル運用見直し / API 破壊的変更）は v2.7.0+ に明示除外
- **理由**:
  - Issue 本文の「段階的改修」記載を patch / minor の分割線として活用
  - v2.7.0+ での本格改修に向けた橋頭堡を早期に確保し、後続サイクルの設計余地を広げる
  - デフォルト動作不変を担保することで consumer プロジェクトへの影響ゼロ
- **影響**: Intent「明示的に除外するもの」セクションに対象外項目を明示記載。Construction Phase Unit 004 で「実装するが既定では未発火」の設計指針を採用
- **関連**: DR-001, DR-004

---

## DR-003: #708 の `cmd_pr_ready` 対応を条件付きに分離

- **日時**: 2026-05-16
- **判断者**: AI 設計（Intent レビュー Round 1 指摘 #1 への対応として明示分離）
- **背景**: #708 本文「`cmd_record_release_prep_commit`: 優先度: 中。パストラバーサル経路あり」「`cmd_pr_ready`: 優先度: 低。パス展開と直接結びついていないが下流での扱いを要確認」
- **意思決定**: 必須対応を `cmd_record_release_prep_commit` のみとし、`cmd_pr_ready` は Construction Phase で「下流の `--cycle` がパス展開に使われるかの影響範囲調査」を実施したうえで同サイクル内対応 / 別 Issue 化を判定する条件付き対応とする
- **理由**:
  - `cmd_record_release_prep_commit` はパス展開経路が明確で必須
  - `cmd_pr_ready` は下流の `pr-ops.sh get-related-issues` がパス展開に使うかが Issue 起票時点で未確定。Construction Phase の調査で根拠を確定するのが安全
- **影響**: Unit 002 の責務に「必須対応」「条件付き対応」を明示分離。調査結果は本 decisions.md に追記される予定
- **関連**: DR-004

---

## DR-004: 完了判定 SoT を「Issue 本文」から「Intent 内サブセット受入基準」に変更

- **日時**: 2026-05-16
- **判断者**: AI 設計（Intent レビュー Round 1 指摘 #2 への対応として明示変更）
- **背景**: 当初の Intent は「各 Issue の完了判定は対応する GitHub Issue 本文の受け入れ基準を SoT とする」と記述したが、#710 / #708 が部分対応となるため Issue 本文 SoT と「4 件すべて完了」表現が衝突
- **意思決定**: 完了判定 SoT を **「v2.6.4 範囲で本 Intent が定義したサブセット受入基準」** に変更。Issue 本文の受入基準は参考情報として扱い、本サイクルでは Intent のサブセット定義が優先される
- **理由**:
  - #710 / #708 のサブセット適用と「4 件すべて完了」の意味的整合を確保
  - Construction Phase で Unit が完了基準を判断する際の混乱を排除
  - #709 / #694 は完全充足のためサブセット適用なし（明示記載）
- **影響**: Intent「含まれるもの」「成功基準」両セクションが「サブセット受入基準」表現に統一
- **関連**: DR-002, DR-003

---

## DR-005: markdown lint 統一化の正本を `package.json` の `scripts.lint:md` に固定

- **日時**: 2026-05-16
- **判断者**: AI 設計（Intent レビュー Round 1 指摘 #4 への対応として明示固定）
- **背景**: #709 本文「`package.json` または `Makefile` に `lint:md` 統一エントリポイントを定義」— 選択肢の自由度が高く、Construction で揺れるリスク
- **意思決定**: **正本は `package.json` の `scripts.lint:md`** に固定。`Makefile` ラッパーは任意 / 必要時のみ追加
- **理由**:
  - npm エコシステムが既にリポジトリで使われている（既存 `npx markdownlint-cli2` 経路）
  - AI レビュー / CI / ローカル開発で同一の `npm run lint:md` コマンドが使える
  - `Makefile` 追加は consumer プロジェクトの環境多様性（make 未インストール等）にも影響するため、必須化を避ける
- **影響**: Unit 003 の責務節で `package.json` を正本と明示。`Makefile` ラッパー追加は本サイクル対象外
- **関連**: なし

---

## DR-006: AI レビュー（Intent / Stories + Units）を 1 codex セッションで連続実施

- **日時**: 2026-05-16
- **判断者**: AI 実行判断（review-flow.md「Codex セッション管理」セクション「初回後 session id を記録、2 回目以降 codex exec resume <session-id>」に基づく）
- **背景**: 本 Inception Phase は 3 ゲート（Intent 承認 / ストーリー承認 / Unit 定義承認）がある
- **意思決定**: Intent レビュー（Round 1-3）とストーリー + Unit 連続レビュー（Round 1-2）を **同一 codex セッション (id: 019e312b-3fb0-7d83-a2cf-f81a3c7d3c67)** で実施。ストーリーと Unit のレビューは 2 ゲートを 1 セッションで連続実行
- **理由**:
  - Intent の文脈を引き継ぐことでストーリー / Unit のレビュー精度が向上
  - codex セッション継続によるコンテキスト保持で重複説明を回避
  - レビューサマリは 2 ゲート分離（intent-review-summary.md / stories-units-review-summary.md）として独立性を維持
- **影響**: codex セッション id を decisions.md に記録（後続サイクルでの再現性確保）。レビューサマリ 2 ファイルが共通 session id を参照する形となる
- **関連**: なし

---

## 追記予定

- **Construction Phase で追加されうる DR**:
  - Unit 002: `cmd_pr_ready` の影響範囲調査結果と「同サイクル内対応 / 別 Issue 化」の判定（DR-003 の結論を本決定として追記）
  - Unit 004: 振り返り opt-in フラグの最終命名（`[rules.retrospective].auto_issue_creation` または同等）
  - 既存ガード（対話必須トークン / cap / mirror）の手動再現結果（DR として記録）
  - `predecessor_resolve_issue` 5 経路の手動再現結果（DR として記録）
