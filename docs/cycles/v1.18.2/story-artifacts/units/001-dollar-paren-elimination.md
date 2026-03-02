# Unit: $()パターン排除とwrite-history.sh --content-file追加

## 概要
プロンプト内のBash実行例から`$()`コマンド置換を排除し、Claude Codeのセミオートモードが許可プロンプトなしで動作するようにする。write-history.shに`--content-file`オプションを追加し、プロンプト全体の呼び出し方式を更新する。

## 含まれるユーザーストーリー
- ストーリー 1: $()パターン排除とwrite-history.sh --content-file追加 (#258)

## 責務
- write-history.shへの`--content-file`オプション追加
- commit-flow.mdの`git commit -m "$(cat <<'EOF'...)"` → Writeツール+`git commit -F`方式への変更
- review-flow.mdのwrite-history.sh呼び出し → Writeツール+`--content-file`方式への変更
- `prompts/package/prompts/common/rules.md`のwrite-history.sh呼び出し例の更新
- inception.md, construction.md, operations.md, operations-release.mdの`gh pr create/edit --body` → `--body-file`方式への変更
- jj環境の`jj describe -m "$(cat <<'EOF'...)"` 同様の置き換え
- `prompts/package/`配下全体の$()横断クリーンアップ検証

## 境界
- シェルスクリプト内部の`$()`は対象外（Claude Codeの許可対象外）
- prose内のリテラルテキスト・インラインコード記法の`$()`は対象外
- 新規機能追加は行わない（既存記述の方式変更のみ）

## 依存関係

### 依存する Unit
- なし

### 外部依存
- gh CLI v2.0+（`--body-file`オプション）

## 非機能要件（NFR）
- **パフォーマンス**: 一時ファイル作成・読込のオーバーヘッドは無視できるレベル
- **セキュリティ**: 一時ファイルは`/tmp`に作成され、使用後に削除されること
- **後方互換性**: 既存の`--content`引数は引き続き動作すること

## 対象範囲と判定手順
- **調査対象**: `prompts/package/`配下の`.md`ファイルおよび`.sh`ファイル全体を調査する
- **修正対象**: `prompts/package/prompts/`配下および`prompts/package/skills/`配下の`.md`ファイル内のBashコードブロックに含まれる`$()`コマンド置換
- **対象外（修正しない）**: シェルスクリプト(`.sh`)内部の`$()`（Claude Codeの許可対象外のため修正不要）、prose内のリテラルテキスト・インラインコード記法の`$()`
- **完了判定**:
  1. 全体調査: `grep -rn '\$(' prompts/package/ --include='*.md' --include='*.sh'` で`prompts/package/`配下全体の`$()`を一覧化し、`.sh`ファイル内の`$()`が修正不要であることを確認
  2. 修正対象抽出: `grep -rn '\$(' prompts/package/prompts/ prompts/package/skills/ --include='*.md'` で修正対象の`.md`ファイル内の`$()`を一覧化
  3. 分類判定: 手順2の各行がBashコードブロック（` ```bash` 〜 ` ``` ` の範囲内）の実行例か、説明文中のインラインコード・リテラルかを目視で分類
  4. 完了条件: Bashコードブロック内の実行例に含まれる`$()`が0件であること

## 技術的考慮事項
- 正本は`prompts/package/`配下を編集。`docs/aidlc/`はrsyncコピー
- commit-flow.mdが最も変更箇所が多い（14箇所）
- Phase A → B → C の段階的実行を推奨

## 実装優先度
High

## 見積もり
1-2セッション

## 関連Issue
- #258

---
## 実装状態

- **状態**: 完了
- **開始日**: 2026-03-02
- **完了日**: 2026-03-02
- **担当**: Claude Code
