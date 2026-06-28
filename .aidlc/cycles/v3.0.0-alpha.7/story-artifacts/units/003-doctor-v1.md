# Unit: doctor v1 実装 + 段階スコープ SoT 反映

## 概要

v3 に diagnosis コマンド `doctor` を shallow scope（8 領域 + parse-guard）で実装し、あわせて doctor の alpha.7/alpha.8 段階スコープを設計 SoT に明示反映する。解消済みの #733 をクローズする。

## 含まれるユーザーストーリー
- ストーリー 2: doctor で着手前診断
- ストーリー 5: doctor 段階スコープの SoT 一貫性 と #733 クローズ

## 責務
- `skills/aidlc-v3/scripts/doctor.sh` の新規作成（診断 + 推奨のみ / **自動修正しない**）。診断領域: `config` / `state`（`state-validate.sh` 再利用）/ `cycle` / `work-items`（`work-item-validate.sh` 再利用）/ `git` / `gh` / `pr`（native git・gh）/ `scripts`（必須スクリプト存在）+ 禁止パースパターン検出（`bin/check-frontmatter-parse-guard.sh` 相当の流用）。
- `skills/aidlc-v3/steps/doctor.md` の新規作成（出力仕様 / `[phase]`・`[trace]` は alpha.8 defer と明記）。
- `scripts/doctor.sh` の契約テストを `skills/aidlc-v3/scripts/tests/` に追加（最低: state.json 不在 / 破損 / work item frontmatter 不正 / 必須スクリプト不在 / git dirty・clean / gh 未認証 / active PR あり・なし / gh 未認証・不可時の pr 診断 / parse-guard 違反 / No active cycle / 全領域 OK 正常系）。
- `SKILL.md` の `doctor` を「予約」から実装済み（`steps/doctor.md` / `scripts/doctor.sh`）に更新。
- 段階スコープ SoT 反映: `docs/v3/workflow.md §3.6` の項目表に alpha.7/alpha.8 段階注記、`docs/v3-renewal-plan.md` の Phase 6 定義および doctor チェック項目一覧に段階注記、Epic #736 の Phase 6 完了条件を「alpha.7 = doctor shallow / phase・trace = alpha.8 必須 follow-up」へ更新。alpha.8 必須 follow-up を Epic #736 ロードマップまたは backlog Issue として切り出し。
- #733（v3系通し振り返り）を alpha.4 完了証跡コメント付きでクローズ。

## 境界
- `[phase]` 導出 code 化・`[trace]` 整合チェックの**実装**は行わない（alpha.8 defer / SoT への defer 反映のみ）。
- doctor は自動修正・状態変更をしない（診断のみ）。
- reflect / status / #735 は扱わない（別 Unit）。

## 依存関係

### 依存する Unit
- なし

### 外部依存
- 既存スクリプト: `state-validate.sh` / `work-item-validate.sh` / `read-config.sh`
- `bin/check-frontmatter-parse-guard.sh`（parse-guard 流用元）
- native `git` / `gh`
- `docs/v3/workflow.md §3.6`（SoT 参照）

## 非機能要件（NFR）
- **パフォーマンス**: shallow check（既存スクリプト wrap + 軽診断）。
- **セキュリティ**: 診断出力に機密情報（トークン等）を含めない。
- **スケーラビリティ**: 診断領域は段階追加可能な構造（alpha.8 で phase/trace 追加）。
- **可用性**: `gh` 不可用時は `[gh]`/`[pr]` を WARN/skip し他領域診断は継続。

## 技術的考慮事項
- 新規ロジックを最小化し既存スクリプト再利用を優先（renewal-plan の doctor 設計）。
- exit code 規約（`guides/exit-code-convention.md`）に整合させる（診断結果と終了コードの設計をガイド照合）。

## 関連Issue
- Relates to #736（v3 リニューアル Epic / Phase 6）
- Closes #733（alpha.4 で Try 全件実装・CI ガード済み / 本 Unit でクローズ）

## 実装優先度
High

## 見積もり
1 サイクル日相当（doctor.sh + 契約テスト + doctor.md + SoT 反映 + #733 クローズ）

---
## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
- **エクスプレス適格性**: -
- **適格性理由**: -
