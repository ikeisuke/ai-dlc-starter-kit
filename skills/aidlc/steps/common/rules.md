# 共通開発ルール

以下のルールは全フェーズで共通して適用されます。

## 設定読み込み【重要】

AI-DLCの設定は `.aidlc/config.toml` と `.aidlc/config.local.toml`（個人設定）からマージして取得する。

```bash
# 単一キー
scripts/read-config.sh <key>

# バッチモード
scripts/read-config.sh --keys <key1> [key2] ...
```

- 終了コード: 0=値あり、1=キー不在、2=エラー
- `.local` の値は上書き、配列は完全置換。詳細は `guides/config-merge.md` を参照

## 質問と実行の判断基準【重要】

実行前に以下の2条件を確認する:

1. **要件を1文で言い換えられるか**
2. **実装アプローチが1つに絞れるか**

両方Yesなら直接実行。どちらかNoなら質問する。

### 質問フロー

1. 質問の数と概要を先に提示
2. 1問ずつ詳細を質問し、回答を待つ
3. 回答に基づく追加質問が発生した場合は明示して質問

### 質問不要でも確認が必要な場面

- 破壊的操作（データ削除、force push等）
- 機密情報の取り扱い

### 不明点の記録

独自の判断をせず、不明点はドキュメントに `[Question]` / `[Answer]` タグで記録する。

## 承認プロセス【重要】

計画・設計等の成果物はユーザーの承認を得てから次ステップへ進む。

- `automation_mode=semi_auto`: フォールバック条件に該当しなければ自動承認（セミオートゲート仕様を参照）
- `automation_mode=manual`: ユーザーの明示的な肯定返答が必要

## Gitコミットのルール

コミットタイミング、メッセージフォーマット、Co-Authored-By設定は `steps/common/commit-flow.md` を参照。

## Depth Level仕様【重要】

成果物詳細度の3段階制御。設定キー: `rules.depth_level.level`（デフォルト: `standard`）

| レベル | 用途 |
|--------|------|
| `minimal` | シンプルなバグ修正・小規模変更。設計省略可 |
| `standard` | 通常の機能開発（デフォルト） |
| `comprehensive` | 複雑な機能開発。リスク分析・代替案検討を追加 |

### レベル別成果物要件

| フェーズ | 成果物 | minimal | standard | comprehensive |
|---------|--------|---------|----------|---------------|
| Inception | Intent | 1-2文 | 背景・目的・スコープ | + リスク分析・代替案 |
| Inception | ストーリー | 主要ケースのみ | INVEST準拠 | + エッジケース網羅 |
| Inception | Unit定義 | 最小限 | 完全な責務・境界・依存 | + 技術的リスク評価 |
| Construction | 設計 | スキップ可 | ドメインモデル+論理設計 | + シーケンス図・状態遷移図 |
| Construction | コード・テスト | 通常通り | 通常通り | + 統合テスト強化 |

無効値の場合は `standard` にフォールバックする。

## エクスプレスモード仕様

`/aidlc express` で有効化。Inception→Construction→Operationsを自動遷移する。

### 適用条件（すべて満たす場合に有効）

1. `express_enabled=true`
2. 全Unitの複雑度判定が `eligible`
3. Unit数が1以上

### 複雑度判定

| 評価項目 | eligible | ineligible |
|----------|----------|------------|
| 受け入れ基準 | 具体的で検証可能 | 曖昧・未定義 |
| 依存関係 | 線形 | 循環・多段分岐 |
| 技術的リスク | 既知技術 | 未使用技術・アーキ変更 |
| 変更影響範囲 | 限定的 | 不明確・横断的 |

### 有効時の動作

- Inception完了後のコンテキストリセットをスキップし、Constructionに自動遷移
- `depth_level=minimal`: Phase 1（設計）をスキップ
- `depth_level=standard/comprehensive`: Phase 1から通常実行
- 適用条件を満たさない場合は通常フローにフォールバック

## セミオートゲート仕様【重要】

`automation_mode=semi_auto` の場合、承認ポイントでフォールバック条件に該当しなければ自動承認する。

### 判定ロジック

1. `manual` → 従来フロー（全承認ポイントでユーザー確認）
2. `semi_auto` → グローバルフォールバック評価 → 固有フォールバック評価 → 該当なしなら `auto_approved`

### グローバルフォールバック条件

設定読取失敗（exit code 2）、実行エラー、前提情報の欠落

### フォールバック条件テーブル

| 優先度 | reason_code | 条件 |
|--------|-------------|------|
| 0 | `review_not_executed` | AIレビュー未実施 |
| 1 | `error` | ビルド/テスト失敗 |
| 2 | `review_issues` | `unresolved_count > 0` |
| 3 | `incomplete_conditions` | 完了条件に未達成項目 |
| 4 | `decision_required` | 技術的判断が必要 |

`auto_approved` の条件: `unresolved_count == 0`（全件が修正済みまたは判断フロー完了）

### レビュー結果シグナル

review-flow.md が生成し、ゲート判定で参照する。承認ポイント内でのみ有効。

| シグナル | 型 | 説明 |
|---------|-----|------|
| `review_detected` | boolean | 1件以上の指摘が検出されたか |
| `deferred_count` | integer | OUT_OF_SCOPE + TECHNICAL_BLOCKER 件数 |
| `resolved_count` | integer | 修正済み件数 |
| `unresolved_count` | integer | 未対応件数 |

### 構造化シグナル

| 結果 | reason_code | 条件 |
|------|-------------|------|
| `auto_approved` | `none` | フォールバック条件に該当しない |
| `fallback` | 上記テーブルの値 | フォールバック条件に該当 |

### 承認ポイントID

`{phase}.{context}.{step}` 形式（例: `construction.plan.approval`）

## 設定仕様リファレンス

以下の設定は `read-config.sh` で読み取る。無効値は各デフォルトにフォールバック。

| 設定キー | デフォルト | 有効値 |
|---------|----------|--------|
| `rules.upgrade_check.enabled` | `false` | `true` / `false` |
| `rules.construction.max_retry` | `3` | 0以上の整数 |
| `rules.preflight.enabled` | `true` | `true` / `false` |
| `rules.preflight.checks` | `['gh', 'review-tools', 'config-validation']` | 有効値の組み合わせ |

## 改善提案のバックログ登録ルール【重要】

改善提案を行う場合は**必ずバックログに登録**すること。口頭提案のみは禁止。

1. **スコープチェック**: Intent「含まれるもの」に該当する場合は現サイクル内で処理（バックログに外出ししない）
2. 該当しない場合: GitHub Issueに記録（`guides/backlog-management.md` 参照）

## コード品質基準

コード品質基準、Git運用の原則は `.aidlc/rules.md` を参照。
