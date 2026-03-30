# Unit 001 計画: バリデーション共通化とサイクルID緩和

## 概要
サイクル名バリデーション正規表現を共通ライブラリ `prompts/package/lib/validate.sh` に抽出し、非SemVer形式のカスタムサイクル名を正式サポートする。

## 変更対象ファイル

| ファイル | 変更内容 |
|---------|---------|
| `prompts/package/lib/validate.sh` | 新規作成。`validate_cycle` 関数を実装 |
| `prompts/package/bin/write-history.sh` | インラインの `validate_cycle` を削除、`validate.sh` を `source` |
| `prompts/package/bin/setup-branch.sh` | インラインのバージョン検証正規表現を `validate_cycle` に置換 |
| `prompts/package/tests/test_validate_cycle.sh` | `validate.sh` から直接 `source` に変更、カスタム名テストケース追加 |

## 実装計画

### Phase 1: 設計
1. ドメインモデル設計（validate.sh の関数仕様）
2. 論理設計（正規表現パターン、source パス解決方式）

### Phase 2: 実装
1. `prompts/package/lib/validate.sh` を新規作成
   - `validate_cycle` 関数: 緩和された正規表現で SemVer、名前付き SemVer、カスタム名すべてを許可
   - 不正値（空文字、`..`、`/` のみ、制御文字等）は拒否
2. `write-history.sh` のインライン `validate_cycle` を削除し `source` に変更
   - コメント・エラーメッセージの「vX.Y.Z 形式のみ許可」を新仕様に更新
3. `setup-branch.sh` のインラインバリデーションを `validate_cycle` 呼び出しに変更
   - エラーメッセージの「vX.Y.Z, vX.Y.Z-prerelease, または [name]/vX.Y.Z 形式で指定してください」を新仕様に更新
4. テスト更新: カスタム名（`feature-auth`, `2026-03`）の受け入れテスト追加、既存回帰テスト維持
5. テスト実行・確認

## 完了条件チェックリスト

### 機能要件
- [ ] `prompts/package/lib/validate.sh` の新設と `validate_cycle` 関数の実装
- [ ] 正規表現の緩和（非SemVer名の許可）
- [ ] `write-history.sh` からの共通関数呼び出し（インライン実装の削除）
- [ ] `setup-branch.sh` からの共通関数呼び出し（インライン正規表現の削除）
- [ ] コメント・エラーメッセージが新しい許可形式を反映していること

### カスタム名の受け入れ確認（#312）
- [ ] `write-history.sh --cycle feature-auth` が終了コード0で履歴追記されること
- [ ] `write-history.sh --cycle 2026-03` が終了コード0で履歴追記されること

### 既存互換の回帰確認
- [ ] SemVer形式（`v1.21.2`）が `write-history.sh` / `setup-branch.sh` で引き続き正常動作すること
- [ ] 名前付きSemVer形式（`waf/v1.0.0`）が引き続き正常動作すること

### setup-branch.sh の受け入れ確認
- [ ] `setup-branch.sh feature-auth branch` がエラーなく動作すること
- [ ] `setup-branch.sh 2026-03 branch` がエラーなく動作すること
- [ ] 無効値（空文字、`..` 含む値）が拒否されること

### セキュリティ（不正値の拒否確認）
- [ ] 空文字 → 終了コード1
- [ ] `../v1.0.0`, `name/../v1.0.0` → 終了コード1（パストラバーサル）
- [ ] `/` のみ、`/v1.0.0` → 終了コード1
- [ ] 制御文字を含む値 → 終了コード1
