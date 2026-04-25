# Unit: 必須 Checks の常時 PASS 報告化

## 概要

v2.3.6 で導入した paths フィルタ + Draft skip により、required check が "Expected — Waiting for status to be reported" のまま報告されず PR が merge 不可になる事象（#598）を、3 workflow に常時 PASS 報告の仕組みを追加することで解消する。

## 含まれるユーザーストーリー

- ストーリー 2: 必須 Checks が paths フィルタ / Draft skip 下でも PASS 報告される

## 責務

- `.github/workflows/pr-check.yml` / `.github/workflows/migration-tests.yml` / `.github/workflows/skill-reference-check.yml` の 3 workflow に、required check が常時 PASS 状態で報告される仕組みを追加する
- 実装方式は Construction Phase の設計レビューで 2 案から選定（outcome は同一）
- 既存 check 名（`Markdown Lint` / `Bash Substitution Check` / `Defaults TOML Sync Check` / `Migration Script Tests` / `Skill Reference Check`）を維持する
- v2.3.6 の Draft skip による runner 課金抑制効果を維持する
- 検証ケース1（workflow 変更系）は本サイクル自身の PR（`.github/workflows/*.yml` 変更を含む）で確認、検証ケース2（paths 非該当）は `skills/aidlc/scripts/*.sh` のみ変更するダミー PR または同等条件を再現した検証で確認する（2 ケースを分けて動作確認する）

## 境界

- Branch protection の required checks 一覧を変更しない（check 名維持）
- runner 時間の大幅増加を伴う設計（例: 常時 full-run）は避ける
- `.github/workflows/*.yml` 以外のファイル（例: workflow ロジックを含むスクリプト）を本 Unit では変更しない（別 Unit に分割するほどの追加変更が必要になった場合は Unit 再定義）
- GitHub Merge Queue（`merge_group` イベント）への移行は本サイクル外

## 依存関係

### 依存する Unit

- なし（他 Unit と独立、並列実装可能）

### 外部依存

- GitHub Actions ランタイム仕様（job 結果報告、`if:` 条件、`paths:` フィルタ、`conclusion: success` の扱い）
- Branch protection の required checks 一覧（変更しないが、check 名の一致確認のため参照）

## 非機能要件（NFR）

- **パフォーマンス**: Draft 中や paths 非該当時の runner 利用時間は、対象ジョブ本体のスキップ維持 + 報告処理は最低限（10 秒未満目安）
- **セキュリティ**: workflow 権限は最低限（`permissions: contents: read` 相当）を維持
- **スケーラビリティ**: 該当なし
- **可用性**: 既存 workflow の PASS 動作（対象パスの実変更時）を破壊しない

## 技術的考慮事項

- 案1（独立の報告 job を追加）と 案2（既存 job 内の PASS step 追加）のどちらを採用するかは Construction Phase 設計レビューで確定
  - 案1: 各 workflow に `report-status` 相当の job を追加し、paths 非該当/Draft でも発火して対象 job 結果を受けて check 名で PASS/FAIL を報告
  - 案2: 対象 job 側で `if:` による skip 条件下に常に PASS を返す step を追加
- 設計選定時には GitHub Actions の既知制約（`needs:` による依存、`if: always()` の扱い、`conclusion` 報告仕様）を考慮
- 動作確認は 2 ケースに分けて実施:
  - **検証ケース1（workflow 変更系）**: 本サイクル自身の PR（`.github/workflows/*.yml` 変更を含む）で、paths 該当 + Ready 状態での PASS 報告を確認
  - **検証ケース2（paths 非該当）**: `skills/aidlc/scripts/*.sh` のみ変更するダミー PR（別 PR として立てる）、または同等条件を再現した検証（例: paths 非該当を意図したテストコミット）で PASS 報告を確認
- Branch protection 設定変更は行わないため、本 Unit 内で check 名一覧を一貫させるレビューが必要

## 関連Issue

- #598

## 実装優先度

High

## 見積もり

設計レビュー 0.5 日 + 実装 0.5〜1 日 + 動作確認 0.5 日 の合計 1.5〜2 日規模

---
## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 完了
- **開始日**: 2026-04-25
- **完了日**: 2026-04-25
- **担当**: Claude (Opus 4.7)
- **エクスプレス適格性**: -
- **適格性理由**: エクスプレスモード無効（通常フロー）
