# Unit 2: ホームディレクトリ共通設定 - 実装計画

## 概要
`~/.aidlc/` にユーザー共通設定を配置できるようにする

---

## 簡易実装先確認

### 1. 対象ファイルの分類

| ファイル | 分類 | 新規/修正 |
|----------|------|-----------|
| `prompts/setup-prompt.md` | ツール側 | 修正 |
| `docs/aidlc/prompts/additional-rules.md` | 成果物側 | 修正 |

### 2. 実装先ファイル一覧

1. **`prompts/setup-prompt.md`**
   - ホームディレクトリ設定の読み込みロジックを追加
   - `~/.aidlc/config.toml` の存在確認と読み込み

2. **`docs/aidlc/prompts/additional-rules.md`**
   - 設定読み込み優先順位の説明を追加
   - ホーム設定 → プロジェクト設定 の順序を明記

---

## 実装内容

### prompts/setup-prompt.md への追加

セットアップ種類の判定前に、ホームディレクトリの設定確認ステップを追加:

```markdown
## 1.5 ホームディレクトリ共通設定の確認

以下のファイルが存在する場合、共通設定として読み込みます:

```bash
ls ~/.aidlc/config.toml 2>/dev/null && echo "HOME_CONFIG_EXISTS" || echo "HOME_CONFIG_NOT_EXISTS"
```

存在する場合、設定内容を確認し、プロジェクト固有設定と統合します。

**優先順位**:
1. プロジェクト固有設定（docs/aidlc.toml）
2. ホームディレクトリ共通設定（~/.aidlc/config.toml）
```

### docs/aidlc/prompts/additional-rules.md への追加

「ホームディレクトリ共通設定」セクションを追加:

```markdown
## ホームディレクトリ共通設定

### 概要
`~/.aidlc/` ディレクトリにユーザー共通設定を配置できます。

### 対応ファイル
- `~/.aidlc/config.toml` - 共通設定ファイル

### 読み込み優先順位
1. **プロジェクト固有設定**（docs/aidlc.toml）- 優先
2. **ホームディレクトリ共通設定**（~/.aidlc/config.toml）- フォールバック

プロジェクト固有設定が存在する場合はそちらが優先され、
存在しないフィールドのみホームディレクトリ設定から読み込まれます。
```

---

## 完了基準

- [ ] prompts/setup-prompt.md にホーム設定確認ステップ追加
- [ ] docs/aidlc/prompts/additional-rules.md に優先順位説明追加
- [ ] ビルド成功（該当なし - ドキュメント変更のみ）
- [ ] テストパス（該当なし - ドキュメント変更のみ）

---

## 備考

- このUnitはドキュメント変更のみで、実際の設定読み込みロジックはAI（Claude等）が解釈して実行する
- `~/.aidlc/` ディレクトリの作成やconfig.tomlのテンプレートは将来のUnitで対応可能
