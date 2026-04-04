# Unit: lintingカスタムコマンド対応

## 概要
rules.lintingにenabled/commandキーを追加し、Markdown lintに使用するコマンドをカスタマイズ可能にする。旧キーmarkdown_lintとの後方互換性を維持する。

## 含まれるユーザーストーリー
- ストーリー 6: lintingカスタムコマンド対応（#523）

## 責務
- defaults.tomlにrules.linting.enabledとrules.linting.commandを追加
- run-markdownlint.shのコマンド取得をread-config.sh経由に変更
- 旧キーmarkdown_lintからenabled/commandへのフォールバック読み取り対応
- プリフライトチェックの設定値取得を新キーに更新

## 境界
- Markdown lint以外のlinter対応は含まない
- command設定はシングルコマンド名のみ（引数は固定で対象パスを付与、シェル展開・パイプ・リダイレクトは非対応）

## 依存関係

### 依存する Unit
- なし（論理的な依存はない。Unit 001とdefaults.toml・preflight.mdを同時編集する場合は競合に注意）

### 外部依存
- なし

## 非機能要件（NFR）
- **後方互換性**: 旧キーmarkdown_lint=trueのみのconfig.tomlでもenabled=trueとして動作すること
- **セキュリティ**: evalを使用しない。コマンドは単一実行ファイル名として扱う

## 技術的考慮事項
- run-markdownlint.sh内でのコマンド実行: `$command $target_path` 形式（evalなし）
- コマンドが存在しない・失敗した場合は非0終了
- フォールバック: markdown_lint=true → enabled=true + command=デフォルト値

## 関連Issue
- #523

## 実装優先度
High

## 見積もり
小規模（defaults.toml、run-markdownlint.sh、preflight.mdの修正）

---
## 実装状態

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
- **エクスプレス適格性**: -
- **適格性理由**: -
