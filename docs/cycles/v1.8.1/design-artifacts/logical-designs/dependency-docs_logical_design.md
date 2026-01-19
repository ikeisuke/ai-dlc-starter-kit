# 論理設計: 依存コマンド追加手順ドキュメント

## 概要

operations.mdに「依存コマンド追加手順」セクションを追加する。

## 挿入位置

**operations.md**の末尾（「AI-DLCサイクル完了」セクションの後）に新しいセクションとして追加。

理由:

- 運用フローの本筋に影響を与えない
- 付録的な位置づけで参照しやすい
- 将来の拡張ドキュメントも同様の位置に追加可能

## セクション構成

```markdown
---

## 付録: 依存コマンド追加手順

新しい依存コマンドをAI-DLCに追加する手順。

### 1. env-info.shへの追加

#### 1.1 汎用ツールの場合

認証確認が不要なツールを追加する場合。

**追加手順**:
1. `prompts/package/bin/env-info.sh` の `main` 関数に追加

**コード例**:
[具体的なコード例]

#### 1.2 認証が必要なツールの場合

認証確認が必要なツールを追加する場合。

**追加手順**:
1. 専用のチェック関数を作成
2. `main` 関数で専用関数を呼び出し

**コード例**:
[具体的なコード例]

### 2. setup.mdへの追加

#### 2.1 運用ルールへの影響説明追加

**追加場所**: `prompts/package/prompts/setup.md` の「運用ルール」セクション

**コード例**:
[具体的なコード例]

### 3. チェックリスト

依存コマンド追加時の確認項目:
- [ ] env-info.shにコマンド追加
- [ ] setup.mdに影響説明追加
- [ ] 動作確認（env-info.sh実行）
```

## 記載する具体的なコード例

### env-info.sh（汎用ツール追加）

```bash
# main関数内に追加
echo "新ツール名:$(check_tool 新ツール名)"
```

### env-info.sh（認証が必要なツール追加）

```bash
# 新しいチェック関数を追加
check_新ツール() {
    if ! command -v 新ツール >/dev/null 2>&1; then
        echo "not-installed"
        return
    fi
    if 新ツール auth status >/dev/null 2>&1; then
        echo "available"
    else
        echo "not-authenticated"
    fi
}

# main関数内で呼び出し
echo "新ツール:$(check_新ツール)"
```

### setup.md（運用ルールへの追加）

```markdown
- 新ツール: [影響の説明]
```

## 変更ファイル一覧

| ファイル | 変更内容 |
|----------|----------|
| `prompts/package/prompts/operations.md` | 末尾に「付録: 依存コマンド追加手順」セクションを追加 |

## 備考

- docs/aidlc/prompts/operations.mdはrsyncで自動同期されるため、prompts/package/prompts/operations.mdのみを編集
