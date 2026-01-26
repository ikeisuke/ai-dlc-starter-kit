# 外部ファイル参照ガイド

このガイドでは、AI-DLCプロンプト内で外部ファイルを参照する方法を説明します。

## 参照方式

### 推奨: instruction-based（指示形式）

プロンプト内にファイル読み込み指示を記述し、AIがReadツールを使用してファイルを読み込む方式です。

**推奨形式**（Claude Code / KiroCLI 両対応）:

```markdown
**【次のアクション】** 今すぐ `docs/aidlc/prompts/common/intro.md` を読み込んで、内容を確認してください。
```

**シンプル形式**（Claude Code のみ確実に動作）:

```markdown
`docs/aidlc/prompts/common/intro.md` を読み込んでください。
```

### 参考: @notation（@ 記法）

Claude Code 限定の機能です。KiroCLI では動作しません。

```markdown
@docs/aidlc/prompts/AGENTS.md
```

**特徴**:
- Claude Code がファイル内容を自動的にコンテキストに追加
- ネスト参照は不可（1段階のみ）
- KiroCLI では解釈されない

## 環境別の動作

| 指示形式 | Claude Code | KiroCLI |
|----------|-------------|---------|
| 推奨形式 | 成功 | 成功 |
| シンプル形式 | 成功 | 認識のみ（実行しない場合あり） |
| @notation | 成功 | 非対応 |

## ネスト参照

instruction-based 方式では、複数段階のネスト参照が可能です。

**例**: ファイルA → ファイルB → ファイルC

```markdown
# ファイルA
**【次のアクション】** 今すぐ `path/to/fileB.md` を読み込んで、内容を確認してください。
```

```markdown
# ファイルB
**【次のアクション】** 今すぐ `path/to/fileC.md` を読み込んで、内容を確認してください。
```

**検証済みの深度**: 3段階まで動作確認済み

## ベストプラクティス

1. **KiroCLI互換性が必要な場合**: 推奨形式を使用
2. **Claude Code のみの場合**: シンプル形式でも可
3. **ネスト深度**: 実用的には2-3段階を推奨
4. **パス形式**: rsync後のパス（`docs/aidlc/...`）を使用

## 関連ドキュメント

- PoC検証結果: `docs/cycles/v1.9.0/construction/units/reference-poc_implementation.md`
- KiroCLI対応: `docs/aidlc/prompts/AGENTS.md` の「KiroCLI対応」セクション
