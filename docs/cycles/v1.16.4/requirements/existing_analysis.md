# 既存コード分析 - v1.16.4

## #223: dasel v3 予約語 'branch' による読み取り失敗

### 対象ファイル
- `prompts/package/bin/read-config.sh` の `get_value()` 関数（145-154行目）

### 現状
- v1.16.3 Unit 001でブラケット記法変換（`rules.branch.mode` → `rules["branch"]["mode"]`）が実装済み
- しかしテスト記録(BUG-001)で実運用時に失敗するケースが報告されている

### 推奨修正方針
- ブラケット記法変換の sed 正規表現が正しく機能しているか再検証
- macOS sed の互換性確認
- dasel v2/v3 両環境での統合テスト

---

## #225: issue-ops.sh 認証バグ

### 対象ファイル
- `prompts/package/bin/issue-ops.sh` の `check_gh_available()` 関数（125-133行目）

### 現状のロジック
```bash
check_gh_available() {
    if ! command -v gh >/dev/null 2>&1; then return 1; fi  # gh未インストール
    if ! gh auth status >/dev/null 2>&1; then return 2; fi  # 認証失敗
    return 0
}
```

### 推定原因
- `gh auth status` は複数ホスト構成で、いずれかのホストが失敗すると exit 1 を返す
- GitHub.com には認証済みでも、他のホスト（Enterprise等）の認証情報が無効な場合に誤判定

### 推奨修正方針
- `gh auth status --hostname github.com` で特定ホストの認証のみ確認する
- gh未認証時の従来動作は維持する

---

## #224: read-config.sh の古い使い方更新

### 対象ファイル
- `prompts/package/guides/config-merge.md`（98-129行目）
- `prompts/package/prompts/common/rules.md`（13-17行目）

### 現状
- `prompts/package/bin/` 配下のスクリプトで古い呼び出しは**ない**（スクリプト間は問題なし）
- ドキュメント内の説明が旧インターフェースのまま
- v1.16.3で追加された `--keys` オプション（複数キー一括取得）の説明がない

### 旧パターンと新パターン
```bash
# 旧パターン（単一キーのみ、後方互換で引き続き動作）
docs/aidlc/bin/read-config.sh rules.reviewing.mode

# 新パターン（v1.16.3以降、複数キー一括取得）
docs/aidlc/bin/read-config.sh --keys rules.reviewing.mode rules.reviewing.tools
```

### 推奨修正方針
- config-merge.md に `--keys` オプションの説明を追加
- rules.md の使用例を更新
- 既存の単一キー形式は後方互換として維持

---

## #229: operations.md 完了メッセージ修正

### 対象ファイル と箇所
| ファイル | 行番号 | 修正内容 |
|---------|--------|----------|
| `prompts/package/prompts/operations.md` | 989 | 「start setup」→「start inception」 |
| `prompts/package/prompts/operations.md` | 991 | 「start setup」→「start inception」 |
| `prompts/package/prompts/lite/operations.md` | 82 | 「start setup」→「start inception」 |

### 推奨修正方針
- 3箇所の単純テキスト置換

---

## #219: .claude/settings.local.json 許可設定ルール整理

### 対象ファイル
- `prompts/package/guides/ai-agent-allowlist.md`（セクション4.1 Claude Code）

### 現状の課題
- 既存の `.claude/settings.local.json` に77個の許可エントリが存在
- フルパスと相対パスが混在
- 同じスクリプトに対して複数の表記パターンが存在
- `docs/aidlc/bin/` と `prompts/package/bin/` の両方が許可されている

### 推奨修正方針
1. ai-agent-allowlist.md のClaude Codeセクションに推奨パターンを追記
2. 相対パス統一の推奨
3. AI-DLCスクリプト群の統合パターン例の提示
4. VCS環境対応（jj/git）の設定パターン
