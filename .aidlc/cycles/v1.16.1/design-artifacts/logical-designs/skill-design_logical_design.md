# 論理設計: 共通処理スキル化の全体設計

## 概要

ドメインモデルで定義した10スキル候補について、具体的なファイル構成、移行対象セクション、互換性維持方針、エラーハンドリング設計、削減効果見積もりを定義する。

## 1. 既存スキル構造の分析

### 既存スキルの分類

| パターン | スキル例 | 特徴 |
|---------|---------|------|
| 外部ツール呼び出し型 | reviewing-*, versioning-with-jj | `allowed-tools` あり、外部CLI実行 |
| 内部ワークフロー型 | upgrading-aidlc | `allowed-tools` なし、手順指示のみ |

### SKILL.md フロントマター共通構造

```yaml
---
name: {skill-name}           # kebab-case、必須
description: {説明}           # 英語、トリガー条件含む、必須
argument-hint: {引数ヒント}   # 必須
compatibility: {互換情報}     # 任意
allowed-tools: {許可ツール}   # 任意
---
```

### 新規スキルの分類

| 分類 | 対象スキル | フロントマター特徴 |
|------|-----------|------------------|
| 内部ワークフロー型 | issue-management, backlog-management, pr-operations, version-management, setup-initialization, progress-tracking, completion-validation | `allowed-tools` なし（内部でシェルスクリプトを呼び出すがAIツール自体のBash実行を利用） |
| メタパターン型 | dialogue-planning | `allowed-tools` なし、パターンガイド提供 |
| ユーティリティ型 | code-quality-check, unit-squash | `allowed-tools` なし、既存スクリプトのラッパー |

## 2. 各スキルのファイル構成設計

### 共通構成

```
prompts/package/skills/{skill-name}/
├── SKILL.md              # スキル定義（フロントマター + 本文）
└── references/           # 参照ドキュメント（任意）
    └── {topic}.md        # 詳細な手順や対照表
```

### 各スキルのファイル構成

#### High優先度

**issue-management/**
```
SKILL.md                  # Issue操作のディスパッチャー
references/
└── operations.md         # 操作別の詳細手順（set-status, list, create-label, label-batch, extract-related）
```

**backlog-management/**
```
SKILL.md                  # バックログ操作のディスパッチャー
references/
├── operations.md         # 操作別の詳細手順
└── mode-decision.md      # モード別（git/issue/git-only/issue-only）の処理分岐
```

**pr-operations/**
```
SKILL.md                  # PR操作のディスパッチャー
references/
├── operations.md         # 操作別の詳細手順（create, ready, merge, validate-state, generate-body）
└── body-templates.md     # PRボディテンプレート集（Draft PR, Unit PR, Cycle PR）
```

#### Medium優先度

**version-management/**
```
SKILL.md                  # バージョン操作のディスパッチャー
references/
├── operations.md         # 操作別の詳細手順
└── project-types.md      # プロジェクト種類別のバージョンファイル・更新方法
```

**setup-initialization/**
```
SKILL.md                  # 初期化手順のオーケストレーター
references/
└── steps.md              # 初期化ステップの詳細（env-info, ディレクトリ作成, ブランチ確認等）
```

**progress-tracking/**
```
SKILL.md                  # 進捗読み取り・状態管理
references/
└── backward-compat.md    # 後方互換処理（progress.md → Unit定義ファイル移行）
```

#### Low優先度

**dialogue-planning/**
```
SKILL.md                  # 対話パターンガイド
references/
└── patterns.md           # コンテキスト種別ごとのテンプレート
```

**completion-validation/**
```
SKILL.md                  # 完了条件チェック手順
```

**code-quality-check/**
```
SKILL.md                  # 品質チェック実行（markdownlint等）
```

**unit-squash/**
```
SKILL.md                  # squash実行手順
```

## 3. 移行対象セクション一覧

### フェーズ × セクション マッピング表

#### Inception Phase（835行）

| セクション | 行範囲（概算） | 移行先スキル | 移行行数 |
|-----------|-------------|------------|---------|
| Part 1: セットアップ（Steps 1-9） | L133-358 | setup-initialization | ~225 |
| Step 10-11: 追加ルール・環境確認 | L361-379 | （共通化済み: check-gh-status.sh等） | 0 |
| Step 12: GitHub Issue確認 | L382-419 | issue-management | ~37 |
| Step 13: バックログ確認 | L421-479 | backlog-management | ~58 |
| Step 14: 進捗管理ファイル確認 | L480-502 | progress-tracking | ~22 |
| Step 1: Intent明確化 | L510-548 | dialogue-planning | ~38 |
| Step 3: ユーザーストーリー作成 | L559-608 | dialogue-planning | ~49 |
| Step 4: ドラフトPR作成 | L715-780 | pr-operations | ~65 |
| サイクルラベル作成 | L677-706 | issue-management | ~29 |
| バージョン確認（Steps 5-6） | L224-280 | version-management | ~56 |
| **Inception合計** | | | **~579** |

#### Construction Phase（889行）

| セクション | 行範囲（概算） | 移行先スキル | 移行行数 |
|-----------|-------------|------------|---------|
| 気づき記録フロー（バックログ部分） | L55-87 | backlog-management | ~32 |
| Step 3: 進捗状況確認 | L206-237 | progress-tracking | ~31 |
| Step 3.5: バックログ確認 | L238-247 | backlog-management | ~9 |
| Step 4.5: Issueステータス更新 | L265-283 | issue-management | ~18 |
| Step 0: 完了条件の確認 | L493-534 | completion-validation | ~41 |
| Step 0.5: 設計・実装整合性チェック | L535-585 | completion-validation | ~50 |
| Step 3（完了時）: Markdownlint実行 | L685-695 | code-quality-check | ~10 |
| Step 3.5: Squash | L696-708 | unit-squash | ~12 |
| Step 1.5: Issueステータス更新（完了時） | L671-680 | issue-management | ~9 |
| Phase 1 設計ステップ | L410-441 | dialogue-planning | ~31 |
| **Construction合計** | | | **~243** |

#### Operations Phase（996行）

| セクション | 行範囲（概算） | 移行先スキル | 移行行数 |
|-----------|-------------|------------|---------|
| Step 3: 進捗管理ファイル確認 | L148-170 | progress-tracking | ~22 |
| Step 5.1: バックログ整理 | L385-423 | backlog-management | ~38 |
| Step 6.0: バージョン確認 | L451-540 | version-management | ~89 |
| Step 6.4: Markdownlint実行 | L587-597 | code-quality-check | ~10 |
| Step 6.6: Closes記載確認 | L621-634 | issue-management | ~13 |
| Step 6.6: ドラフトPR Ready化 | L614-680 | pr-operations | ~66 |
| Step 6.6.5-6.6.6: 検証 | L681-775 | pr-operations | ~94 |
| Step 6.7: PRマージ | L776-807 | pr-operations | ~31 |
| デプロイ準備等（Steps 1-5） | L290-384 | dialogue-planning | ~94 |
| **Operations合計** | | | **~457** |

### 移行前後の記述イメージ

**移行前**（operations.md内に直接記述、約30行）:
```markdown
### 6.6 Closes記載確認
PRボディに関連IssueのCloses記法が含まれているか確認する。
Unit定義ファイルの「関連Issue」セクションから番号を取得し...
（以下、具体的な手順が続く）
```

**移行後**（operations.md内のスキル呼び出し、約3行）:
```markdown
### 6.6 Closes記載確認
`/issue-management extract-related` でUnit定義ファイルから関連Issue番号を取得し、
PRボディに `Closes #XX` が含まれているか確認する。
```

## 4. 互換性維持方針

### AIツール間の互換性

| 要素 | Claude Code | KiroCLI | その他 |
|------|------------|---------|--------|
| SKILL.md読み込み | Skillツール経由 | Skill一覧API | ファイル直接読み込み |
| フロントマター | name, description, argument-hint | 同左 | 同左 |
| allowed-tools | 不要（新規スキルは内部ワークフロー型） | 不要 | 不要 |
| 引数渡し | Skillツールのargs | 同左 | 手動 |

**方針**: 新規スキルは全て「内部ワークフロー型」（SKILL.mdの指示に従ってAIが処理を実行）である。ただし、一部スキル（issue-management, backlog-management, pr-operations, version-management）は内部で `gh` CLI や既存シェルスクリプト（issue-ops.sh, pr-ops.sh等）に依存する。これらの外部依存はスキルのエラーモードとして定義済みであり、依存先不可時はフォールバック（CONTINUE/ASK_USER）で対応する。`allowed-tools` フロントマターは不要（AIツール自体のBash実行を利用するため）。

### 段階的移行計画

| フェーズ | 対象 | 内容 | 影響範囲 |
|---------|------|------|---------|
| Phase A | High優先度スキル | issue-management, backlog-management, pr-operations の3スキルを作成 | 全フェーズプロンプト |
| Phase B | Medium優先度スキル | version-management, setup-initialization, progress-tracking の3スキルを作成 | inception.md, operations.md 中心 |
| Phase C | Low優先度スキル | 残り4スキルを作成（dialogue-planningは要再評価） | 各フェーズプロンプト |

**各フェーズの完了条件**:
- スキルが作成され、SKILL.mdが完成していること
- 対応するフェーズプロンプトのセクションがスキル呼び出しに置き換えられていること
- 回帰確認（既存ワークフローが正常に動作すること）が完了していること

### 破壊的変更の判定基準

以下のいずれかに該当する変更を「破壊的変更」と定義する：

| 変更種別 | 例 | 判定 |
|---------|-----|------|
| 必須入力パラメータの追加（Enum値追加） | operationに新しいEnum値を追加 | 非破壊的（受信側互換ルール: 未知Enum値は無視/警告とする） |
| 必須入力パラメータの削除・名前変更 | cycle → cycle_name | **破壊的** |
| 出力形式の変更 | `issue:{number}:status-updated` → JSON形式 | **破壊的** |
| エラーモードのphaseAction変更 | CONTINUE → STOP | **破壊的** |
| 任意パラメータの追加 | 新しいオプションパラメータ | 非破壊的 |

### 受信側互換ルール

フェーズプロンプト（スキルの呼び出し元）は以下のルールに従うこと：

- **未知のEnum値**: 無視または警告を表示して処理を継続する
- **未知の出力フィールド**: 無視する（将来追加されるフィールドに依存しない）
- **status=skipped**: SKIPPED_BY_CONFIG に対応するステータス。スキップとして扱い、後続処理を継続する

### deprecated運用方針

1. **廃止予定スキルのマーキング**: SKILL.mdのフロントマターに `deprecated: true` を追加
2. **廃止予告期間**: 最低1サイクル（廃止予告 → 次サイクルで削除）
3. **移行ガイド**: SKILL.md内に「移行先」セクションを追加し、代替スキルを案内
4. **フェーズプロンプト側**: 廃止予定スキルの呼び出し箇所にコメントで「次サイクルで移行」と記載

## 5. エラーハンドリング設計

### 失敗分類と対応方針

| カテゴリ | 説明 | デフォルト対応 | 例 |
|---------|------|-------------|-----|
| INPUT_INVALID | 入力パラメータが不正 | ASK_USER | Issue番号が数値でない、未知のoperation |
| DEPENDENCY_UNAVAILABLE | 依存先（gh CLI、ファイル等）が利用不可 | CONTINUE（スキップ or フォールバック） | gh未インストール、テンプレートファイル不在 |
| EXECUTION_FAILURE | 実行中のエラー | ASK_USER | API通信失敗、rebase失敗 |

### フェーズ側の継続/停止判定

| phaseAction | フェーズプロンプト側の処理 |
|------------|------------------------|
| CONTINUE | 警告を表示してフローを継続。スキップされた処理の影響を記録 |
| STOP | フローを停止し、問題の解決を待つ。次のステップに進まない |
| ASK_USER | ユーザーに対応を選択させる（修正して再実行 / スキップ / 中断） |

### リトライポリシー

- **リトライ可能**: ネットワーク系エラー（API通信失敗等）は1回のみ自動リトライ
- **リトライ不可**: 入力不正、依存先不在、ロジックエラーは即座にphaseAction実行
- **リトライ失敗時**: phaseAction に従う

### スキル横断的なフォールバックチェーン

```
issue-management（gh不可時）→ CONTINUE（Issue操作をスキップ、手動対応を案内）
backlog-management（issue-only + gh不可時）→ ASK_USER（issue-onlyモードではgit保存不可。手動対応を案内）
backlog-management（git/issue + gh不可時）→ CONTINUE（git fallbackで一時保存、警告表示）
pr-operations（gh不可時）→ CONTINUE（手動PR作成を案内）
version-management（GitHub API失敗時）→ CONTINUE（現行バージョンで継続）
```

## 6. 削減効果見積もり

### フェーズ別削減行数

| フェーズ | 現在行数 | 削減行数 | 残存行数 | 削減率 |
|---------|---------|---------|---------|-------|
| inception.md | 835 | ~579 | ~256 | 69% |
| construction.md | 889 | ~243 | ~646 | 27% |
| operations.md | 996 | ~457 | ~539 | 46% |
| **合計** | **2,720** | **~1,279** | **~1,441** | **47%** |

### スキル別の行数変化

| スキル | 削減行数（3フェーズ合計） | 新規SKILL.md行数（推定） | references行数（推定） | 純削減 |
|--------|----------------------|----------------------|---------------------|--------|
| issue-management | ~106 | ~40 | ~60 | +6（純増だが散在解消） |
| backlog-management | ~137 | ~50 | ~80 | +7（純増だが散在解消） |
| pr-operations | ~256 | ~60 | ~120 | +76 |
| version-management | ~143 | ~40 | ~80 | +23 |
| setup-initialization | ~225 | ~50 | ~100 | +75 |
| progress-tracking | ~75 | ~30 | ~40 | +5（純増だが散在解消） |
| dialogue-planning | ~248 | ~40 | ~60 | +148 |
| completion-validation | ~91 | ~30 | - | +61 |
| code-quality-check | ~20 | ~20 | - | 0 |
| unit-squash | ~12 | ~20 | - | -8（純増） |

### 可読性影響の評価

| 影響種別 | 評価 | 説明 |
|---------|------|------|
| フェーズプロンプトの可読性 | **向上** | 手順の詳細がスキルに移動し、フェーズの全体フローが見通しやすくなる |
| 新規参入者の理解しやすさ | **やや低下** | スキル呼び出しの先を追う必要がある（間接参照の増加） |
| 保守時の変更容易性 | **向上** | 共通処理の修正が1箇所で完結する |
| デバッグ時の追跡しやすさ | **やや低下** | 処理が分散するため、問題箇所の特定に手間が増える可能性 |

**総合評価**: フェーズプロンプトの主目的（フェーズ全体のフロー制御）に対する可読性は向上する。一方、新規参入者やデバッグ時のオーバーヘッドが発生するため、以下の緩和策を講じる：

**緩和策**:
1. **スキル呼び出し箇所にコメント**: 何が行われるかの1行サマリを併記
2. **スキル一覧ドキュメント**: 全スキルの概要・引数・出力を一覧化したガイドを作成（既存の `docs/aidlc/guides/skill-usage-guide.md` を拡充）
3. **Low優先度スキルの再評価**: dialogue-planning（抽象化リスク高）と unit-squash（純増）は実装フェーズで再評価し、見送りも選択肢とする

### 純行数変化のまとめ

| 項目 | 行数 |
|------|------|
| フェーズプロンプトからの削減 | -1,279 |
| 新規スキルファイルの追加 | +880（SKILL.md ~380 + references ~500） |
| **純削減** | **~399** |

**注意**: 純行数の削減幅は限定的だが、以下のメリットが行数以上の価値を持つ：
- **散在の解消**: 同一ロジックが3-5箇所に散在する問題の解消
- **単一変更点**: 共通処理の修正が1箇所で完結
- **フェーズプロンプトの簡素化**: フローの見通しが改善し、プロンプト品質向上に寄与

## 不明点と質問（設計中に記録）

[Question] dialogue-planningはスキル化のメリットが薄い可能性がある。実装フェーズで再評価する方針でよいか
[Answer] ドメインモデル設計の優先度評価でLow判定済み。実装フェーズで再評価し、見送りも選択肢とする方針で合意。

[Question] unit-squashは純増（-8行）となるが、スキル化する意味はあるか
[Answer] 行数削減の観点では意味がないが、squashフロー（条件分岐・エラーリカバリ）の標準化の観点で検討。ただしLow優先度のため実装フェーズで再評価。
