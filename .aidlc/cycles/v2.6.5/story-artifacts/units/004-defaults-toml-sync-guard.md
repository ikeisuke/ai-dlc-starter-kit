# Unit: defaults.toml 二重 SoT 同期ガード（CI 早期検出）

## 概要

`skills/aidlc/config/defaults.toml`（本体）と `skills/aidlc-setup/config/defaults.toml`（consumer 配布用）のキー差分を CI で自動検出する Defaults TOML Sync チェックジョブを `.github/workflows/` に追加（既存があれば強化）し、Construction Phase 早期に同期漏れを検出できるようにする。v2.6.4 Unit 004 の修復コミット 421c5ac1 を踏まえた構造的予防。

## 含まれるユーザーストーリー

- ストーリー 4: defaults.toml 二重 SoT の同期漏れを CI で早期検出する

## 責務

- `.github/workflows/` の Defaults TOML Sync チェックジョブの新規追加または既存ジョブ強化（PR トリガー）
- 比較ロジック: `skills/aidlc/config/defaults.toml` 正本 vs `skills/aidlc-setup/config/defaults.toml` のキー集合・型一致確認
- CI fail 出力フォーマット: 不足キー一覧 + 修復方法（正本に合わせて同期 or 削除）の明示
- starter kit 自己リポジトリ専用 CI ジョブとして配置（consumer 配布物にしない）
- 本 Unit 自身で「同期崩し → CI red」「同期復元 → CI green」の遷移を再現検証
- （追加達成条件 / 任意）Unit 完了処理段階での自動同期スクリプト同梱のトレードオフ評価（Construction Phase Unit 4 設計時）

## 境界

- defaults.toml の構造変更（共通テンプレ展開等）は対象外（intent §含まれないもの 参照）
- consumer プロジェクトへ追加配布する CI ジョブ・スクリプトは作らない
- 既存「マージ前 CI 通過確認」（v2.6.3 Unit 004 / `operations-release.md §7.12.6`）の改修は対象外
- 旧 `[rules.backlog]` deprecated セクション等の defaults 整理は別 Issue（#640 / #646）スコープ、本 Unit では対象外

## 依存関係

### 依存する Unit

- **ハード依存**: なし（CI ジョブ追加 + failing→green 検証は U4 単独で完結する）
- **ソフト依存（推奨）**: U2（事前コード Read 工程組み込み）の改修完了後であれば、U2 で定めた「事前コード Read」セクションを Phase 1 設計時にドッグフーディングできる。U2 未完了でも U4 は独立に進められる（U4 設計時の aidlc-setup 側 defaults.toml の事前 Read は本 Unit 自身の Phase 1 として通常通り実施する）

### 外部依存

- GitHub Actions ランナー（既存環境利用）
- dasel CLI（既存依存）または diff コマンド（OS 標準）

## 非機能要件（NFR）

- **パフォーマンス**: CI 実行時間に 30 秒以内の追加
- **セキュリティ**: 影響なし（read-only 比較のみ）
- **スケーラビリティ**: 他の二重 SoT 検出にも汎用化可能なジョブ構造
- **可用性**: CI ランナー停止時は他ジョブと同様に失敗扱い

## 技術的考慮事項

- CI ジョブの実装は bash + dasel または bash + grep/comm の単純比較で十分（複雑な TOML diff ライブラリ依存は避ける）
- 「ドッグフーディング特殊処理を本体に埋めない」原則を遵守: 検出ロジックを本体スクリプト内に分岐として埋めず、`.github/workflows/` の独立ジョブとして配置
- aidlc-setup 側の defaults.toml の構造（キー階層・配列扱い）を本 Unit 自身の Phase 1 設計時に Read で確認する（U2 が完了済みであればその「事前コード Read」セクション仕様でドッグフーディングする / U2 未完了でも本 Unit Phase 1 設計の前提作業として独立に実施する）
- 追加達成条件の同期スクリプトは `skills/aidlc/scripts/` 配下、汎用ユーティリティ化（特定スキル依存禁止）

## 関連Issue

- #714（このサイクルで Closes）

## 実装優先度

High

## 見積もり

0.5〜1 日（CI ジョブ追加 + failing→green 検証 + 任意の同期スクリプト評価）

---

## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 完了
- **開始日**: 2026-05-17
- **完了日**: 2026-05-17
- **担当**: AI (Claude Code)
- **エクスプレス適格性**: -
- **適格性理由**: -
