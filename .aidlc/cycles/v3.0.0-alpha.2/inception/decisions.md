# 意思決定記録: v3.0.0-alpha.2

## DR-001: skeleton に含める state スクリプトの本数

- **日付**: 2026-06-11
- **状態**: 採用
- **背景**: 計画書（`docs/v3-renewal-plan.md`）内で state スクリプト本数が食い違っていた。Phase 2 成果物リスト（L1012）は `state-read.sh` / `state-write.sh` / `state-validate.sh` の 3 本、最初の Unit 定義 Unit 002（L1157）は `state-validate.sh` のみ。
- **選択肢**:
  - 案 A（採用）: 3 本（read / write / validate）。Phase 2 成果物リスト準拠
  - 案 B: 1 本（validate のみ）。Unit 002 スコープ準拠。read/write は Phase 3 へ defer
- **決定**: 案 A（3 本）。
- **理由**: 「試せる skeleton」には state.json の読み取り（status が参照）・書き込み（define 完了で更新）・検証（doctor が利用）の最小 I/O が必要。計画書 L591 の v3 恒久スクリプトリスト（read/write/validate の 3 本）とも一致する。状態遷移ルールの詳細化は Phase 3 へ defer する範囲限定で採用。
- **決定者**: ユーザー（AskUserQuestion で「3本（read/write/validate）」を選択）

## DR-002: Construction コマンド名（build / develop）の確定

- **日付**: 2026-06-11
- **状態**: 採用
- **背景**: 計画書本文では Construction フェーズコマンドを `build` と表記していたが、alpha.1 で確定した RFC（`docs/v3/rfc.md` DG-1 / `docs/v3/workflow.md` §2）は `develop` を正式名と定め、`build` / `implement` はエイリアスにもしないと明記している。
- **選択肢**:
  - 案 A（採用）: `develop`（確定 RFC 準拠）
  - 案 B: `build`（renewal plan 表記準拠）
- **決定**: 案 A（`develop`）。
- **理由**: 確定 RFC（`docs/v3/*.md`）が設計の正本であり、renewal plan の表記と食い違う場合は RFC を優先する（intent.md 制約に明記）。Intent / ストーリー / Unit 定義の `build` 表記を `develop` に統一した。
- **決定者**: AI（SoT 優先ルールに基づく自己解決。Intent レビュー Round 2 で codex 指摘により取りこぼし修正）
