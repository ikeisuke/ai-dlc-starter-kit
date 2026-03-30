# 論理設計: PR本文へのレビュー情報記載

## 概要

各PRテンプレートの具体的なセクション構成とプレースホルダ、レビューサマリの存在チェックロジックを定義する。

**重要**: この論理設計では**コードは書かず**、コンポーネント構成とインターフェース定義のみを行います。

## コンポーネント構成

### 変更対象箇所

```text
prompts/package/prompts/
├── construction.md
│   ├── Unitブランチ作成 > ドラフトPR body  ← 変更
│   ├── Unit完了時 > ステップ5-2 PR Ready化 body  ← 変更
│   └── Unit完了時 > ステップ5-3 新規PR作成 body  ← 変更
└── operations.md
    ├── ステップ6.6 PR Ready化 body  ← 変更
    └── ステップ6.6 新規PR作成 body  ← 変更
```

## テンプレート設計

### A. construction.md: ドラフトPR body

**現行**:

```text
## Unit概要
[Unit定義から抽出した概要]

## 関連Issue
[Unit定義ファイルの関連Issueから抽出]
- #[Issue番号]（参照のみ、サイクルPRでCloses）

---
:construction: このPRは作業中です。Unit完了時にレビュー依頼を行います。
```

**変更後**:

```text
## Unit概要
[Unit定義から抽出した概要]

## 要件
[Unit定義の「責務」セクションから箇条書きで抽出]

## 受け入れ基準
[計画ファイルの「完了条件チェックリスト」から抽出]

## 関連Issue
[Unit定義ファイルの関連Issueから抽出]
- #[Issue番号]（参照のみ、サイクルPRでCloses）

---
:construction: このPRは作業中です。Unit完了時にレビュー依頼を行います。
```

### B. construction.md: Ready化/新規PR body

**現行（Ready化・新規共通）**:

```text
## Unit概要
[Unit定義から抽出した概要]

## 変更内容
[主な変更点]

## テスト結果
[テスト結果サマリ]
```

**変更後**:

```text
## Unit概要
[Unit定義から抽出した概要]

## 要件
[Unit定義の「責務」セクションから箇条書きで抽出]

## 受け入れ基準
[計画ファイルの「完了条件チェックリスト」から抽出]

## 変更内容
[主な変更点]

## テスト結果
[テスト結果サマリ]

## レビューサマリ
[レビューサマリファイルの内容を記載]
```

**レビューサマリ存在チェック手順**（テンプレート内に記載する指示）:

```text
**レビューサマリの記載手順**:
1. `docs/cycles/{{CYCLE}}/construction/units/{NNN}-review-summary.md` の存在を確認
2. 存在する場合: ファイル内容を読み込み、「## レビューサマリ」セクションに記載
3. 存在しない場合: 「## レビューサマリ」セクションを省略
```

### C. operations.md: Ready化/新規PR body

**現行（Ready化 body は存在しない → 新規PR作成テンプレートのみ存在）**:

```text
## Summary
[変更点]

## Test plan
- [ ] 主要機能が動作する

## Closes
Closes #[Issue番号]
```

**変更後**:

```text
## Summary
[Intentから抽出した概要]

## 受け入れ基準
[各Unit計画ファイルの「完了条件チェックリスト」から集約して記載]

## 変更概要
[全Unitの主な変更点を箇条書き]

## レビューサマリ

### Construction Phase
[各ファイルへのリンクを列挙]
- `docs/cycles/{{CYCLE}}/construction/units/{NNN}-review-summary.md`

### Inception Phase
[各ファイルへのリンクを列挙（許容される{step-name}: intent, user-stories, unit-definition）]
- `docs/cycles/{{CYCLE}}/inception/{step-name}-review-summary.md`

## Test plan
- [ ] 主要機能が動作する

## Closes
Closes #[Issue番号]
```

**レビューサマリ存在チェック手順**（テンプレート内に記載する指示）:

```text
**レビューサマリの記載手順**:
1. 以下のディレクトリでサマリファイルを検索:
   - `docs/cycles/{{CYCLE}}/construction/units/*-review-summary.md`
   - `docs/cycles/{{CYCLE}}/inception/*-review-summary.md`（許容されるstep-name: `intent`, `user-stories`, `unit-definition`）
2. いずれかのファイルが存在する場合: ファイルへのリンクを「## レビューサマリ」セクションに列挙
3. いずれも存在しない場合: 「## レビューサマリ」セクションを省略
```

## 処理フロー概要

### Unit PR作成時のフロー

1. Unit定義ファイルから「責務」セクションを読み込む
2. 計画ファイルから「完了条件チェックリスト」を読み込む
3. レビューサマリファイルの存在を確認
4. PRテンプレートのセクションを埋める（サマリ非存在時は省略）

### サイクルPR作成時のフロー

1. Intent（`docs/cycles/{{CYCLE}}/requirements/intent.md`）から概要を読み込む
2. 各Unit計画ファイル（`docs/cycles/{{CYCLE}}/plans/unit-{NNN}-plan.md`）から完了条件チェックリストを集約
3. レビューサマリファイル群の存在を確認
4. PRテンプレートのセクションを埋める（サマリ非存在時は省略）

## 実装上の注意事項

- Ready化のPR bodyと新規PRのbodyは同じ構成にする（DRY原則）
- operations.md のReady化は既存ドラフトPRの `gh pr edit --body` で更新する（現行の新規PR作成テンプレートも同じ構成に統一）
- レビューサマリの存在チェックは `ls` コマンドの結果で判断する指示をテンプレートに含める
