# Unit 003 計画: AIレビューフロー機密情報マスキング手順追加

## 概要

AIレビュー実行前に機密情報を含むファイルを自動除外するステップをreview-flow.mdに追加し、外部AIへの情報漏洩リスクを低減する。スキャンはプロンプト内の手順として記述し、専用スクリプトは作成しない。

## 変更対象ファイル

### Phase A: review-flow.md 変更（正本）

- `prompts/package/prompts/common/review-flow.md` - 機密情報除外スキャンステップの追加

### Phase B: aidlc.toml テンプレート・デフォルト・実体更新

- `prompts/setup/templates/aidlc.toml.template` - `exclude_patterns` 設定コメントの追加
- `prompts/package/config/defaults.toml` - `exclude_patterns` デフォルト値の追加（正本）
- `docs/aidlc.toml` - `[rules.reviewing]` セクションに `exclude_patterns` コメントを追加

**正本と同期コピーの関係**: `prompts/package/config/defaults.toml` が正本。`docs/aidlc/config/defaults.toml` は Operations Phase の rsync で自動同期されるため、Construction Phase では正本のみ編集する。

## 実装計画

### Phase A: review-flow.md に機密情報除外スキャンステップを追加

**挿入位置**: ステップ5（AIレビューフロー）内の「レビュー前コミット」の直後、「種別ごとの反復レビュー」の直前。

**新ステップの構成**:

1. **スキップ条件の明記**: セルフレビュー（ステップ5.5）は外部AIへの送信がないため、このスキャンをスキップ
2. **デフォルト除外パターンの定義**:
   - `.env*`
   - `*.key`
   - `*.pem`
   - `credentials.*`
   - `*secret*`
3. **カスタムパターンの読み込み手順**:
   - `docs/aidlc.toml` の `[rules.reviewing].exclude_patterns` を参照
   - 未設定・空配列: デフォルトパターンのみ適用
   - 非配列型: 警告を出力しデフォルトパターンのみ適用
   - 設定あり: デフォルトパターンに**追加**（デフォルトは常に適用）
4. **スキャン手順**: レビュー対象ファイル一覧に対してパターンマッチング
5. **除外通知フォーマット**: ファイル名のみ通知（内容は含まない）

**通知フォーマット**:

除外ファイルがある場合:

```text
【機密情報除外】以下のファイルをレビュー対象から除外しました:
- .env.local（パターン: .env*）
- config/credentials.json（パターン: credentials.*）

除外パターンは docs/aidlc.toml の [rules.reviewing].exclude_patterns でカスタマイズできます。
```

除外ファイルがない場合: 通知なし（無言で続行）。

**スキャン方式**:

AIエージェントがレビュー対象ファイル一覧を確認する際に、以下の判定を行う（プロンプト内の手順として記述）:

- レビュー対象ファイルの**ベース名（ファイル名部分）**をデフォルト+カスタムパターンと照合
- パターンマッチにはglobパターン（ワイルドカード）を使用
- マッチしたファイルをレビュー対象から除外し、除外後のファイル一覧を以降のAIレビュー呼び出し引数に使用する

**パターンマッチルール**:

- デフォルトパターンはファイルのベース名に適用（例: `credentials.*` は `config/credentials.json` のベース名 `credentials.json` にマッチ）
- カスタムパターンに `**/` や `/` を含む場合はフルパスに適用（例: `config/secrets/**`）
- カスタムパターンに `/` を含まない場合はベース名に適用

**注意**: `$()`パターンはプロンプト内のBashコードブロックで使用しない（Unit 001準拠）。

### Phase B: aidlc.toml テンプレート・デフォルト更新

**`prompts/setup/templates/aidlc.toml.template`**:

`[rules.reviewing]` セクションに `exclude_patterns` をコメント付きで追加:

```toml
[rules.reviewing]
mode = "recommend"
tools = ["codex"]
# exclude_patterns: レビュー対象から除外するファイルパターン（配列）
# - デフォルトパターン(.env*, *.key, *.pem, credentials.*, *secret*)は常に適用
# - ここに追加のパターンを指定可能
# exclude_patterns = ["*.p12", "config/secrets/**"]
```

**`prompts/package/config/defaults.toml`**:

`[rules.reviewing]` セクションに空配列のデフォルトを追加:

```toml
[rules.reviewing]
mode = "recommend"
tools = ["codex"]
exclude_patterns = []
```

**`docs/aidlc.toml`（プロジェクト実体）**:

`[rules.reviewing]` セクションに `exclude_patterns` のコメントを追加:

```toml
[rules.reviewing]
mode = "required"
tools = ["codex"]
# exclude_patterns: レビュー対象から除外するファイルパターン（配列）
# - デフォルトパターン(.env*, *.key, *.pem, credentials.*, *secret*)は常に適用
# - ここに追加のパターンを指定可能
# exclude_patterns = ["*.p12", "config/secrets/**"]
```

**migrate-config.shの変更は不要**: `exclude_patterns`はオプショナル設定であり、未設定時はデフォルトパターンのみで動作するため、既存プロジェクトへの自動マイグレーションは不要。

**正本と同期コピー**: `prompts/package/config/defaults.toml` が正本、`docs/aidlc/config/defaults.toml` は rsync コピー。Construction Phase では正本のみ編集する。

## 完了条件チェックリスト

- [ ] デフォルト除外パターン（`.env*`, `*.key`, `*.pem`, `credentials.*`, `*secret*`）がreview-flow.mdに定義されていること
- [ ] `docs/aidlc.toml`の`[rules.reviewing].exclude_patterns`でカスタムパターンを追加可能であること
- [ ] `exclude_patterns`が未設定・空配列の場合、デフォルトパターンのみで動作すること
- [ ] `exclude_patterns`に不正な値（非配列型等）が設定された場合、警告を出力しデフォルトパターンで動作すること
- [ ] 除外されたファイルがある場合、ファイル名のみをユーザーに通知すること（ファイル内容は含まない）
- [ ] セルフレビュー時はスキャンステップをスキップすること
- [ ] review-flow.mdの機密情報除外スキャンステップがステップ5の反復レビュー開始前に挿入されていること
