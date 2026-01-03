# 監視・分析ガイド

## 概要

このガイドでは、GitHub Insightsを活用してプロジェクトの利用状況を把握する方法を説明します。

### このガイドの目的

- プロジェクトの健全性を確認する
- 利用状況を把握する
- 改善ポイントを発見する

### 対象読者

- **プロジェクトメンテナ**: リポジトリを管理・改善する方
- **プロジェクト利用者**: フォークして自プロジェクトで活用する方

---

## GitHub Insightsへのアクセス

1. GitHubでリポジトリページを開く
2. 上部のタブから **「Insights」** をクリック
3. 左サイドバーから確認したい指標を選択

> **Note**: Insightsの一部機能はリポジトリの可視性（Public/Private）や権限によって利用可能な範囲が異なります。

---

## 確認すべき指標

### Traffic（トラフィック）

リポジトリへのアクセス状況を確認できます。

| 指標 | 説明 |
|------|------|
| Views | ページビュー数（総計） |
| Unique visitors | ユニーク訪問者数 |
| Referring sites | 流入元サイト |
| Popular content | よく閲覧されるページ |

**確認ポイント**:
- 訪問者数の推移（増加傾向か、減少傾向か）
- どのコンテンツが人気か
- どこから流入しているか

### Commits（コミット）

開発活動の活発さを確認できます。

| 指標 | 説明 |
|------|------|
| Commit frequency | コミット頻度 |
| Contributors | 貢献者一覧 |
| Commit history | コミット履歴 |

**確認ポイント**:
- コミット頻度は安定しているか
- 貢献者は増えているか

### Code frequency（コード頻度）

コードベースの変化量を確認できます。

| 指標 | 説明 |
|------|------|
| Additions | 追加された行数 |
| Deletions | 削除された行数 |
| Net changes | 純増減 |

**確認ポイント**:
- 大きな変更があった時期
- リファクタリング（削除が多い）の実施状況

### Dependency graph（依存関係）

依存関係とセキュリティ状況を確認できます。

| 指標 | 説明 |
|------|------|
| Dependencies | このリポジトリが依存しているパッケージ |
| Dependents | このリポジトリに依存しているプロジェクト |
| Security alerts | セキュリティ脆弱性の警告 |

**確認ポイント**:
- セキュリティアラートがないか
- 依存パッケージは最新か

---

## 各指標の活用方法

### 利用状況の把握

1. **Traffic** で全体的なアクセス状況を確認
2. **Popular content** でよく見られるドキュメントを特定
3. **Referring sites** で流入経路を分析

### 改善ポイントの発見

1. **Popular content** から需要の高いコンテンツを把握し、優先的に改善
2. **Code frequency** で活発に開発されている領域を確認
3. **Dependency graph** でセキュリティリスクを早期発見

---

## 定期確認チェックリスト

### 週次確認項目

- [ ] Traffic: 訪問者数の推移を確認
- [ ] Security alerts: 新しいセキュリティアラートがないか確認

### 月次確認項目

- [ ] Commits: コミット頻度と貢献者の推移を確認
- [ ] Code frequency: コード変更量の推移を確認
- [ ] Popular content: 人気コンテンツの変化を確認
- [ ] Dependencies: 依存パッケージの更新状況を確認

---

## 参考リンク

- [GitHub Insights について - GitHub Docs](https://docs.github.com/ja/repositories/viewing-activity-and-data-for-your-repository/about-repository-graphs)
