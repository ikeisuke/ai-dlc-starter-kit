# Unit 004: サイクルセットアップ分離 - 実装計画

## 概要

inception.md内のサイクルディレクトリ作成処理を専用プロンプト（setup.md）に分離し、責務を明確化する。

## 現状分析

### 現在の inception.md の構造（サイクル関連部分）

- **ステップ 1: サイクル存在確認**（行 245-250）
  - `docs/cycles/{{CYCLE}}/` の存在確認

- **ステップ 1-1: バージョン確認**（行 256-286）
  - GitHubから最新バージョン取得
  - アップグレード推奨の判定

- **ステップ 1-2: サイクルディレクトリ作成**（行 287-371）
  - ディレクトリ構造作成
  - history/ 初期化
  - バックログディレクトリ確認
  - Gitコミット

### 問題点

1. inception.md に複数の責務が混在（セットアップ + 要件定義）
2. サイクル作成処理が長大で、inception.md の本来の目的が見えにくい
3. 他のフェーズ（construction/operations）でもサイクル存在確認があり、案内先が不明確

## 変更計画

### 1. 新規作成: `prompts/package/prompts/setup.md`

**責務**: サイクルディレクトリの作成とバージョン確認

**内容**:
- AI-DLC手法の要約（共通ヘッダー）
- プロジェクト情報（共通部分）
- バージョン確認処理（現行の 1-1）
- サイクルディレクトリ作成処理（現行の 1-2）
- 完了後の案内（Inception Phase へ誘導）

### 2. 修正: `prompts/package/prompts/inception.md`

**変更内容**:
- ステップ 1 を簡素化: サイクル存在確認のみ
- 存在しない場合: setup.md を案内してエラー終了
- ステップ 1-1, 1-2 を削除

**変更後のステップ 1**:
```markdown
### 1. サイクル存在確認
`docs/cycles/{{CYCLE}}/` の存在を確認：

```bash
ls docs/cycles/{{CYCLE}}/ 2>/dev/null && echo "CYCLE_EXISTS" || echo "CYCLE_NOT_EXISTS"
```

- **存在する場合**: 処理を継続（ステップ2へ）
- **存在しない場合**: エラーを表示し、setup-cycle.md を案内
  ```
  エラー: サイクル {{CYCLE}} が見つかりません。

  既存のサイクル:
  [ls docs/cycles/ の結果]

  サイクルを作成するには、以下のプロンプトを読み込んでください：
  docs/aidlc/prompts/setup.md
  ```
```

### 3. 確認: `prompts/package/prompts/construction.md` と `operations.md`

これらのファイルにも同様のサイクル存在確認があるため、整合性を確認:
- 存在しない場合の案内先を setup.md に統一

## 成果物

| ファイル | 操作 |
|---------|------|
| `prompts/package/prompts/setup.md` | 新規作成 |
| `prompts/package/prompts/inception.md` | 修正（ステップ 1-1, 1-2 削除） |
| `prompts/package/prompts/construction.md` | 確認・必要に応じて修正 |
| `prompts/package/prompts/operations.md` | 確認・必要に応じて修正 |

## リスクと対策

| リスク | 対策 |
|-------|------|
| 既存ワークフローへの影響 | setup.md からの Inception Phase 誘導を明確に |
| バージョン確認の欠落 | setup.md に移動するため問題なし |

## 実装順序

1. setup.md 新規作成
2. inception.md 修正
3. construction.md / operations.md 整合性確認
4. 動作確認（ドキュメントレビュー）
