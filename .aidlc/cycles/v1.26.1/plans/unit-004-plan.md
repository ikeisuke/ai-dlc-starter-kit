# Unit 004 計画: read-config.sh --default廃止とバッチモード化

## 概要
read-config.shから--defaultオプションを廃止し、全プロンプトから使用箇所を除去する。preflight.mdは--keysバッチモードに集約。

## 変更対象ファイル
1. `prompts/package/bin/read-config.sh` - --default実装削除
2. `prompts/package/prompts/common/preflight.md` - バッチモード化
3. `prompts/package/prompts/common/rules.md` - --default使用箇所除去
4. `prompts/package/prompts/common/feedback.md` - --default除去
5. `prompts/package/prompts/common/compaction.md` - --default除去
6. `prompts/package/prompts/common/commit-flow.md` - --default除去
7. `prompts/package/prompts/inception.md` - --default除去
8. `prompts/package/guides/config-merge.md` - ドキュメント更新
9. `prompts/package/skills/aidlc-setup/SKILL.md` - --default除去
10. `prompts/package/skills/aidlc-setup/bin/aidlc-setup.sh` - --default除去

## 実装計画

### Step 1: read-config.shから--default実装削除
### Step 2: 全プロンプトから--default除去（単純置換）
### Step 3: preflight.mdを--keysバッチモード化
### Step 4: ドキュメント（config-merge.md, rules.md）の説明更新
### Step 5: grep検証で残存0件を確認

## 完了条件チェックリスト
- [ ] read-config.shから--default実装が削除されている
- [ ] 全プロンプトから--default使用箇所が除去されている
- [ ] preflight.mdが--keysバッチモード1回に集約されている
- [ ] 終了コード（0=値あり, 1=キー不在, 2=エラー）の動作が維持されている
- [ ] `grep -r "\-\-default" prompts/package/` の結果が0件である
