# Unit: Inception 直近サイクル完了 Unit との重複検出フロー SoT 化

## 概要

Inception Phase での Unit 定義策定時に、直近 N サイクルの完了 Unit スラグおよび関連 CLOSED Issue 番号と自動突合し、重複候補を AskUserQuestion で警告できるフローを `skills/aidlc/steps/inception/` に SoT として組み込む。v2.6.4 Unit 001（v2.6.3 Unit 004 と完全重複で取り下げ）の再発を構造的に予防する。

## 含まれるユーザーストーリー

- ストーリー 1: Inception での Unit 重複起案を未然に検出する

## 責務

- `skills/aidlc/steps/inception/04-stories-units.md` または相当ステップへ「直近サイクル完了 Unit との重複チェック」手順を追記
- 重複チェックの 3 ステップ（(a) スラグ一覧取得、(b) 関連 Issue 抽出、(c) Issue OPEN/CLOSED 状態確認）を SoT 化
- AskUserQuestion による「取り下げ / 継続（理由記録必須）」選択肢の仕様を明文化
- 直近 N サイクル数（既定 3）の config 解決ロジック仕様を策定
- 本サイクル自身の Inception でドッグフーディング検証実施 + 結果を `history/inception.md` に記録

## 境界

- 重複判定ロジックの自動ブロック化は行わない（警告のみ + AskUserQuestion）
- 既存 `phase-recovery-spec.md` の materialized binding 構造変更は対象外
- false positive を低減するためのスラグ正規化（複数形 / 略語展開等）は対象外（将来拡張）
- consumer プロジェクトへの追加配布物は伴わない（既存 `steps/inception/` 内で完結）

## 依存関係

### 依存する Unit

- なし

### 外部依存

- `gh issue view --json state`（Issue OPEN/CLOSED 状態確認）
- 既存 `scripts/read-config.sh`（直近 N サイクル数 config 解決）

## 非機能要件（NFR）

- **パフォーマンス**: 直近 3 サイクル × 平均 5 Unit × Issue 状態確認 1〜2 回 / Unit 程度の追加コスト（10 秒以内）
- **セキュリティ**: gh CLI 認証範囲内、追加権限要求なし
- **スケーラビリティ**: N サイクル数を config で調整可能（将来 5〜10 に拡張可）
- **可用性**: gh 不可用時は警告表示 + スキップ（フェーズ中断しない）

## 技術的考慮事項

- AskUserQuestion で「取り下げ」選択時は当該 Unit 定義ファイルを削除（または skip マーク）
- 「継続」選択時は当該 Unit 定義ファイルの末尾コメントとして「重複警告: <重複 Unit パス + 理由>」を機械可読形式（コメントブロック）で記録
- 既存 `04-stories-units.md` ステップ4 直後（Unit 定義承認前 AI レビュー前）に挿入
- Inception index.md の「2. 分岐ロジック」or「3. 判定チェックポイント表」への新行追加は本サイクルでは行わず、ステップ本文記述のみで完結

## 関連Issue

- #712（このサイクルで Closes）

## 実装優先度

High

## 見積もり

0.5〜1 日（手順追加 + ドッグフーディング検証）

---

## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
- **エクスプレス適格性**: -
- **適格性理由**: -
