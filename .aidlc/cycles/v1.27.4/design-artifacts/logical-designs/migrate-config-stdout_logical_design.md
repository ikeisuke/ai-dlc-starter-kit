# 論理設計: migrate-config警告検出のstdout解析移行

## コンポーネント構成

### 変更対象
- `prompts/package/skills/aidlc-setup/bin/aidlc-setup.sh` — Step 5 セクション（L385-401）

### 変更しない
- `prompts/package/bin/migrate-config.sh` — 出力フォーマットは現状維持

## 実装方式

### stdout キャプチャと判定

1. `$()` でmigrate-config.shのstdout出力を変数にキャプチャ（シェルスクリプト内部の`$()`は禁止対象外）
2. 終了コードでエラー判定（0以外 → エラー）
3. **stdoutは再出力しない**: キャプチャした出力は内部判定のためだけに使用する。migrate-config.shの生出力はaidlc-setup.shのシグナル出力と混在するため、再出力するとシグナル解析の競合が発生する
4. `grep -q '^warn:'` でwarn行の存在を確認
5. warn行があれば `warn:migrate-warnings` をaidlc-setup.shのシグナルとして出力

### 現行コードとの差分（互換性影響）

| 項目 | 変更前（現行） | 変更後 | 互換性影響 |
|------|--------------|--------|----------|
| migrate-config.shのstdout | そのまま上位に流れる | 変数にキャプチャ（上位には流さない） | migrate-config.shの詳細出力（`added:`, `migrated:`等）がaidlc-setup.sh呼び出し元から見えなくなる。aidlc-setupスキルはシグナル行（`warn:`, `error:`, `migrate:`等）のみを解析するため影響なし |
| migrate-config.shのstderr | そのまま上位に流れる | そのまま上位に流れる（変更なし） | エラー時の診断情報は維持される |
| 警告検出方式 | exit 2 で判定 | stdout内の`warn:`行で判定 | exit 2が返らなくなったため、この変更で正しく警告を検出できるようになる |
| エラー検出方式 | exit 0,2以外で判定 | exit 0以外で判定 | exit 2もエラー扱いになるが、v1.27.3以降migrate-config.shはexit 2を返さないため実質影響なし |
| 出力順序 | migrate-config.shの出力 → aidlc-setup.shのシグナル | aidlc-setup.shのシグナルのみ | シグナル解析に影響なし |

### エッジケース考慮
- migrate-config.shの出力が空の場合: grepにマッチしない → 警告なし（正常動作）
- migrate-config.shが複数のwarn行を出力する場合: `warn:migrate-warnings`は1回のみ出力
- migrate-config.shがstderrに出力する場合: stdoutキャプチャのみなのでstderrは通常通り上位に流れる
