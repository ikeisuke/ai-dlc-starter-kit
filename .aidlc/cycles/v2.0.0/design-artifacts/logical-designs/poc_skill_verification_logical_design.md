# 論理設計: PoC - スキル機能検証

## 概要
テストスキルの構成・検証手順・判定ロジックを定義し、PoCの実行可能な検証計画を確立する。

**重要**: この論理設計では**コードは書かず**、コンポーネント構成とインターフェース定義のみを行います。

## アーキテクチャパターン
Claude Codeプラグイン・スキル機構に準拠したディレクトリ構成。各テストスキルは独立したSKILL.mdを持ち、プラグインとしてインストールされる。

## コンポーネント構成

### ディレクトリ構成

```text
prompts/poc/
├── skills/
│   ├── poc-read-test/          # 検証1: オンデマンドRead
│   │   ├── SKILL.md            # Read指示を含むスキル定義
│   │   └── steps/
│   │       └── sample-step.md  # マーカー文字列を含むステップファイル
│   ├── poc-caller/             # 検証2: スキル間呼び出し（caller側）
│   │   └── SKILL.md            # Skillツール呼び出し指示を含む
│   └── poc-callee/             # 検証2: スキル間呼び出し（callee側）
│       └── SKILL.md            # 固定応答を返す
└── CLAUDE.md                   # プラグインルート（プラグイン登録用）
```

### コンポーネント詳細

#### poc-read-test（オンデマンドRead検証スキル）
- **責務**: SKILL.md内のRead指示により、同一スキルディレクトリ内のsteps/sample-step.mdを読み込めるか検証
- **依存**: なし（単体で動作）
- **公開インターフェース**: スキル呼び出し時に `steps/sample-step.md` の内容を出力

#### poc-caller（スキル間呼び出し検証 - 呼び出し側）
- **責務**: Skillツールを使用して `poc-callee` スキルを呼び出し、応答を取得できるか検証
- **依存**: poc-callee
- **公開インターフェース**: `poc-callee` の応答を中継して出力

#### poc-callee（スキル間呼び出し検証 - 呼び出される側）
- **責務**: 呼び出された際に固定のマーカー文字列を含む応答を返す
- **依存**: なし（単体で動作）
- **公開インターフェース**: 固定応答 `[POC-CALLEE-RESPONSE-67890]` を出力

## インターフェース設計

### スキルインターフェース

#### poc-read-test SKILL.md
- **frontmatter**:
  - name: `poc-read-test`
  - description: PoC用 - オンデマンドRead検証
  - allowed-tools: Read
- **本文指示**: 「今すぐ `steps/sample-step.md` を読み込んで、その内容を出力してください」
- **期待出力**: `[POC-READ-MARKER-12345]` を含むテキスト

#### poc-caller SKILL.md
- **frontmatter**:
  - name: `poc-caller`
  - description: PoC用 - スキル間呼び出し検証（caller）
  - allowed-tools: なし（Skillツールはデフォルトで利用可能か検証）
- **本文指示**: 「Skillツールを使って `poc-callee` スキルを呼び出し、その応答を出力してください」
- **期待出力**: `[POC-CALLEE-RESPONSE-67890]` を含むテキスト
- **前提条件**: Skillツールがスキル実行コンテキスト内で利用可能であること
- **失敗時の分類**:
  - `tool-unavailable`: Skillツール自体がスキルコンテキストで利用不可
  - `callee-not-found`: Skillツールは利用可能だがpoc-calleeスキルが見つからない
  - `invocation-denied`: 呼び出しが権限等により拒否される

#### poc-callee SKILL.md
- **frontmatter**:
  - name: `poc-callee`
  - description: PoC用 - スキル間呼び出し検証（callee）
  - allowed-tools: なし
- **本文指示**: 「以下の固定応答を出力してください: `[POC-CALLEE-RESPONSE-67890]`」
- **期待出力**: `[POC-CALLEE-RESPONSE-67890]`

### CLAUDE.md（プラグインルート）
- **役割**: `prompts/poc/` をプラグインとして認識させるためのルートファイル
- **内容**: プラグインの説明（PoC検証用テストスキル集）

## ファイル形式

### 検証結果ドキュメント（unit001-poc-results.md）

```text
# PoC検証結果: スキル機能検証

## 検証1: オンデマンドRead
- capability: ondemand-read
- status: {supported / supported_with_constraints / unsupported}
- observed_output: {実際の出力}
- constraints: {制約条件があれば}
- decision: {採用する実装方針}

## 検証2: スキル間呼び出し
- capability: skill-invocation
- status: {supported / supported_with_constraints / unsupported}
- observed_output: {実際の出力}
- constraints: {制約条件があれば}
- decision: {採用する実装方針}

## v2.0.0 実装方針サマリ
{検証結果に基づく方針の要約}
```

## 処理フロー概要

### 検証1: オンデマンドRead の処理フロー

**ステップ**:
1. `poc-read-test/SKILL.md` と `poc-read-test/steps/sample-step.md` を作成
2. `prompts/poc/` をプラグインとしてインストール（手動: claude CLI のプラグインインストール機能を使用）
3. `/poc-read-test` を実行
4. 出力に `[POC-READ-MARKER-12345]` が含まれるか確認
5. 結果をCapabilityStatusで判定し記録

**判定ロジック**:
- 出力にマーカー含む → `supported`
- 絶対パス指定等の追加操作で読める → `supported_with_constraints`（制約を記録）
- マーカーが出力されない / エラー → `unsupported`

### 検証2: スキル間呼び出し の処理フロー

**ステップ**:
1. `poc-caller/SKILL.md` と `poc-callee/SKILL.md` を作成
2. プラグインインストール済み（検証1と同一プラグイン）
3. `/poc-caller` を実行
4. 出力に `[POC-CALLEE-RESPONSE-67890]` が含まれるか確認
5. 結果をCapabilityStatusで判定し記録

**判定ロジック**:
- calleeの応答が得られる → `supported`
- 制約付きで呼び出し可能 → `supported_with_constraints`（制約を記録）
- Skillツール呼び出しがエラーまたは無視 → `unsupported`

## 非機能要件（NFR）への対応

### パフォーマンス
- **要件**: 特になし（検証のみ）
- **対応策**: N/A

### セキュリティ
- **要件**: 特になし
- **対応策**: テストスキルには最小限のallowed-toolsのみ付与

## 技術選定
- **プラットフォーム**: Claude Code スキル・プラグイン機構
- **ファイル形式**: Markdown（SKILL.md / steps/*.md）

## 実装上の注意事項
- テストスキルは検証目的のみ。検証完了後に削除可能
- プラグインインストールはClaude Codeセッション内で手動実施（自動化不可）
- 検証はユーザーの手動操作（スキル実行）を含むため、完全自動化ではない

## 不明点と質問（設計中に記録）

現時点で不明点はありません。
