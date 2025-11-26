# Operations Phase 再開プロンプト（PRマージ後）

このプロンプトは、PRマージ後にGitタグを作成するために使用します。

---

## 状況

AI-DLC Starter Kit v1.0.0 の Operations Phase がほぼ完了しました。

**完了済み**:
- VERSIONファイル更新（1.0.0）
- リリースノート作成
- Gitコミット
- ブランチpush
- PR作成（https://github.com/ikeisuke/ai-dlc-starter-kit/pull/1）

**ユーザーが実施済み**:
- 動作検証
- PRレビュー
- **PRマージ（feature/v1.0.0-setup → main）**

## 残作業

**Gitタグ `v1.0.0` の作成（mainブランチ）**

## 実行指示

以下の手順でGitタグを作成してください：

1. mainブランチに切り替え
2. リモートから最新を取得
3. Gitタグ `v1.0.0` を作成
4. タグをリモートにpush

```bash
git checkout main
git pull origin main
git tag -a v1.0.0 -m "Release v1.0.0: プロンプト共通化とディレクトリ構造改善"
git push origin v1.0.0
```

## 完了確認

```bash
git tag -l
# v0.1.0
# v1.0.0 ← これが表示されればOK
```

---

**このプロンプトを読み込んだ後、上記の手順を実行してください。**
