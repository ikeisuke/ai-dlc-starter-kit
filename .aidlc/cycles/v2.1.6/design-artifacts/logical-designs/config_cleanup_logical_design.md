# 論理設計: 設定キー整理

## 概要

defaults.tomlから不要キーを削除し、関連するプロンプトファイル（preflight.md、rules.md、01-setup.md）とsetupスキル（migrate-config.sh）を同期的に修正する。

**重要**: この論理設計では**コードは書かず**、コンポーネント構成とインターフェース定義のみを行います。

## アーキテクチャパターン

設定ファイル中心アーキテクチャ。defaults.tomlを設定スキーマの正本とし、プロンプトファイルとスクリプトがその設定を参照・解釈する構成。変更は「削除」が中心であり、新規コンポーネントの追加はない。

## コンポーネント構成

### 変更対象コンポーネント

```text
skills/aidlc/
├── config/
│   └── defaults.toml          [変更] キー削除
├── steps/
│   ├── common/
│   │   ├── preflight.md       [変更] 簡素化
│   │   └── rules.md           [変更] リファレンス更新
│   └── inception/
│       └── 01-setup.md        [変更] named_enabledチェック除去
skills/aidlc-setup/
├── scripts/
│   └── migrate-config.sh      [変更] preflightセクション追加除去
```

### 確認のみ（変更なし）

```text
bin/
└── check-size.sh              [確認] キー不在時のフォールバック動作
.aidlc/
└── config.toml                [確認] メタ開発リポジトリの既存size_check設定維持
```

### コンポーネント詳細

#### defaults.toml

- **責務**: 全ユーザー共通の設定デフォルト値を定義
- **変更内容**:
  - `[rules.preflight]` セクション（enabled, checks）を削除
  - `[rules.size_check]` セクション全体を削除
  - `rules.cycle.named_enabled` キーを削除
- **影響**: detect-missing-keys.shが上記キーを欠落として検出しなくなる

#### preflight.md

- **責務**: プリフライトチェックの実行手順を定義
- **依存**: defaults.toml（設定値取得）
- **変更内容**:
  - 手順4（設定値取得）: `--keys` バッチから `rules.preflight.enabled` と `rules.preflight.checks` を除去
  - 手順5（オプションチェック）: `preflight_enabled` の true/false 分岐を除去し、常時全項目実行に変更。`preflight_checks` リスト参照の分岐を除去し、gh/review-tools/config-validation を固定で実行
  - 手順6（結果提示）: `preflight_enabled` と `preflight_checks` に依存する動的表示を静的表示に変更
  - コンテキスト変数: `preflight_enabled` と `preflight_checks` を削除
  - 主要設定値表示: `preflight_enabled` と `preflight_checks` の行を削除

#### rules.md

- **責務**: 共通開発ルールと設定仕様リファレンスを定義
- **変更内容**:
  - 設定仕様リファレンスから `rules.preflight.enabled` と `rules.preflight.checks` を削除
  - `rules.upgrade_check.enabled` を `rules.version_check.enabled` に更新

#### inception/01-setup.md

- **責務**: Inception Phase セットアップ手順を定義
- **変更内容**:
  - ステップ7: `named_enabled` チェックロジック全体を除去
  - ステップ7: `rules.cycle.mode` を直接参照する形式に変更
  - モード分岐フロー: `named_enabled=true` 条件を除去し、mode値で直接分岐

#### migrate-config.sh

- **責務**: setupスキルのアップグレード時にconfig.tomlに新セクションを追加
- **変更内容**:
  - `_add_section "rules\\.preflight"` ブロックを削除

## 互換ポリシー一覧（CompatibilityPolicy）

| 対象キー | 分類 | 参照元 | 移行要否 | 実行時の扱い |
|---------|------|--------|---------|------------|
| `rules.preflight.enabled` | `deleted` | preflight.md（手順4,5） | 参照除去 | read-config.sh exit 1。プロンプトからの参照禁止 |
| `rules.preflight.checks` | `deleted` | preflight.md（手順4,5,6） | 参照除去 | read-config.sh exit 1。プロンプトからの参照禁止 |
| `rules.cycle.named_enabled` | `deleted` | inception/01-setup.md（ステップ7） | 参照除去 | read-config.sh exit 1。プロンプトからの参照禁止 |
| `rules.size_check.*` | `deleted`（defaults.tomlから） | bin/check-size.sh（config.toml直接読み取り） | defaults.toml除去のみ。bin/check-size.shは変更なし | read-config.sh exit 1（defaults.toml不在）。bin/check-size.shはconfig.tomlを直接読み取るため影響なし |
| `rules.upgrade_check.enabled` | `doc_only` | rules.md（設定仕様リファレンス） | 文書更新のみ | read-config.sh内の既存フォールバック（inception/01-setup.md ステップ6）は維持 |

### 削除済みキーの二層契約

- **実行時契約**: 削除済みキーへの`read-config.sh`アクセスはexit 1（キー不在）を返す
- **利用側ルール**: プロンプトファイル・ステップファイルからの削除済みキーへの参照は禁止。万が一参照が残った場合、exit 1が返りデフォルト値なしとなるため、呼び出し元のエラーハンドリング（exit 1時の処理）で安全に失敗する

### 設定値の解決契約

- **マージ順**: defaults.toml → config.toml → config.local.toml
- **優先順位**: config.local.toml > config.toml > defaults.toml（後勝ち）
- read-config.shは上記マージ順で値を重ね合わせ、最終的に最も優先度の高い値を返す

### size_checkの読み取り経路

`size_check`は`project_specific`スコープのキーであり、defaults.toml（schema-managed）には含まれない。

- **bin/check-size.sh**: config.tomlの`[rules.size_check]`を直接読み取り（dasel/grep）。read-config.shは経由しない。スクリプト内にデフォルト値を持ち、セクション不在時はそちらを使用
- **read-config.sh**: defaults.tomlにキーがないためexit 1を返す。ただしconfig.tomlに記載があれば読み取り可能（read-config.shはconfig.tomlも参照するため）。本Unitではこの経路の利用者はいない

## setupテンプレートの変更対象

Unitの「setupテンプレートからpreflight・size_check設定を除外」に対応するファイル:

- **`skills/aidlc-setup/templates/config.toml.template`**: 調査の結果、テンプレートにpreflight/size_checkセクションは含まれていない（変更不要）
- **`skills/aidlc-setup/scripts/migrate-config.sh`**: `_add_section "rules\\.preflight"` ブロックを削除（アップグレード時のpreflight追加を停止）
- **config.toml.template自体には変更なし**: setupテンプレートの責務はここで閉じる

## スクリプトインターフェース設計

### defaults.toml 変更後のインターフェース契約

#### read-config.sh（既存、変更なし）

##### 削除キーへのアクセス

| キー | 変更前 | 変更後 |
|------|--------|--------|
| `rules.preflight.enabled` | exit 0, 値: `true` | exit 1（キー不在） |
| `rules.preflight.checks` | exit 0, 値: `["gh", ...]` | exit 1（キー不在） |
| `rules.size_check.enabled` | exit 0, 値: `true` | exit 1（キー不在）※ |
| `rules.cycle.named_enabled` | exit 0, 値: `false` | exit 1（キー不在） |

※ メタ開発リポジトリではconfig.tomlに直接記載があるため、そちらから読み取られる（exit 0）

#### bin/check-size.sh（確認のみ、変更なし）

- config.tomlの`[rules.size_check]`セクションを直接読み取り
- セクション不在時: grepがマッチせず、デフォルト値（スクリプト内定義）を使用
- メタ開発リポジトリ: config.tomlにsize_check設定を直接記載しているため、動作に影響なし
- 一般ユーザー: config.tomlにsize_check設定がない場合、スクリプト内のデフォルト値で動作

## 処理フロー概要

### preflight.md簡素化の処理フロー

**変更前**:

1. 手順4で `rules.preflight.enabled` と `rules.preflight.checks` を取得
2. 手順5で `preflight_enabled` が false なら全スキップ、true なら `preflight_checks` リストに基づいてチェック
3. 手順6で動的な結果表示

**変更後**:

1. 手順4から preflight 関連キーを除去（取得しない）
2. 手順5で gh/review-tools/config-validation を常時実行
3. 手順6で静的な結果表示

### inception/01-setup.md ステップ7の処理フロー

**変更前**:

1. `read-config.sh rules.cycle.named_enabled` を実行
2. false → cycle_mode を default に設定（modeがnamed/askでも無効化）
3. true → `read-config.sh rules.cycle.mode` でモード分岐

**変更後**:

1. `read-config.sh rules.cycle.mode` を直接実行
2. mode値に応じて分岐（default/named/ask）
3. 無効値 → default にフォールバック

## 非機能要件（NFR）への対応

### 後方互換性

- defaults.tomlからキーを削除しても、ユーザーのconfig.tomlに旧キーが残ることは可能
- read-config.shは config.toml → defaults.toml のマージで動作するため、config.tomlに残っているキーは読み取り可能（ただし本Unitの対象キーはもはやどこからも参照されないため、実質的に無視される）
- named_enabledが旧config.tomlに残っていても、01-setup.mdがもはや参照しないため無視される

### 安全性

- 削除するキーを参照している全箇所を特定し、参照の除去を同時に行う
- bin/check-size.shはread-config.shを使用せず直接config.tomlを読むため、defaults.toml変更の影響を受けない

## 実装上の注意事項

- preflight.mdの簡素化では、コンテキスト変数 `preflight_enabled` と `preflight_checks` を使用している他のステップファイルがないか確認すること
- rules.mdの設定仕様リファレンスは他ステップファイルから「参照」として言及されるため、整合性を確認すること
- migrate-config.shのpreflightブロック削除後、既存のconfig.tomlにpreflightセクションが存在するケースは問題ない（TOMLパーサーは未知セクションを無視する）

## 不明点と質問（設計中に記録）

なし
