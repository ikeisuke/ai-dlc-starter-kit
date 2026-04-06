# 論理設計: Reviewingスキル共通基盤抽出

## 概要

9つのReviewingスキルの共通セクションを正本ファイルに集約し、各スキルへの配布・参照の仕組みを設計する。

**重要**: この論理設計では**コードは書かず**、コンポーネント構成とインターフェース定義のみを行います。

## アーキテクチャパターン

**Source of Truth + Distribution パターン**: 共通コンテンツの正本を1箇所に管理し、配布スクリプトで各消費先に複製する。プラグインキャッシュへの個別展開時にもクロススキル参照が不要になる。

## コンポーネント構成

### ディレクトリ構成

```text
skills/
├── reviewing-common/                    ← 新規: 正本ディレクトリ
│   └── reviewing-common-base.md         ← 正本（source of truth）
├── reviewing-construction-code/
│   ├── SKILL.md                         ← 簡素化（固有セクションのみ）
│   └── references/
│       ├── reviewing-common-base.md     ← 配布先（正本のコピー）
│       └── session-management.md        ← 変更なし
├── reviewing-construction-design/
│   ├── SKILL.md
│   └── references/
│       ├── reviewing-common-base.md
│       └── session-management.md
│   ... (他7スキルも同構成)
bin/
└── sync-reviewing-common.sh             ← 新規: 配布スクリプト
```

### コンポーネント詳細

#### reviewing-common-base.md（正本）

- **責務**: 全Reviewingスキルの外部ツール実行基盤を一元管理
- **依存**: session-management.md（セッション継続セクション内でリンク参照）
- **公開インターフェース**: Markdownドキュメントとして参照される
- **外部依存（間接）**: review-flow.md がスキル起動時のフロー制御で共通基盤の情報を前提とする

**構成セクション**:

```text
# Reviewingスキル共通基盤
├── ## 実行コマンド
│   ├── ### Codex
│   ├── ### Claude Code
│   └── ### Gemini
├── ## セッション継続
├── ## 外部ツールとの関係
│   └── 責務の分離
└── ## セルフレビューモード
    ├── ### 手順
    ├── ### 実行方式
    ├── ### サブエージェントへの指示テンプレート
    └── ### 制約
```

#### 簡素化後のSKILL.md（各スキル）

- **責務**: スキル固有の識別情報とレビュー観点を管理
- **依存**: `references/reviewing-common-base.md`（Read指示による遅延参照）
- **公開インターフェース**: Claude Codeスキルハーネスから呼び出される

**構成テンプレート**:

```text
---
(frontmatter: name, description, argument-hint, compatibility, allowed-tools)
---
# [スキルタイトル]
[スキル説明]
(focusメタデータ: 該当スキルのみ)

## レビュー観点
(各スキル固有のレビュー観点)
(N/A判定ガイダンス: reviewing-construction-codeのみ)

## 共通基盤
実行コマンド・セッション継続・外部ツールとの関係・セルフレビューモードは `references/reviewing-common-base.md` を参照。
```

#### sync-reviewing-common.sh（配布スクリプト）

- **責務**: 正本から9スキルの `references/` への複製と整合性検証
- **依存**: 正本ファイル、9スキルのディレクトリ構成

## スクリプトインターフェース設計

### sync-reviewing-common.sh

#### 概要

正本（`skills/reviewing-common/reviewing-common-base.md`）を9つのReviewingスキルの `references/` にコピーする。

#### 引数

| 引数 | 必須/任意 | 説明 |
|------|----------|------|
| `--dry-run` | 任意 | 実際のコピーを行わず、差分のみ表示 |
| `--verify` | 任意 | コピー後の整合性検証のみ実行 |

#### 成功時出力

```text
sync: skills/reviewing-construction-code/references/reviewing-common-base.md (updated)
sync: skills/reviewing-construction-design/references/reviewing-common-base.md (unchanged)
...
sync: 9/9 files checked, N updated
```

- 終了コード: `0`
- 出力先: stdout

#### エラー時出力

```text
error: source file not found: skills/reviewing-common/reviewing-common-base.md
```

- 終了コード: `1`（正本不在）、`2`（引数エラー）
- 出力先: stderr

#### 使用コマンド

```bash
# 通常の配布
bin/sync-reviewing-common.sh

# dry-runで差分確認
bin/sync-reviewing-common.sh --dry-run

# 整合性検証のみ
bin/sync-reviewing-common.sh --verify
```

#### 配布先リスト（ハードコード）

```text
skills/reviewing-construction-code/references/
skills/reviewing-construction-design/references/
skills/reviewing-construction-integration/references/
skills/reviewing-construction-plan/references/
skills/reviewing-inception-intent/references/
skills/reviewing-inception-stories/references/
skills/reviewing-inception-units/references/
skills/reviewing-operations-deploy/references/
skills/reviewing-operations-premerge/references/
```

## 処理フロー概要

### 共通基盤更新フロー

**ステップ**:
1. 正本（`skills/reviewing-common/reviewing-common-base.md`）を編集
2. `bin/sync-reviewing-common.sh` を実行して9スキルに配布
3. `git diff` で差分確認
4. コミット

**関与するコンポーネント**: reviewing-common-base.md（正本）、sync-reviewing-common.sh、9スキルの references/

### スキル起動時の参照フロー

**ステップ**:
1. Claude Codeスキルハーネスが SKILL.md を読み込む（固有セクションのみ、軽量）
2. レビュー実行時に `references/reviewing-common-base.md` をRead
3. 共通基盤の実行コマンド/セルフレビュー手順に従ってレビュー実行

**関与するコンポーネント**: SKILL.md、reviewing-common-base.md（配布先）

### 共通基盤欠落時のフォールバック

**最小契約（SKILL.md単体で保証する情報）**:
- frontmatter（スキル識別・allowed-tools）: スキルハーネスが正常に読み込める
- レビュー観点: セルフレビュー時のレビュー基準として十分
- 参照指示テキスト: 共通基盤の存在を示す（Read失敗時にエラーの原因が分かる）

**フォールバックフロー**:
1. SKILL.md読み込み（正常: frontmatter + レビュー観点が完結）
2. `references/reviewing-common-base.md` のRead失敗
3. 外部CLIコマンド情報が参照不可 → review-flow.md既存フォールバック（CLI不在→セルフレビュー→ユーザーレビュー）で吸収
4. セルフレビューモード: SKILL.md内のレビュー観点に基づき、メインエージェント自身がインラインレビューを実行（サブエージェント指示テンプレートは不要。review-flow.mdのパス2セルフレビューがスキル呼び出し時にレビュー観点を引数に含めるため）

**注**: インライン方式のフォールバックはSKILL.md側に追加情報を保持する必要がない。review-flow.mdがセルフレビュースキル呼び出し時に `args="self-review [対象ファイル]"` を渡し、スキル側はレビュー観点（SKILL.md内に存在）のみで実行する

## 依存関係DAG

```text
review-flow.md (aidlcスキル内)
    ├──→ SKILL.md (各Reviewingスキル)  [スキル呼び出し]
    │        └──→ references/reviewing-common-base.md (配布先)  [Read参照]
    │                 └──→ references/session-management.md  [リンク参照]
    │
    └──→ reviewing-common-base.md (正本)  [間接: 正本の仕様を前提としたフロー制御]

sync-reviewing-common.sh
    ├──→ reviewing-common-base.md (正本)  [読み取り]
    └──→ references/reviewing-common-base.md (配布先×9)  [書き込み]
```

**依存方向**: 一方向（SKILL.md → 共通基盤 → session-management.md）。循環なし。

## 受け入れ条件

1. **フォールバック成立**: 共通基盤欠落時も SKILL.md 単体でセルフレビューが実行可能（frontmatter + レビュー観点で完結）
2. **依存の非循環**: 上記DAGの依存方向が一方向であり循環しないこと
3. **配布整合性**: `bin/sync-reviewing-common.sh --verify` で正本と9配布先の差分ゼロを検証可能
4. **責務境界の維持**: レビュー観点の追加・変更が各SKILL.mdに局所化されていること。共通基盤の変更が外部ツール実行基盤に限定されていること

## 非機能要件（NFR）への対応

### パフォーマンス
- **要件**: 該当なし（プロンプトファイルの変更のみ）
- **対応策**: SKILL.md初回ロードサイズの削減（~53KB → ~20KB以下目標）

### セキュリティ
- **要件**: 該当なし

### スケーラビリティ
- **要件**: 共通基盤の変更が全9スキルに自動反映される構造
- **対応策**: 配布スクリプトによる一括更新

### 可用性
- **要件**: 共通基盤欠落時にスキルが停止しないこと
- **対応策**: 上記フォールバックフロー

## 技術選定

- **言語**: Bash（配布スクリプト）
- **ツール**: cp, diff, md5（配布・検証用）

## 実装上の注意事項

- 配布スクリプトはプロジェクトルートから実行する前提（`bin/` 配下）
- 正本ディレクトリ `skills/reviewing-common/` はスキルとして登録しない（SKILL.md を持たない）
- session-management.md は本Unit のスコープ外。9つの個別コピーを維持

## 不明点と質問（設計中に記録）

（現時点で不明点なし）
