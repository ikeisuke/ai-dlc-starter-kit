# AI-DLC Starter Kit

[![Version](https://img.shields.io/badge/version-3.0.0--rc.1-blue.svg)](./.claude-plugin/marketplace.json)

AI-DLC (AI-Driven Development Lifecycle) を使った開発をすぐに始められるスターターキット

## 概要

このリポジトリには、AWS が提唱する AI-DLC 方法論の日本語リソースと、Claude Code 向けのスキルプラグイン実装が含まれています。

- **AI-DLC とは**: AI を「支援ツール」ではなく、開発プロセスの「中心的な協働者」として位置づける新しいソフトウェア開発方法論
- **v3 のサイクル**: `define`（定義）→ `develop`（実装）→ `release`（リリース）の 3 フェーズ + 任意の `reflect`（振り返り）

## v3 について（RC）

**v3.0.0-rc.1** より、`/aidlc` は **v3** を起動します（本流化済み）。v3 は、フェーズ進行を会話履歴の推論ではなく、リポジトリ内の `.aidlc/state.json` + work item frontmatter から**明示的に導出**する新設計です。セッションを跨いでも `/aidlc` の実行だけで現在地から再開できます。

- **v2 を使い続けたい場合**: v2 実装一式は [v2-maintenance ブランチ](https://github.com/ikeisuke/ai-dlc-starter-kit/tree/v2-maintenance)に保全されています
- **v2 から v3 へ移行する場合**: `/aidlc-migrate` が v2→v3 マイグレーション（new-cycle-only / 旧成果物は残置）を実行します

フィードバックは Issue でお寄せください。

## インストール

### 前提条件

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) がインストール済みであること
- Git がインストール済みであること
- [jq](https://jqlang.github.io/jq/) がインストール済みであること（`state.json` 操作に使用）
- （推奨）[dasel](https://github.com/TomWright/dasel) がインストール済みであること（設定ファイル操作に使用）

### インストール手順

1. Claude Code でマーケットプレイスを追加:

```text
/plugin marketplace add ikeisuke/ai-dlc-starter-kit
```

2. プラグインをインストール:

```text
/plugin install aidlc@ikeisuke-ai-dlc-starter-kit
```

以下のスキルがまとめてインストールされます:

| スキル | 用途 |
|--------|------|
| `aidlc` | AI-DLC v3 オーケストレーター（メインスキル / `/aidlc`） |
| `aidlc-migrate` | v2→v3 マイグレーション |
| `aidlc-feedback` | AI-DLC へのフィードバック送信 |
| `reviewing-construction-plan` | 計画承認前レビュー |
| `reviewing-construction-design` | 設計レビュー |
| `reviewing-construction-code` | コード+セキュリティレビュー |
| `reviewing-construction-integration` | 統合レビュー |
| `reviewing-operations-deploy` | デプロイ計画レビュー |
| `reviewing-operations-premerge` | PRマージ前レビュー |

3. 対象プロジェクトのルートに `.aidlc/config.toml` を作成:

```toml
[rules.depth_level]
level = "standard"  # minimal / standard / comprehensive

[rules.automation]
mode = "manual"     # manual / semi_auto
```

すべてのキーにはデフォルト値があるため、空ファイルでも動作します。設定キーの全リファレンス（v3 終端 8 キー）は [docs/configuration.md](docs/configuration.md) を参照してください。

4. `/aidlc define` を実行してサイクルを開始:

```text
/aidlc define
```

対話形式で目的・スコープ・受け入れ基準（Intent）と work item を確定し、`.aidlc/` 配下にサイクル成果物と `state.json` を初期化します。

### v2 からの移行（v2 → v3）

v2（`.aidlc/config.toml` があり `state.json` が無い環境）からの移行は、マイグレーションスキルで自動化されています:

```text
/aidlc-migrate
```

- **new-cycle-only（推奨）**: 旧成果物は変換せず残置し、v3 は新規サイクルから開始します
- **archive-only**: 残置に加えて、旧成果物の所在を示す index を生成します
- 実データ変換（best-effort）は未サポートです（選択時は書き込みなしで安全に中断します）
- v1 環境を検出した場合は書き込みを行わず、v2-maintenance ブランチでの v1→v2 移行を案内します

#### v2 から撤去されたスキルと v3 での代替

v3 本流化に伴い、以下の v2 スキルは配布から撤去されました（実装は v2-maintenance ブランチに保全されています）:

| 撤去された v2 スキル | v3 での代替 |
|---------------------|------------|
| `/aidlc-setup` | 廃止。`.aidlc/config.toml` を手動作成（空ファイル可 / 上記手順 3） |
| `/aidlc-v3` | `/aidlc` に統合（本流化） |
| `/squash-unit` | 個別スキル廃止。develop フローが work item 完了時にコミットを集約 |
| `/write-history` | 個別スキル廃止。`journal.md` への追記は各フェーズフローが直接実施 |
| `aidlc-retrospective` | `/aidlc reflect` |
| `reviewing-inception-intent` / `-stories` / `-units` | 個別スキル廃止。Intent / work item の確認は define の承認ゲートで実施 |

上記の代替で不足する v2 機能は v2-maintenance ブランチで継続利用できます。

### v1 / v2 ブランチについて

| 系統 | 参照先 | 状態 |
|------|--------|------|
| v1 | [v1 ブランチ](https://github.com/ikeisuke/ai-dlc-starter-kit/tree/v1) | メンテナンスモード（新機能追加なし） |
| v2 | [v2-maintenance ブランチ](https://github.com/ikeisuke/ai-dlc-starter-kit/tree/v2-maintenance) | 保全ブランチ（v2 実装一式を取得可能） |

## リポジトリ構成

```text
ai-dlc-starter-kit/
├── skills/                        # Claude Code スキルプラグイン
│   ├── aidlc/                     # v3 オーケストレーター（メインスキル）
│   │   ├── SKILL.md               # スキル定義・コマンドルーティング
│   │   ├── steps/                 # フェーズ実行手順（define / develop / release / reflect / status / doctor）
│   │   ├── scripts/               # state.json / work item 操作スクリプト
│   │   ├── templates/             # 成果物テンプレート（intent / work-item / design 等）
│   │   ├── guides/                # 補助ガイド
│   │   └── config/                # デフォルト設定
│   ├── aidlc-migrate/             # v2→v3 マイグレーション
│   ├── aidlc-feedback/            # フィードバック送信
│   ├── reviewing-common/          # レビュー共通基盤
│   ├── reviewing-construction-*/  # 実装時レビュー（plan / design / code / integration）
│   └── reviewing-operations-*/    # リリース時レビュー（deploy / premerge）
│
├── .aidlc/                        # プロジェクト設定・サイクル成果物
│   ├── config.toml                # プロジェクト設定
│   ├── state.json                 # サイクル状態（フェーズ導出の正本データ）
│   └── cycles/<cycle>/            # サイクル成果物（intent / work-items / designs / reviews / journal 等）
│
├── docs/
│   ├── v3/                        # v3 設計正本（workflow / data-model / migration / rfc）
│   └── translations/              # AI-DLC ホワイトペーパーの日本語翻訳
│
└── bin/                           # リポジトリ開発用スクリプト（CI チェック / GitHub Projects 連携）
```

## クイックスタート

### 1. AI-DLC について学ぶ

まず、AI-DLC の概要を理解しましょう：

- [要約版](docs/translations/AI-Driven_Development_Lifecycle_Summary.md)（10分）
- [詳細版](docs/translations/README.md)（30分〜1時間）

### 2. プロジェクトをセットアップ

対象プロジェクトのルートに `.aidlc/config.toml` を作成します（[インストール手順](#インストール手順) 3 参照）。ディレクトリ構造と `state.json` は `/aidlc define` が自動生成します。

### 3. 開発サイクルを回す

v3 のコマンド体系:

| コマンド | 責務 | 状態変更 |
|---------|------|---------|
| `/aidlc define` | 目的・スコープ・完了条件・作業単位（work item）を決める（Intent 承認ゲート） | あり |
| `/aidlc develop` | 次の work item を 1 件実装・検証・完了する（1 実行 = 1 work item） | あり |
| `/aidlc release` | main に安全に取り込む（PR 整備・merge） | あり |
| `/aidlc reflect` | 振り返り・改善 Issue 起票（任意実行） | なし |
| `/aidlc status` | 現在地と次アクションを表示（読み取り専用） | なし |
| `/aidlc doctor` | config / state / work item / git / gh 等の問題を診断（自動修正しない） | なし |

引数なしの `/aidlc` は、`state.json` + work item frontmatter からフェーズを導出して適切なコマンドへ自動ルーティングします。迷ったら `/aidlc` だけで進められます。

```text
/aidlc（引数なし）
  ├─ state.json 不在        → define
  └─ state.json 存在        → フェーズ導出
        ├─ define 未完了     → define
        ├─ work item 残あり  → develop
        ├─ 全 work item 完了 → release
        └─ merged + 承認済   → reflect（任意）
```

#### develop の自動判定（size × depth_level）

`develop` は work item の `size`（`tiny` / `normal` / `risky`）と設定の `depth_level`（`minimal` / `standard` / `comprehensive`）の組合せから、design 作成・レビュー実行の要否を自動判定します。小さな変更は軽く、リスクの高い変更は厚く扱います（正本: [docs/v3/data-model.md](docs/v3/data-model.md) §8）。

#### express（連続実行）

define で生成された work item が 1 つ（`tiny` または `normal`）の場合のみ、`define → develop → release` を連続実行できます。`risky` を含む場合や複数 work item の場合は個別実行を案内します。

#### 旧名エイリアス

v2 のフェーズ名は後方互換エイリアスとして利用できます:

| 旧名 | v3 コマンド |
|------|-----------|
| `inception` | `define` |
| `construction` | `develop` |
| `operations` | `release` |
| `retrospective` | `reflect` |

### 4. 次サイクルの開発

release（+ 任意の reflect）完了後、新しいサイクル識別子で `/aidlc define` を実行してライフサイクルを継続します。前サイクルの `journal.md` / `reflect.md` は次の define の入力として自動参照されます。

## 主要な機能

### 明示的な状態管理

フェーズを会話履歴からの推論ではなく `.aidlc/state.json` + work item frontmatter から導出します。コンテキストリセットやセッション切替の後も、`/aidlc` の実行だけで現在地から正確に再開できます。

### size × depth_level マトリクス

work item の大きさとプロジェクトの厳格度設定の組合せで、design / review の要否を自動判定します。`risky` な work item には design・セキュリティレビュー・Rollback Note を必須化し、`tiny` な work item は最小手続きで完了します。

### 人間の承認プロセス

Intent 承認・Design 承認などのゲートで人間の承認を要求します。`[rules.automation] mode = "semi_auto"` でフォールバック条件非該当時の自動承認に切り替えられます。

### work item 単位の自動 Git コミット

1 実行 = 1 work item で、実装・状態遷移・journal 追記を 1 コミットに集約します。履歴が work item 単位で追跡できます。

### AI レビュー統合

外部 AI ツール（Codex、Claude CLI、Gemini CLI）によるコード・セキュリティ・設計レビューを統合。レビュー種別ごとの専門スキル（`reviewing-*`）で品質を確保し、develop のレビュー結果はサイクル成果物（`reviews/`）に、release のレビュー結果は `release.md` に記録されます。

### 診断コマンド

`/aidlc doctor` が config / state / cycle / work item / git / gh / スクリプトの問題を読み取り専用で診断します。`/aidlc status` でいつでも現在地と次アクションを確認できます。

### カスタマイズ

`.aidlc/config.toml` で depth_level・automation mode・レビューモード等を制御します。設定は 4 階層（スキル同梱デフォルト → ユーザー共通 → プロジェクト → ローカル）でマージされます。詳細は [docs/configuration.md](docs/configuration.md) を参照してください。

### GitHub Projects 連携

本リポジトリ自身のバックログ管理を GitHub Projects (ProjectsV2) で動的管理化。`bin/setup-github-project.sh` で宣言的仕様（`config/github-project-spec.yaml`）に基づき Project / フィールド / ビュー / Item を冪等作成し、`bin/audit-github-project.sh` で spec 整合を監査します。詳細は [docs/development/github-projects-setup.md](docs/development/github-projects-setup.md) を参照してください。

### サンドボックス環境

AI エージェントを隔離環境で安全に実行するには [jailrun](https://github.com/ikeisuke/jailrun) を参照してください。

## ドキュメント

### v3 設計ドキュメント

| ドキュメント | 内容 |
|------------|------|
| [docs/v3/workflow.md](docs/v3/workflow.md) | v3 ワークフロー全体像（コマンド体系・承認ゲート） |
| [docs/v3/data-model.md](docs/v3/data-model.md) | データモデル（state.json / work item / フェーズ導出規則） |
| [docs/v3/migration.md](docs/v3/migration.md) | v2→v3 マイグレーション仕様 |
| [docs/configuration.md](docs/configuration.md) | 設定ファイルリファレンス |

### AI-DLC 翻訳文書

| ドキュメント | 内容 |
|------------|------|
| [要約版](docs/translations/AI-Driven_Development_Lifecycle_Summary.md) | 全体の概要（最初に読むことを推奨） |
| [背景](docs/translations/AI-DLC_I_CONTEXT_Translation.md) | なぜ AI-DLC が必要か |
| [主要原則](docs/translations/AI-DLC_II_KEY_PRINCIPLES_Translation.md) | AI-DLC を支える 10 の原則 |
| [コアフレームワーク](docs/translations/AI-DLC_III_CORE_FRAMEWORK_Translation.md) | 3つのフェーズの詳細 |
| [実践例（新規）](docs/translations/AI-DLC_IV_IN_ACTION_Translation.md) | Green-Field プロジェクト |
| [実践例（既存）](docs/translations/AI-DLC_V_IN_ACTION_BrownField_Translation.md) | Brown-Field プロジェクト |
| [導入方法](docs/translations/AI-DLC_VI_Adopting_Translation.md) | 組織への導入戦略 |
| [付録A](docs/translations/AI-DLC_AppendixA_ja.md) | プロンプトテンプレート集 |

詳細な読み方ガイドは [docs/translations/README.md](docs/translations/README.md) を参照してください。

### その他

- [CHANGELOG.md](CHANGELOG.md) - バージョンごとの変更履歴

## 設計原則

1. **会話の反転** - AI が作業計画を提示し、人間が承認・判断する
2. **明示的な状態導出** - フェーズは会話履歴の推論ではなく、リポジトリ内の状態から導出する
3. **対話による明確化** - AI が独自判断をせず、不明点は質問
4. **リスクに応じた厚み** - size × depth_level で手続きの重さを変える
5. **短サイクル反復** - define → develop → release を短いサイクルで反復
6. **冪等性の保証** - 各ステップで既存成果物を確認し、差分のみ更新
7. **コンテキスト効率** - 必要最小限のファイルのみ読み込み
8. **work item 単位のコミット** - 追跡可能な粒度で自動的に Git コミットを作成

## 関連リンク

- [オリジナルのホワイトペーパー](https://prod.d13rzhkk8cj2z0.amplifyapp.com) - AWS による AI-DLC 公式ドキュメント

## ライセンス

このリポジトリのオリジナルコンテンツ（プロンプトテンプレート等）は MIT License で提供されています。

AI-DLC 翻訳文書については、オリジナルのホワイトペーパーは AWS (Amazon Web Services) により公開されており、著者は Raju SP です。オリジナルドキュメントには明示的なライセンス情報が記載されていないため、このリポジトリの翻訳文書は学習・参考目的での利用を想定しています。商用利用や再配布については、AWS または著者に直接確認することを推奨します。

## コントリビューション

問題や改善提案がありましたら、Issue や Pull Request をお気軽にお送りください。

## フィードバック

このスターターキットについてのフィードバックや質問は、GitHub Issues でお願いします。

- [フィードバック・改善提案](https://github.com/ikeisuke/ai-dlc-starter-kit/issues/new?template=feedback.yml)
- [バグ報告](https://github.com/ikeisuke/ai-dlc-starter-kit/issues/new?template=bug.yml)
- [機能要望](https://github.com/ikeisuke/ai-dlc-starter-kit/issues/new?template=feature.yml)

**AIで作業中の場合**: 「AIDLCフィードバック」と入力すると、AIがフィードバック送信を案内します。
