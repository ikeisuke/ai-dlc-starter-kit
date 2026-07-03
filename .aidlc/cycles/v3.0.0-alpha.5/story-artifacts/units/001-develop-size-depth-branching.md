# Unit: develop size×depth_level 分岐基盤

## 概要
`skills/aidlc-v3/steps/develop.md` の「normal/risky 未サポート停止」を解除し、work item の `size` と cycle の `depth_level` を解決して `data-model.md` §8 マトリクスに基づき後続 Step（設計・レビュー）の実行可否を決める分岐基盤を実装する。本 Unit 単体で `normal + minimal`（実装 + テストのみ）が end-to-end で完走できる状態を作る。

## 含まれるユーザーストーリー
- ストーリー 1: size 分岐で normal/risky が停止せず進む

## 責務
- develop.md Step 1 の `size != tiny` 停止ブロックを分岐に置換
- `depth_level` を `.aidlc/config.toml` から解決する（既存 `read-config.sh` 等を利用。未設定時 `standard`）
- size×depth_level 判定: 成果物・レビュー要否を §8 マトリクスから決定するロジック（後続 Step が参照する単一の判定結果）
- `normal + minimal`: Step 2 / Step 5 をスキップし実装 + テスト + 完了まで進む（end-to-end）
- `risky + minimal`: 「risky は minimal 不可」としてエラー停止（mutation なし／副作用なし）
- `tiny + comprehensive`: §8 に従い「短い理由記録」を追加する（journal への 1 行理由記録等。tiny + {minimal, standard} は Phase 3 挙動から不変＝非回帰）
- `designs/` / `reviews/` 出力先パスの解決・配線（生成自体は Unit 002 / 003）

## 境界
- 設計成果物の生成・design template（Unit 002 の責務）
- レビューのルーティング・実行（Unit 003 の責務）
- 回帰テストの追加（Unit 004 の責務。本 Unit では最小の動作確認のみ）

## 依存関係

### 依存する Unit
- なし（develop フローの基盤。他 Unit が本 Unit に依存する）

### 外部依存
- `skills/aidlc/scripts/read-config.sh`（depth_level 読取、公開 API スクリプト）
- `skills/aidlc-v3/scripts/work-item-next.sh` / `work-item-status.sh` / `state-read.sh`（既存）

## 非機能要件（NFR）
- **パフォーマンス**: 既存 tiny フローの実行時間に有意な追加負荷を与えない
- **セキュリティ**: 該当なし（ローカルファイル操作のみ）
- **スケーラビリティ**: 該当なし
- **可用性**: depth_level 読取失敗時は安全側（standard）にフォールバックし停止しない

## 技術的考慮事項
- 判定の正本は `data-model.md` §8。size は work item frontmatter、depth_level は config.toml。
- frontmatter / status のパースは既存安全境界スクリプト（`work-item-status.sh` / `lib/frontmatter.sh`）を経由し、develop.md 内で grep/sed の局所パースを足さない（#733 P1/P2 再発防止）。
- 「ドッグフーディング特殊処理の禁止」: 自リポジトリ判定を埋め込まない。

## 関連Issue
- #736（部分対応 / Phase 4）

## 実装優先度
High

## 見積もり
0.5〜1 セッション

---
## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 完了
- **開始日**: 2026-06-25
- **完了日**: 2026-06-25
- **担当**: -
- **エクスプレス適格性**: -
- **適格性理由**: -
