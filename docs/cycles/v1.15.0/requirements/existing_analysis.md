# 既存コード分析 - v1.15.0

## 1. コミット関連の現状（#187）

### 1.1 コミット作成パターン

現在4つのパターンでコミットが作成される：

| パターン | 場所 | メッセージ形式 | タイミング |
|---------|------|--------------|-----------|
| レビュー前 | `common/review-flow.md` | `chore: [{{CYCLE}}] レビュー前 - {成果物名}` | AIレビュー/人間レビュー前 |
| レビュー反映 | `common/review-flow.md` | `chore: [{{CYCLE}}] レビュー反映 - {成果物名}` | レビュー指摘修正後 |
| Unit完了 | `construction.md` | `feat: [{{CYCLE}}] Unit {NNN}完了 - {内容}` | Unit全実装完了後 |
| Phase完了 | 各フェーズプロンプト | `feat/chore: [{{CYCLE}}] {Phase}完了` | フェーズ完了時 |

### 1.2 コミット処理の分散状況

コミット関連のロジックが複数箇所に分散している：

- **`common/rules.md`**: Gitコミットのタイミング定義、Co-Authored-Byルール
- **`common/review-flow.md`**: レビュー前/後のコミット実行（`git add -A && git commit -m`）
- **`construction.md`**: Unit完了コミット（指示形式、実行コマンドなし）
- **`operations.md`**: Phase完了コミット

### 1.3 jjサポート

- `docs/aidlc.toml` の `[rules.jj].enabled` で制御
- Unit完了時の3点セット: `jj describe -m "..." && jj new && jj bookmark set ...`
- `jj squash` コマンドは存在するが、履歴自動圧縮機能は未実装

### 1.4 既存のsquash関連

- Unit PRマージ時: `gh pr merge --squash --delete-branch`（Unit Branch使用時）
- Operations Phase PRマージ: `pr-ops.sh merge {PR番号} --squash`
- **履歴の自動圧縮（複数コミットの自動統合）機能は未実装**

### 1.5 Co-Authored-By

`common/rules.md` で標準化。自動検出フロー：
1. `docs/aidlc.toml` の `ai_author` 設定値
2. AIツール自己認識
3. 環境変数検出
4. ユーザー確認

---

## 2. プロンプト構造の現状（#116）

### 2.1 ディレクトリ構成

```
prompts/package/prompts/
├── AGENTS.md                    # 開発サイクルガイド
├── CLAUDE.md                    # Claude Code固有設定
├── setup.md                     # セットアップ
├── inception.md                 # Inception Phase（859行）
├── construction.md              # Construction Phase（960行）
├── operations.md                # Operations Phase（985行）
├── common/
│   ├── intro.md                 # 共通イントロ（22行）
│   ├── rules.md                 # 共通ルール（157行）
│   └── review-flow.md           # AIレビューフロー（437行）
└── lite/
    ├── inception.md             # Lite版 Inception（71行）
    ├── construction.md          # Lite版 Construction（117行）
    └── operations.md            # Lite版 Operations（88行）
```

合計: 約4,025行（フル版2,804行、共通616行、Lite版276行）

### 2.2 依存関係

```
各フェーズプロンプト（inception/construction/operations）
  ├── common/intro.md（読み込み指示）
  ├── common/rules.md（読み込み指示）
  └── common/review-flow.md（読み込み指示）
```

- 各フェーズプロンプトは独立しており、相互参照はない
- `common/rules.md` が最も多く参照される共通モジュール
- `common/review-flow.md` がAIレビュー実行の統一フロー

### 2.3 Skills構造

```
prompts/package/skills/
├── reviewing-code/SKILL.md
├── reviewing-architecture/SKILL.md
├── reviewing-security/SKILL.md
├── upgrading-aidlc/SKILL.md
└── versioning-with-jj/
    ├── SKILL.md
    └── references/jj-support.md
```

### 2.4 テンプレート・ガイド参照

プロンプト内で参照されるファイル：
- テンプレート: `docs/aidlc/templates/` 配下（10種類）
- ガイド: `docs/aidlc/guides/` 配下（4種類）
- その他: `docs/aidlc/bug-response-flow.md`、`docs/cycles/rules.md`

---

## 3. 変更が必要な箇所

### 3.1 コミットまとめ（#187）

**必要な変更**:
1. **squashスクリプトの新規作成**: Unit完了時に中間コミットをまとめるスクリプト
   - git用: `git reset --soft` + `git commit` 方式
   - jj用: `jj squash` 方式
2. **プロンプトへの組み込み**: `construction.md` のUnit完了時手順にsquash呼び出しを追加
3. **jj対応**: `versioning-with-jj` スキルまたはサポートファイルにsquash手順を追加

### 3.2 Skills化に向けた全体整理（#116）

**必要な変更**:
1. **コミット処理の統合**: 分散しているコミット関連ロジックを `common/` に集約
2. **review-flow.md の整理**: 437行と長大。レビューフローとコミットフローの関心事を整理
3. **フェーズ間の状態引き継ぎ**: Skills化時に各フェーズが独立動作できるよう、状態管理を明確化
4. **構造方針の策定**: Skills化に必要な分離ポイントの特定と方針ドキュメント作成
