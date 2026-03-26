# Unit 001 計画: PoC - スキル機能検証

## 概要

Claude Codeスキルの2つの技術的前提条件を検証するPoCを実施する。
1. **オンデマンドRead**: スキルのSKILL.md内のRead指示でsteps/ファイルを相対パスで読めるか
2. **スキル間呼び出し**: テストスキルAからSkillツールでテストスキルBを呼べるか

検証結果に基づき、v2.0.0の実装方針（パス解決戦略・スキル間連携戦略）を確定する。

## 変更対象ファイル

### 作成するファイル
- `prompts/poc/skills/poc-read-test/SKILL.md` — Read検証用テストスキル
- `prompts/poc/skills/poc-read-test/steps/sample-step.md` — 読み込み対象のステップファイル
- `prompts/poc/skills/poc-caller/SKILL.md` — スキル間呼び出し検証用テストスキル（呼び出し側）
- `prompts/poc/skills/poc-callee/SKILL.md` — スキル間呼び出し検証用テストスキル（呼び出される側）
- `docs/cycles/v2.0.0/design-artifacts/poc-results/unit001-poc-results.md` — 検証結果ドキュメント

### 既存ファイルの変更
- `docs/cycles/v2.0.0/story-artifacts/units/001-poc-skill-verification.md` — 実装状態の更新

## 実装計画

### Phase 1: 設計（depth_level=standard）

1. **ドメインモデル設計**: PoCのスコープ（検証項目・判定基準・フォールバック戦略）を構造化
2. **論理設計**: テストスキルの具体的な構成・検証手順・判定ロジックを定義
3. **設計レビュー**: AIレビュー後、承認

### Phase 2: 実装

#### ステップ4: テストスキル作成

**検証1: オンデマンドRead**
- `poc-read-test` スキルを作成
- SKILL.mdに「steps/sample-step.md を読み込んでください」の指示を含める
- `steps/sample-step.md` にマーカー文字列 `[POC-READ-MARKER-12345]` を記載
- 判定基準:
  - `supported`: マーカー文字列がコンテキストに出力される（相対パスで解決成功）
  - `supported_with_constraints`: 絶対パス指定等の条件付きで読み込み可能
  - `unsupported`: Read指示が無視される、またはファイル不在エラー

**検証2: スキル間呼び出し**
- `poc-caller` スキル（Skillツールで `poc-callee` を呼ぶ指示を含む）を作成
- `poc-callee` スキル（固定応答 `[POC-CALLEE-RESPONSE-67890]` を返す指示を含む）を作成
- 判定基準:
  - `supported`: `poc-callee` の固定応答がcaller側で取得できる
  - `supported_with_constraints`: 呼び出しは可能だが制約あり（引数渡し不可等）
  - `unsupported`: Skillツール呼び出しがエラーまたは無視される

#### ステップ5: 検証実行・結果記録

各検証について以下のスキーマで記録:
- `capability`: オンデマンドRead / スキル間呼び出し
- `status`: supported / supported_with_constraints / unsupported
- `observed_output`: 実際の出力またはエラーメッセージ
- `constraints`: 制約条件（status=supported_with_constraintsの場合）
- `decision`: 採用する実装方針

#### ステップ6: 結果ドキュメント化・方針確定

**オンデマンドRead**:
- `supported`: steps/ディレクトリによるステップ分割方式を採用
- `supported_with_constraints`: 制約を明記した上でステップ分割方式を採用
- `unsupported`: @参照フォールバック（SKILL.md本文に全内容を含める）

**スキル間呼び出し**:
- `supported`: reviewing-*スキルをSkillツール経由で直接呼び出し
- `supported_with_constraints`: 制約を明記した上でSkillツール経由で呼び出し
- `unsupported`: review-flow内にレビュー実行アダプタを設け、外部CLIによるレビュー実行にフォールバック（reviewing-*の内容コピーは行わず、既存のcodex/claude/gemini CLIベースのレビュー実行パスを維持）

## 完了条件チェックリスト

- [x] テストスキルを作成しプラグインとしてインストール
- [x] オンデマンドRead: SKILL.md内のRead指示でsteps/ファイルを相対パスで読めるか検証 → **supported**
- [x] スキル間呼び出し: テストスキルAからSkillツールでテストスキルBを呼べるか検証 → **supported**
- [x] 検証結果に基づくフォールバック戦略の確定・ドキュメント化 → 両方supported、フォールバック現時点で不要
