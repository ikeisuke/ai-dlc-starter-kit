# Unit 002 計画: マーケットプレイス対応

## 概要

AI-DLCスキルのマーケットプレイス方式を実装する。リポジトリルートに `.claude-plugin/marketplace.json` を作成し、`/plugin marketplace add` + `/plugin install <スキル名>` でのインストールを可能にする。同時に、既存の埋め込み方式（sync-package.sh → setup-ai-tools.sh）との共存を確認する。

## 2方式の責務分離

| 方式 | 責務 | Source of Truth | 対象ユーザー |
|------|------|----------------|-------------|
| マーケットプレイス方式 | 選択的な個別スキル配布・インストール | `.claude-plugin/marketplace.json` | 外部プロジェクトの利用者 |
| 埋め込み方式 | スターターキット同梱スキルの一括同期・リンク作成 | `prompts/package/skills/` | スターターキット自体の開発者・同梱利用者 |

**競合時の優先ルール**: 両方式は共存するが、同一スキルが両経路で導入された場合、埋め込み方式（setup-ai-tools.sh によるシンボリックリンク）が上書きする。理由: 埋め込み方式はスターターキットバージョンと整合するスキルを保証するため。マーケットプレイス方式は埋め込み方式を使用しないプロジェクトや、追加スキルの選択的導入に使用する。

## 変更対象ファイル

### 新規作成

- `.claude-plugin/marketplace.json` — リポジトリルートに配置。スキルカタログ定義

### 変更なし（動作確認のみ）

- `prompts/package/bin/setup-ai-tools.sh` — 埋め込み方式の回帰確認
- `prompts/package/bin/sync-package.sh` — `.claude-plugin/` はリポジトリルート配置であり rsync 対象外のため変更不要
- `docs/aidlc/bin/setup-ai-tools.sh` — sync後のシンボリックリンク作成確認

## marketplace.json スキーマ契約

`claude-skills` リポジトリのパターンに準拠した JSON 形式:

| フィールド | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| `name` | string | Yes | リポジトリ識別名 |
| `owner.name` | string | Yes | 所有者名 |
| `owner.email` | string | Yes | 所有者メール |
| `metadata.description` | string | Yes | カタログの説明 |
| `metadata.version` | string | Yes | カタログバージョン（semver） |
| `plugins[].name` | string | Yes | プラグイングループ名 |
| `plugins[].description` | string | Yes | グループの説明 |
| `plugins[].source` | string | Yes | ソースディレクトリ（相対パス） |
| `plugins[].strict` | boolean | No | 厳格モード（デフォルト: false） |
| `plugins[].skills[]` | string[] | Yes | スキルパス一覧（相対パス） |

**ID規約**: スキルの識別子はディレクトリ名（スラッグ）と一致する。`/plugin install` で指定するスキル名はこのスラッグを使用する（例: `reviewing-code`, `session-title`）。大文字小文字は区別しない。エイリアスは設けない。

## 実装計画

### Phase 1: 設計

1. **ドメインモデル設計**: marketplace.json のスキーマ構造、スキルカタログのエンティティ定義、2方式の責務境界
2. **論理設計**: marketplace.json の配置場所（リポジトリルート `.claude-plugin/`）、skills パスの参照規則

### Phase 2: 実装

3. **marketplace.json 作成**:
   - 上記スキーマ契約に準拠
   - AI-DLCスキルをカタログに登録（`versioning-with-jj` は Unit 004 で削除予定のため除外）
   - カタログID = スキルディレクトリ名（スラッグ）

4. **動作確認**:
   - `/plugin marketplace add` でリポジトリ登録
   - `/plugin install <スキル名>` で個別スキルインストール（スキル名 = スラッグ）
   - エラーケース: 存在しないスキル名指定時にエラーメッセージ表示
   - エラーケース: 再インストール時に上書き更新
   - 埋め込み方式（`/aidlc-setup` → sync-package.sh → setup-ai-tools.sh）の回帰確認
   - reviewing-*, session-title, squash-unit スキルの呼び出し確認

## 完了条件チェックリスト

- [ ] `marketplace.json` が上記スキーマ契約に準拠し、全スキルのカタログIDが定義されている
- [ ] `/plugin marketplace add` でAI-DLCスキルリポジトリを登録できる
- [ ] `/plugin install <スキル名>` で個別スキルインストールできる（スキル名 = スラッグ）
- [ ] 存在しないスキル名を指定した場合、エラーメッセージが表示されインストールされない
- [ ] 埋め込み方式（sync-package.sh → setup-ai-tools.sh → シンボリックリンク作成）の回帰確認済み
- [ ] reviewing-*, session-title, squash-unit スキルが呼び出し可能であることを確認済み
