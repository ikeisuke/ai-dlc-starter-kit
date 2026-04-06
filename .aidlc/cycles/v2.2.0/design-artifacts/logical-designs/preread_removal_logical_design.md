# 論理設計: 先読み指示廃止・テンプレート外部化

## 概要
先読み指示削除（25箇所）とインラインテンプレート外部化（3箇所）の変更対象・手順・参照方式を定義する。

## コンポーネント構成

### 変更対象ファイル一覧

```text
skills/aidlc/
├── steps/
│   ├── construction/
│   │   └── 01-setup.md          [削除: 10行]
│   ├── inception/
│   │   ├── 01-setup.md          [削除: 5行]
│   │   └── 05-completion.md     [テンプレート外部化: 2箇所]
│   ├── operations/
│   │   ├── 01-setup.md          [削除: 9行]
│   │   └── 02-deploy.md         [削除: 1行]
│   └── common/
│       └── review-flow.md       [テンプレート外部化: 1箇所]
└── templates/
    ├── context_reset_template.md        [新規作成]
    ├── inception_pr_body_template.md    [新規作成]
    └── review_summary_template.md       [既存更新]
```

## タスクA: 先読み指示パターン削除

### 削除対象パターン定義

「【次のアクション】」で始まり、特定ステップファイルの事前読込を要求する先読み指示。以下の2パターンを含む:

```text
**【次のアクション】** 今すぐ `steps/...` を読み込んで、内容を確認してください。
**【次のアクション】** 今すぐ `steps/...` を読み込んで、手順に従ってください。
```

**維持基準**: 「【次のアクション】」で始まっても、タスクリスト作成やSquashフロー実行など実際の作業指示は削除しない。

### ファイル別削除一覧

#### construction/01-setup.md（10行削除）
- L3: intro.md読み込み
- L4: rules.md読み込み
- L5: project-info.md読み込み
- L29: task-management.md読み込み
- L30: review-flow.md読み込み
- L34: context-reset.md読み込み
- L35: compaction.md読み込み
- L43: phase-responsibilities.md読み込み
- L44: progress-management.md読み込み
- L66: preflight.md読み込み

#### inception/01-setup.md（5行削除）
- L14: review-flow.md読み込み
- L24: compaction.md読み込み
- L32: phase-responsibilities.md読み込み
- L33: progress-management.md読み込み
- L59: preflight.md読み込み

#### operations/01-setup.md（9行削除）
- L3: intro.md読み込み
- L4: rules.md読み込み
- L5: project-info.md読み込み
- L19: review-flow.md読み込み
- L23: context-reset.md読み込み
- L24: compaction.md読み込み
- L34: phase-responsibilities.md読み込み
- L35: progress-management.md読み込み
- L61: preflight.md読み込み

#### operations/02-deploy.md（1行削除）
- L184: operations-release.md読み込み指示

### 維持対象（削除しない）
- construction/01-setup.md L106: タスクリスト作成指示
- construction/04-completion.md L92: Squashフロー実行指示
- inception/01-setup.md L70, L278, L294: タスクリスト作成指示
- inception/05-completion.md L211: Squashフロー実行指示
- operations/01-setup.md L86: タスクリスト作成指示

## タスクB: インラインテンプレート外部化

### B-1: PR本文テンプレート（05-completion.md → Inception専用テンプレート新規作成）

**現状**: L176-187にInception完了時のPR本文インラインテンプレートが記述されている（サイクル概要/含まれるUnit/複数IssueのCloses列挙）。
**既存テンプレートとの差異**: `pr_body_template.md`はOperations Phase用（Summary/受け入れ基準/変更概要/Test plan/Closes構成）であり、構成が異なる。
**対��**: `templates/inception_pr_body_template.md`として新規作成し、05-completion.md側は参照指示に置換。

**置換後**:
```text
1. Writeツールで一時ファイルを作成（テンプレート: `templates/inception_pr_body_template.md` を参照）:
```

### B-2: コンテキストリセットテンプレート（05-completion.md）

**現状**: L252-277にコンテキストリセットメッセージのテンプレートが記述されている。
**対応**: `templates/context_reset_template.md`として新規作成し、元の箇所を参照指示に置換。

**新規テンプレート内容**: 05-completion.mdのL252-277の内容をそのまま移動。

**置換後**:
```text
テンプレート（`templates/context_reset_template.md`）に従い、セッションサマリを含むメッセージを出力する。
```

### B-3: レビューサマリSetフォーマット（review-flow.md → フォーマット例のみ移動）

**現状**: L173-199にSetフォーマットとバックログ列有効値テーブルが記述されている。
**責務分離**: バックログ列有効値テーブル（L190-199）と検証条件（OUT_OF_SCOPE時必須ルール等）は業務ルールであり、review-flow.mdに残す。Setフォーマット例（L175-188のマークダウンコードブロック）のみテンプレートに移動する。

**review-flow.md置換後**:
```text
**Setフォーマット**: `templates/review_summary_template.md` の「Setフォーマット」セクションを参照。

**バックログ列���有効値**:
（既存テーブルをそのまま維持）

OUT_OF_SCOPE時はバックログ列必須（`-` 以外）。修正済み・TECHNICAL_BLOCKER時は `-`。
```

## 実装上の注意事項
- 行削除後に空行が連続する場合は適切に整理する
- テンプレート参照は「テンプレート: `templates/xxx.md`」の形式で統一する
- review_summary_template.mdの既存「記述例」セクションは維持する
