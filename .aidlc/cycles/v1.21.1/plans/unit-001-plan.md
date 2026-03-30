# Unit 001: 名前付きサイクル履歴修正 - 実装計画

## 概要
write-history.shの`validate_cycle()`関数が`/`を含むサイクル名を一律拒否しているため、名前付きサイクル（`name/vX.X.X`形式）の履歴書き込みが失敗する。setup-branch.shと同じ正規表現パターンに揃えて修正する。

## 変更対象ファイル
- `prompts/package/bin/write-history.sh` — `validate_cycle()`関数の修正（1箇所）

## 実装計画

### Phase 1: 設計（depth_level=standardのため実施）

1. **ドメインモデル設計**: シンプルなバリデーション修正のため、最小限のドメインモデル
2. **論理設計**: validate_cycle()の正規表現変更

### Phase 2: 実装

1. `validate_cycle()`関数を以下のように修正:
   - 現在: 空文字チェック → `/`を含む場合は拒否
   - 修正後: 空文字チェック → 正規表現 `^([a-z0-9][a-z0-9-]*/)?v[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.]+)?$` でバリデーション
   - setup-branch.shと完全に同一の正規表現パターンを採用（prereleaseサフィックス含む）
2. エラーメッセージの更新（`Cannot be empty or contain '/'` → 適切な形式説明に変更）

### セキュリティ考慮
- `../` を含むパスは正規表現で自動的に拒否される（`[a-z0-9][a-z0-9-]*` にドットが含まれないため）
- 後方互換: `vX.X.X`形式は `([a-z0-9][a-z0-9-]*/)?` がオプショナルなため引き続き受け入れ

## 完了条件チェックリスト
- [ ] write-history.shのvalidate_cycle()関数が`name/vX.X.X`形式を受け入れる
- [ ] パストラバーサル防止のバリデーションが維持される（`../`含むパスを拒否）
- [ ] 従来の`vX.X.X`形式との後方互換性が維持される
- [ ] prerelease付き形式（`vX.Y.Z-rc.1`, `name/vX.Y.Z-beta`等）がsetup-branch.shと同様に受け入れられる
