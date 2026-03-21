# 論理設計: ワイルドカードルール検出による重複防止

## コンポーネント構成

変更対象は `prompts/package/bin/setup-ai-tools.sh` 内の2つの既存関数のみ。

### `_merge_permissions_jq()` の変更

**現在のフロー**:
1. テンプレートからデフォルトallow配列を取得
2. `$defaults - $existing` で差集合（新規パターン）を算出
3. 新規パターンをexistingに追加

**変更後のフロー**:
1. テンプレートからデフォルトallow配列を取得
2. `$defaults - $existing` で差集合（新規パターン候補）を算出
3. **既存ルールからワイルドカードパターンを抽出** ← 追加
4. **新規パターン候補から、ワイルドカードに包含されるものを除外** ← 追加
5. 残った新規パターンをexistingに追加

**jqでの包含判定ロジック**:

```
# 既存ルールからワイルドカード（:*) で終わるもの）を抽出
$existing | map(select(endswith(":*)")))

# 各候補について、ワイルドカードに包含されるかチェック
# 1. 候補から Type( と ) を除去してパス部分を取得
# 2. ワイルドカードから Type( と :*) を除去してプレフィックスを取得
# 3. 同一Type かつ パスがプレフィックスで始まるか判定
```

### `_merge_permissions_python()` の変更

**変更後のフロー**: jq版と同一。

**Pythonでのヘルパー関数**:

```python
def is_covered_by_wildcard(rule, wildcards):
    """ルールがワイルドカードルールのいずれかに包含されるか判定"""
    # rule が Type(...) 形式でなければ False
    # ワイルドカードの各要素について:
    #   - 同一Type かつ パスがプレフィックスで始まれば True
    return False
```

### `setup_claude_permissions()` の変更

ログ出力のみ。スキップされたルールがある場合に情報メッセージを追加:

```
Updated: .claude/settings.json (N new permissions added, M skipped by wildcard)
```

既存の `new_count` と別に `skipped_count` を受け渡す必要がある。stderrは単一整数のまま維持するため、`_new_count` と同様に `_skipped_count` をJSON一時メタデータとして返す。

## インターフェース

### 関数シグネチャ（変更なし）

- `_merge_permissions_jq(existing_file)` → stdout: マージ済みJSON, stderr: new_count, 戻り値: 0/1/2
- `_merge_permissions_python(existing_file)` → stdout: マージ済みJSON, stderr: new_count, 戻り値: 0/1/2

### 内部メタデータ（追加）

stdoutのJSON内に `_skipped_count` を一時的に含め、呼び出し側で抽出・削除する（`_new_count` と同パターン）。

## エラーハンドリング

- パース不能なルール文字列: 非包含として扱い、通常どおりマージ対象とする
- ワイルドカード抽出失敗: 包含チェックをスキップし、従来どおりの動作にフォールバック
