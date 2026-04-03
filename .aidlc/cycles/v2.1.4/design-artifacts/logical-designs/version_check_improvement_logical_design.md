# 論理設計: バージョンチェック改善・setup早期判定改修

## 概要

設定キーリネーム・デフォルト有効化・メタ開発スキップ廃止をプロンプトファイルと設定ファイルに反映し、setupスキルの早期判定にバージョン比較ロジックを追加するための変更箇所と処理フローを定義する。

**重要**: この論理設計では**コードは書かず**、コンポーネント構成とインターフェース定義のみを行います。

## アーキテクチャパターン

既存のプロンプト駆動アーキテクチャを維持。設定読み取り→判定→表示のパイプラインパターン。マイグレーション層と実行時解決層の責務分離。

## コンポーネント構成

### ファイル構成

```text
skills/aidlc/
├── config/
│   └── defaults.toml          # [変更] セクション名・デフォルト値
├── steps/
│   └── inception/
│       └── 01-setup.md        # [変更] ステップ6のロジック
skills/aidlc-setup/
├── steps/
│   └── 01-detect.md           # [変更] 早期判定にバージョン比較追加
├── scripts/
│   └── migrate-config.sh      # [変更] マイグレーション処理
.aidlc/
└── config.toml                # [変更] セクション名リネーム
```

### コンポーネント詳細

#### defaults.toml
- **責務**: 新規インストール環境のデフォルト設定値を定義
- **変更内容**: `[rules.upgrade_check]` → `[rules.version_check]`、`enabled = false` → `enabled = true`

#### 01-setup.md（Inception Phase ステップ6）
- **責務**: `/aidlc`起動時の3点バージョン比較の実行・表示
- **依存**: `read-config.sh`（設定値取得）、`curl`（リモート取得）
- **変更内容**:
  - スキップ条件から`STARTER_KIT_DEV`を削除
  - 設定キー参照を`rules.version_check.enabled`に変更（旧キーフォールバック記載）
  - スキップ条件の論理を反転（`enabled = false`の場合にスキップ）

#### 01-detect.md（setup早期判定）
- **責務**: config.toml存在時にバージョン比較を行い、不一致時はアップグレードモードに遷移
- **依存**: `config.toml`（`starter_kit_version`）、スキルの`version.txt`
- **変更内容**: 「1. config.tomlが存在する場合」の処理フローにバージョン比較ステップを追加

#### migrate-config.sh
- **責務**: 旧設定キーから新設定キーへの永続化マイグレーション
- **変更内容**: `_add_section`のパターン・内容を`rules.version_check`に更新

#### .aidlc/config.toml
- **責務**: プロジェクトの設定値
- **変更内容**: セクション名とコメントの更新

## 処理フロー概要

### フロー1: 設定解決（01-setup.md ステップ6）

**ステップ**:
1. `read-config.sh rules.version_check.enabled` を実行
2. exit code 0（値あり）: その値を使用（resolvedFrom=version_check）
3. exit code 1（キー不在）: `read-config.sh rules.upgrade_check.enabled` をフォールバック実行
   - exit 0 → その値を使用（resolvedFrom=upgrade_check）
   - exit 1 → デフォルト値 `true`（resolvedFrom=default）
   - exit 2 → 警告表示 + デフォルト値 `true`（resolvedFrom=error_default）
4. exit code 2（エラー）: 警告表示、旧キーへは進まずデフォルト値 `true`（resolvedFrom=error_default）
5. `enabled = false` の場合: ステップ6全体をスキップ
6. `enabled = true` の場合: 従来の3点バージョン比較を実行（ComparisonMode判定はこのフローの責務として実行）

**関与するコンポーネント**: 01-setup.md, read-config.sh

### フロー2: setup早期判定（01-detect.md）

**ステップ**:
1. `.aidlc/config.toml` の存在を確認
2. 存在する場合: `read-config.sh starter_kit_version` でローカルバージョンを取得
3. スキルの `version.txt` からスキルバージョンを取得（Readツール使用）
4. **フェイルセーフ判定**:
   - いずれかの取得に失敗した場合 → 従来動作（Inception遷移）+ 警告表示
   - 両方取得成功の場合 → 正規化して比較
5. **比較結果**:
   - 一致 → 従来動作（「セットアップ済み」表示 → Inception遷移）
   - 不一致 → アップグレードモード遷移の案内
6. 不存在の場合: 既存ロジック（v1移行 or 初回セットアップ）を維持

**関与するコンポーネント**: 01-detect.md, read-config.sh, version.txt

### フロー3: マイグレーション（migrate-config.sh）

**マイグレーション契約**: 以下の3ケースに対応する。

| 状態 | 処理 |
|------|------|
| 旧セクションのみ存在 | 旧セクション名を`[rules.version_check]`にリネーム、既存の`enabled`値は保持 |
| 新旧両方存在 | 新セクションの値を優先、旧セクションを削除 |
| 新セクションのみ存在 | 何もしない |

**ステップ**:
1. `grep -q "^\[rules\.upgrade_check\]"` で旧セクションの存在を確認
2. 旧セクション存在時:
   - `grep -q "^\[rules\.version_check\]"` で新セクションの存在を確認
   - 新セクション不在 → `sed` で `[rules.upgrade_check]` を `[rules.version_check]` にリネーム（値保持）
   - 新セクション存在 → 旧セクションを削除（新セクションの値を優先）
3. `_add_section "rules\\.version_check"` で新セクションが存在しない場合にデフォルト値で追加（旧セクションもない新規インストール環境向け）

**関与するコンポーネント**: migrate-config.sh

## スクリプトインターフェース設計

### migrate-config.sh（変更箇所のみ）

#### 変更対象: `_add_section` 呼び出し

**変更前**:
- パターン: `rules\\.upgrade_check`
- 内容: `[rules.upgrade_check]`、`enabled = false`

**変更後**:
- パターン: `rules\\.version_check`
- 内容: `[rules.version_check]`、`enabled = true`
- コメント: 「バージョンチェック設定」に更新

## NFRへの対応

### 可用性
- **要件**: リモート取得タイムアウト5秒（既存値維持）
- **対応策**: setup早期判定のフェイルセーフ（取得失敗時は従来動作維持）

## 技術選定

- **言語**: Markdown（プロンプトファイル）、TOML（設定ファイル）、Bash（マイグレーションスクリプト）
- **ツール**: `read-config.sh`（dasel ラッパー）、`curl`（リモート取得）

## 実装上の注意事項

- `01-setup.md`の設定解決順は`read-config.sh`の終了コードで分岐する（0=値あり、1=キー不在、2=エラー）。exit 2の場合は旧キーフォールバックに進まずデフォルト値を採用し警告表示
- `01-detect.md`のバージョン比較は文字列完全一致（semver比較ではない）。正規化（vプレフィックス除去、空白トリム）は01-setup.mdの既存仕様と統一
- `.aidlc/config.toml`のセクション名変更は開発環境のみ。ユーザー環境はmigrate-config.shが対応
- ガイド照合: `guides/exit-code-convention.md` — migrate-config.shの終了コードは既存規約に準拠（変更なし）

## 不明点と質問

（なし）
