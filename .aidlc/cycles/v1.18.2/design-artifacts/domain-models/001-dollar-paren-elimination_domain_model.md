# ドメインモデル: $()パターン排除

## エンティティ

### write-history.sh
- 既存の`--content`引数に加え`--content-file`を受け取る
- 排他制約: `--content`と`--content-file`は同時指定不可
- `--content-file`はファイルパスを受け取り、内容を読み込んで`--content`として処理

### squash-unit.sh
- 既存の`--message`引数に加え`--message-file`を受け取る
- 排他制約: `--message`と`--message-file`は同時指定不可

## 値オブジェクト

### 置換パターン分類
1. **commit-pattern**: `git commit -m "$(cat <<'EOF'...)"` → Write + `git commit -F`
2. **jj-pattern**: `jj describe -m "$(cat <<'EOF'...)"` → Write + `jj describe --stdin <`
3. **squash-pattern**: `SQUASH_MESSAGE="$(cat <<'EOF'...)"` + `--message` → Write + `--message-file`
4. **content-pattern**: `--content "$(cat <<'CONTENT_EOF'...)"` → Write + `--content-file`
5. **body-pattern**: `--body "$(cat <<'EOF'...)"` → Write + `--body-file`
6. **var-pattern**: `VAR=$(command)` → 事前にBash実行して変数格納（スクリプト変更不要。プロンプト記述のみ変更）

## 制約
- 編集対象は`prompts/package/`のみ（`docs/aidlc/`は直接編集しない）
- `.sh`ファイル内部の`$()`は対象外
- 後方互換性を維持（既存の`--content`, `--message`は引き続き動作）
- **回帰防止**: `rules.md`に「プロンプト`.md`のBashコードブロック内で`$()`を使用しない」ルールを新設し、今後の再混入を防止
