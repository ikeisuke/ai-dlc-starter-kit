# Unit: T 中心アウトプット仕様 + `aggregate_issue_enabled` フラグ + cap 仕様 SoT 定義

## 概要

aidlc-retrospective skill の出力契約を「T 中心」に再定義し、`rules.retrospective.aggregate_issue_enabled` フラグ（既定 `false`）と cap 判定の意味を本 Unit で **単一 SoT** として定義する。実装利用（ループ起票実体 / 既定動作の cap 判定）は Unit 004 に委譲する。

## 含まれるユーザーストーリー

- ストーリー 1: T 中心アウトプット仕様 + `aggregate_issue_enabled` フラグ + cap 仕様 SoT 定義

## 充足する Intent 成功基準

- SC-01（SKILL.md / steps 冒頭 SoT 記載）
- SC-04（旧 v2.6.5 同等性 fixture オラクル整備）

## 責務

- `skills/aidlc-retrospective/SKILL.md` と `steps/retrospective.md` 冒頭への SoT 文言追加
- `config/defaults.toml`（aidlc / aidlc-setup 両側）への `rules.retrospective.aggregate_issue_enabled = false` 追加 + 二重 SoT CI ガード pass 確認
- skill 内に「`aggregate_issue_enabled` 仕様節」を新設し、`true` / `false` 時の動作差分（集約 vs T ループ）と cap 判定意味の連動を SoT として記述
- `skills/aidlc/scripts/lib/retrospective-api.sh` への `retrospective_api_aggregate_enabled` 判定 helper 追加（既存関数シグネチャ不変）
- `tests/fixtures/retrospective_v265_aggregate.json` 新規追加（SC-04 同等性オラクル fixture）
- fixture スキーマ + 正規化規則 SoT + 公開契約 helper を整備し、構造検証 bats（fixture スキーマ存在 / 正規化 helper 動作 / helper 公開契約）を Unit 001 段階で完了（**SC-04 二段階基準の Unit 001 段階責務 = fixture スキーマ + 正規化 SoT + helper + 構造検証 bats まで / `fixture_status="schema-only"` 状態で完了 / 差分 0 同等性 bats は Unit 004 finalize 責務**）

## 境界

- 本 Unit は仕様 SoT 定義と fixture **スキーマ整備 + 公開契約 helper + 正規化規則 SoT** までを担う
- **fixture 実値 finalize（SC-04 フル同等性 bats）は Unit 004 統合フェーズへ委譲**（v2.6.5 集約 Issue 実起票不在のため、Unit 004 で「v2.6.6 リリース時点 aggregate path コード生成 output」を SoT として実値確定 / 詳細は計画書「リスク」の二段階基準参照）
- §1.5 Issue 起票ループの実装本体は Unit 004 (ストーリー 4A) に委譲
- §1.2.5 セルフレビュー追加は Unit 002 に委譲
- 三層検証 helper の追加は Unit 003 に委譲

## 依存関係

### 依存する Unit

- なし

### 外部依存

- v2.6.5 リリース時点の集約 Issue 起票本文（fixture 生成のための参照データ / `.aidlc/cycles/v2.6.5/` 内の retrospective 関連 artifacts）

## 非機能要件（NFR）

- **パフォーマンス**: 起票 helper の追加は既存処理に対して 5% 以内のオーバーヘッド
- **セキュリティ**: 新規 fixture に GitHub トークン / 個人情報を含めない
- **後方互換性**: `aggregate_issue_enabled` 未設定環境（v2.6.5 以前の consumer プロジェクト）でアップグレード時にエラーが出ない（4 階層マージで `defaults.toml` から `false` が解決される）

## 技術的考慮事項

- `defaults.toml` 二重 SoT（aidlc / aidlc-setup）の同期は v2.6.5 Unit 004 で導入された CI 早期検出ガードに合致する記述形式で行う
- fixture の `normalize_volatile()` 対象項目（タイムスタンプ / セッション ID / 環境固有パス）は Unit 内で抽出規則を定義
- 仕様節は SKILL.md / steps/retrospective.md / 公開 API doc の **どこに置くか** を設計段階で確定（推奨: `steps/retrospective.md` 内 `§1.5 前置き` セクション）

## 関連Issue

- #710（CLOSED / 方針親 / 本サイクル PR で Comment）

## 実装優先度

High（Unit 004 の前提となる）

## 見積もり

0.5 営業日

---
## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 完了
- **開始日**: 2026-05-18
- **完了日**: 2026-05-18
- **担当**: AI-DLC (Claude Code / codex)
- **エクスプレス適格性**: 適格
- **適格性理由**: depth_level=standard / 設計レビュー 3R clean / 統合レビュー 3R clean / bats 22 件 (21 pass + 1 skip) / 二重 SoT sync ガード pass
