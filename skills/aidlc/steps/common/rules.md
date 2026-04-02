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

これらの確認は「AskUserQuestion使用ルール」セクションでは主に「ユーザー選択」として扱う。

### 不明点の記録

独自の判断をせず、不明点はドキュメントに `[Question]` / `[Answer]` タグで記録する。

## 承認プロセス【重要】

計画・設計等の成果物はユーザーの承認を得てから次ステップへ進む。

- `automation_mode=semi_auto`: フォールバック条件に該当しなければ自動承認（セミオートゲート仕様を参照）
- `automation_mode=manual`: ユーザーの明示的な肯定返答が必要

## AskUserQuestion使用ルール【重要】

ユーザーとの対話場面を3種類に分類し、種別に応じた適切なツール使用を定義する。

### インタラクション種別と対応方法

| 種別 | 説明 | 対応方法 | `semi_auto` での扱い | 具体例 |
|------|------|---------|---------------------|--------|
| ゲート承認 | フェーズ/ステップの進行承認 | セミオートゲート仕様に従う | `auto_approved` / `fallback` で判定 | 「この設計で進めてよろしいですか？」「計画を承認しますか？」 |
| ユーザー選択 | 複数の選択肢からユーザーが1つを選ぶ場面 | `AskUserQuestion` 必須 | 自動化対象外（常に `AskUserQuestion`） | 「マージ方法を選んでください」「force pushしてよろしいですか？」「どのUnitから着手しますか？」 |
| 情報収集 | ユーザーからの自由入力やコンテキスト提供が必要な場面 | `AskUserQuestion` 必須 | 自動化対象外（常に `AskUserQuestion`） | 「今回取り組みたい内容は何ですか？」「追加コンテキストを教えてください」 |

### セミオートゲート仕様との関係

本セクションはセミオートゲートの**対象範囲**（どの種類のインタラクションが自動化対象か）を定義する。判定ロジック自体（`automation_mode`, `reason_code`, `auto_approved`, `fallback` の処理フロー）は既存のセミオートゲート仕様に委譲する。

- **ゲート承認のみ**がセミオートゲート仕様の対象。`automation_mode=semi_auto` 時にフォールバック条件に該当しなければ `auto_approved` となる
- **ユーザー選択**と**情報収集**は `automation_mode` に関わらず常に `AskUserQuestion` ツールを使用する。テキスト出力のみで代替してはならない

### 各種別の入出力契約

| 種別 | 入力 | 出力 | ツール |
|------|------|------|--------|
| ゲート承認 | 承認ポイントID、成果物 | `manual`: ユーザー承認結果 / `semi_auto`: `auto_approved` / `fallback` | セミオートゲート仕様に委譲 |
| ユーザー選択 | 選択肢リスト、コンテキスト | ユーザーの選択結果 | `AskUserQuestion`（選択肢提示） |
| 情報収集 | 質問文、コンテキスト | ユーザーの自由入力 | `AskUserQuestion`（自由入力） |

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

## スコープ保護ルール【重要】

Intentの「含まれるもの」に記載された要件を制限・除外する判断（スコープ縮小）は、`automation_mode` に関わらずユーザー確認を必須とする。

**スコープ縮小の定義**: レビュー指摘への対応やその他の判断で、Intentの「含まれるもの」セクションに列挙された要件の全部または一部を実装対象から除外すること。

**適用条件**: `automation_mode`（`manual` / `semi_auto`）やエクスプレスモードの有無に関わらず、常時適用する。

**実行ポイント**: 実際の強制は `review-flow.md` の「指摘対応判断フロー」で実施する。OUT_OF_SCOPE選択時にIntent内要件への影響を判定し、該当する場合はユーザー確認を必須とする。詳細は `review-flow.md` の「スコープ保護確認」セクションを参照。

**判定不能時**: Intentの「含まれるもの」セクションが存在しない、または対象の該当性が曖昧な場合は、ユーザー確認へフォールバックする（安全側に倒す）。

## 改善提案のバックログ登録ルール【重要】

改善提案を行う場合は**必ずバックログに登録**すること。口頭提案のみは禁止。

1. **スコープチェック**: Intent「含まれるもの」に該当する場合は現サイクル内で処理（バックログに外出ししない）
   - **例外**: 「スコープ保護ルール」に基づきユーザーが明示的にOUT_OF_SCOPEを承認した場合は、Intent内要件であってもバックログ登録を許可する（ユーザー承認済みのスコープ縮小）
2. 該当しない場合: GitHub Issueに記録（`guides/backlog-management.md` 参照）

## コード品質基準

コード品質基準、Git運用の原則は `.aidlc/rules.md` を参照。
