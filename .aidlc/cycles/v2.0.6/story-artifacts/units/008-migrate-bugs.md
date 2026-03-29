# Unit: マイグレーション処理バグ修正（4件）

## 概要
`/aidlc migrate` 実行時に発生する4件のバグを修正する。

## 修正内容

### Bug 1: docs/aidlc.toml が移動後も残存
- `migrate-apply-config.sh`: `cp` 後に元ファイルを `rm` で削除

### Bug 2/3: AGENTS.md / CLAUDE.md の参照先が未更新
- `migrate-apply-config.sh`: `@docs/aidlc/prompts/` → `@skills/aidlc/` への参照更新を追加

### Bug 4: .kiro/agents/aidlc.json の壊れたシンボリックリンク
- `migrate-cleanup.sh`: symlink解決時に相対パスをsymlinkディレクトリ基準で解決
- ターゲット不在時はv2テンプレートからコピー、テンプレートも不在なら壊れたsymlinkを削除

## 依存関係
なし

---
## 実装状態

- **状態**: 完了
- **開始日**: 2026-03-29
- **完了日**: 2026-03-29
- **担当**: -
- **エクスプレス適格性**: -
- **適格性理由**: -
