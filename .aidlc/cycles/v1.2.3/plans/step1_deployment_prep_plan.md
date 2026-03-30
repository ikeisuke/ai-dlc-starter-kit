# ステップ1: デプロイ準備 計画

## 概要
v1.2.3（6つのBug Fix）のデプロイ準備を行う

## 前提条件（運用引き継ぎ情報より）
- プロジェクトタイプ: ドキュメント・テンプレートプロジェクト（general）
- デプロイ方式: GitHubリポジトリとして公開
- リリース方法: mainブランチへのマージ + タグ作成（自動）
- バージョニング: セマンティックバージョニング

## 今回の変更内容（v1.2.3）
1. Lite版パス解決安定化
2. フェーズ遷移ガードレール強化
3. starter_kit_versionフィールド追加
4. 移行時ファイル削除確認追加
5. 日時記録必須ルール化
6. Inception Phaseステップ6削除

## 作成する成果物
- `docs/cycles/v1.2.3/operations/deployment_checklist.md`

## チェックリスト内容

### コード品質（このプロジェクト向け）
- [ ] 全Unitが完了している
- [ ] 実装がintentの要件を満たしている

### バージョン更新（メタ開発特有）
- [ ] `version.txt` を 1.2.3 に更新
- [ ] setup-init実行で `docs/aidlc/` を最新化

### ドキュメント
- [ ] README.md更新（変更履歴）

### デプロイ手順
1. version.txt更新
2. setup-init実行（アップグレードモード）
3. README.md更新
4. Operations Phase完了コミット
5. PR作成
6. PRマージ（手動）
7. 自動タグ作成（GitHub Actions）

### ロールバック方法
```bash
git checkout v1.2.2
```

## 確認事項
前サイクルで決定済みの設定を再利用するため、追加の質問なし
