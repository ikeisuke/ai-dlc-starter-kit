# Unit 004 計画: ブランチ設定化と個人設定リネーム

## 概要

`aidlc.toml.local` を `aidlc.local.toml` にリネームし、`rules.branch` セクションの設定テンプレート追加を行う。

## 変更対象

### ストーリー6: 個人設定ファイルのリネーム

1. **`prompts/package/bin/read-config.sh`**: `LOCAL_CONFIG_FILE` を `aidlc.local.toml` に変更し、旧名フォールバック + 警告メッセージを追加
2. **`.gitignore`**: `docs/aidlc.local.toml` を追加（旧名 `docs/aidlc.toml.local` も残す）
3. **`prompts/package/prompts/common/rules.md`**: 旧名参照を新名に更新
4. **`prompts/package/prompts/inception.md`**: 旧名参照を新名に更新
5. **`prompts/package/guides/config-merge.md`**: 旧名参照を新名に更新
6. **`prompts/package/bin/migrate-config.sh`**: 旧名参照を新名に更新

### ストーリー5: ブランチ作成方式の設定化

- `prompts/package/config/defaults.toml` に `[rules.branch]` セクションが既に存在することを確認（変更不要の可能性）
- `inception.md` のステップ7で既に `rules.branch.mode` を参照しているか確認（変更不要の可能性）

## 完了条件

- [ ] `read-config.sh` が `aidlc.local.toml`（新名）を優先し、`aidlc.toml.local`（旧名）にフォールバック
- [ ] 旧名のみ存在時に警告を表示
- [ ] `.gitignore` に新名が追加されている
- [ ] `grep -r "aidlc.toml.local" prompts/package/` で `.gitignore` と `read-config.sh` のフォールバック以外に残存がないこと
