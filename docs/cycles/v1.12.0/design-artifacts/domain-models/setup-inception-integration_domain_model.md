# ドメインモデル設計: Setup/Inception統合

## 1. 統合の目的

Setup PhaseとInception Phaseを1つのプロンプトに統合し、ユーザーが1回のプロンプト読み込みでサイクル開始からUnit定義完了まで進められるようにする。

## 2. 現状分析

### setup.md の主要セクション

| セクション | 概要 | 統合後の扱い |
|-----------|------|-------------|
| AI-DLC手法の要約 | 手法の説明 | 維持（統合版の冒頭） |
| プロジェクト情報 | ディレクトリ構成等 | マージ |
| あなたの役割 | セットアップ担当者 | 拡張（PM兼任） |
| 依存コマンド確認 | env-info.sh実行 | 維持 |
| デプロイ済みファイル確認 | docs/aidlc確認 | 維持 |
| スターターキット開発リポジトリ判定 | name確認 | 維持 |
| バックログモード確認 | mode確認 | 維持 |
| バージョン確認 | スターターキット版確認 | 維持 |
| サイクルバージョン決定 | vX.Y.Z決定 | 維持 |
| ブランチ確認 | worktree/ブランチ作成 | 維持 |
| サイクル存在確認 | ディレクトリ確認 | 維持 |
| サイクルディレクトリ作成 | init-cycle-dir.sh | 維持 |
| バックログ移行 | 旧形式移行（deprecated） | 維持 |

### inception.md の主要セクション

| セクション | 概要 | 統合後の扱い |
|-----------|------|-------------|
| プロジェクト情報 | 制約事項、開発ルール | マージ |
| あなたの役割 | PM兼BA | setup.mdと統合 |
| ブランチ確認 | サイクルブランチ確認 | setup.mdで実施済み（スキップ） |
| サイクル名決定 | vX.Y.Z確認 | setup.mdで実施済み（スキップ） |
| セットアップコンテキスト確認 | 引継ぎ確認 | 統合版では不要（同一セッション） |
| Dependabot/Issue確認 | gh cli確認 | 維持 |
| バックログ確認 | 既存バックログ確認 | 維持 |
| 進捗管理ファイル確認 | progress.md確認 | 維持 |
| Intent明確化 | 要件定義 | 維持 |
| ユーザーストーリー作成 | ストーリー作成 | 維持 |
| Unit定義 | Unit分解 | 維持 |
| PRFAQ作成 | プレスリリース作成 | 維持 |

## 3. 統合版の構成

### 3.1 セクション構成

```
1. AI-DLC手法の要約（setup.mdから）
2. プロジェクト情報（マージ）
3. あなたの役割（統合: セットアップ担当者兼PM兼BA）
4. 設定階層化機能の案内【新規】
5. 最初に必ず実行すること
   5.1 依存コマンド確認（setup.md）
   5.2 デプロイ済みファイル確認（setup.md）
   5.3 スターターキット開発リポジトリ判定（setup.md）
   5.4 バックログモード確認（setup.md）
   5.5 スターターキットバージョン確認（setup.md）
   5.6 サイクルバージョン決定（setup.md）
   5.7 ブランチ確認（setup.md）
   5.8 サイクル存在確認（setup.md）
   5.9 サイクルディレクトリ作成（setup.md）
   5.10 バックログ移行（setup.md、deprecated）
   5.11 追加ルール確認（inception.md）
   5.12 環境確認（inception.md）
   5.13 Dependabot PR確認（inception.md）
   5.14 GitHub Issue確認（inception.md）
   5.15 バックログ確認（inception.md）
   5.16 進捗管理ファイル確認（inception.md）
   5.17 既存成果物確認（inception.md）
6. フロー
   6.1 Intent明確化（inception.md）
   6.2 既存コード分析（inception.md）
   6.3 ユーザーストーリー作成（inception.md）
   6.4 Unit定義（inception.md）
   6.5 PRFAQ作成（inception.md）
7. 実行ルール
8. 完了基準
9. 完了時の必須作業（マージ）
10. 次のステップ
11. このフェーズに戻る場合
12. 補足: git worktree
```

### 3.2 削除・統合される重複セクション

| 削除対象 | 理由 |
|---------|------|
| inception.mdのブランチ確認 | setup.mdで実施済み |
| inception.mdのサイクル名決定 | setup.mdで実施済み |
| inception.mdのセットアップコンテキスト確認 | 同一セッションのため不要 |
| inception.mdのサイクル存在確認 | setup.mdで実施済み |

### 3.3 設定階層化機能の案内【新規セクション】

Unit 001で実装された個人設定機能を案内:

```markdown
## 個人設定（オプション）

チーム共有設定を個人の好みで上書きできます:

| ファイル | 用途 | Git管理 |
|----------|------|---------|
| `docs/aidlc.toml` | プロジェクト共有設定 | Yes |
| `docs/aidlc.toml.local` | 個人設定（上書き用） | No（.gitignore） |

例: AIレビューを個人的に無効化
```toml
# docs/aidlc.toml.local
[rules.mcp_review]
mode = "disabled"
```

詳細は `docs/aidlc/guides/config-merge.md` を参照。
```

## 4. エンティティ定義

### SetupInceptionFlow

統合版フローを表すエンティティ。

| 属性 | 型 | 説明 |
|-----|-----|------|
| cycle | string | サイクルバージョン（vX.Y.Z） |
| phase | enum | "setup" / "inception" |
| currentStep | number | 現在のステップ番号 |
| completedSteps | array | 完了済みステップのリスト |

### ConfigHierarchy

設定階層を表す値オブジェクト。

| 属性 | 型 | 説明 |
|-----|-----|------|
| projectConfig | path | docs/aidlc.toml |
| localConfig | path | docs/aidlc.toml.local |
| userConfig | path | ~/.aidlc/config.toml |

## 5. 境界と制約

- **スコープ**: 通常版のみ（Lite版はUnit 004で対応）
- **後方互換性**: 旧版（setup.md/inception.md）はリダイレクトとして維持
- **設定階層化**: Unit 001完了後は.local設定を案内、Unit 002完了後は~/.aidlc/も案内
