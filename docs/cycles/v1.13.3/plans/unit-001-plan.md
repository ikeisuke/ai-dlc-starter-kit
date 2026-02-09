# Unit 001 計画: progress.md更新タイミング修正

## 概要

Construction PhaseでUnitブランチ使用時、Unit定義ファイルの「実装状態」更新タイミングとPR作成の関係が不明確な問題を修正する。Operations Phase ステップ6.4.5の「PR準備完了」パターンをConstruction Phaseにも適用する。

**用語対応**: Construction PhaseではUnit定義ファイルの「実装状態」がOperations Phaseの `progress.md` と同等の進捗管理の役割を担う。新規の `construction/progress.md` ファイルは作成しない。

## 変更対象ファイル

- `prompts/package/prompts/construction.md` （メイン変更）

## 実装計画

### 変更1: ステップ1の説明に「PR準備完了」の解釈を追加

現在のステップ1は Unit定義ファイルの「実装状態」を「完了」に更新するが、Unitブランチ使用時の「完了」の意味が不明確。Operations Phase ステップ6.4.5と同様に「PR準備完了 = 完了」の解釈を明記する。

**修正箇所**: ステップ1（Unit定義ファイルの「実装状態」を更新）

**追加内容**:
- 「完了」は「PR準備完了」を意味する旨の注釈（Operations Phase ステップ6.4.5と同一の解釈）
- Unitブランチ使用時はこの更新がGitコミット（ステップ4）に含まれ、PRに正確な状態が反映される旨の説明

### 変更2: コミットチェックリストの修正

現在のステップ4のコミットチェックリストに `進捗ファイル（Operations Phase）: docs/cycles/{{CYCLE}}/operations/progress.md` がある。Construction Phaseのコミットでは不要なため削除する。

**修正箇所**: ステップ4（Gitコミット）の「重要ファイルの確認」チェックリスト

**変更内容**:
- `進捗ファイル（Operations Phase）: docs/cycles/{{CYCLE}}/operations/progress.md` 行を削除

### 変更3: ステップ5（Unit PR作成・マージ）に注意事項を追加

Operations Phase ステップ6.6の注意事項と同様、PR作成後は新たな変更を加えない旨の禁止ルールを追記する。

**修正箇所**: ステップ5（Unit PR作成・マージ）の「はい」の場合セクション

**追加内容**:
- PR作成後はUnit定義ファイルが既にステップ1で「完了」（= PR準備完了）として更新済みである旨の注記
- PR作成後は、バグ修正や追加要件がない限り新たな変更を加えないこと（Operations Phase ステップ6.6準拠）
- コミット漏れが見つかった場合は、漏れていたファイルのみ追加コミットすること

## 完了条件チェックリスト

- [ ] Unit定義ファイルの「実装状態」更新ステップ（ステップ1）に「PR準備完了 = 完了」の解釈が明記されている
- [ ] ステップ1の更新がPR作成（ステップ5）前のGitコミット（ステップ4）に含まれることが手順として明確化されている
- [ ] ステップ5にPR作成後の変更禁止ルールが記載されている
- [ ] コミットチェックリストから不要な `operations/progress.md` 参照が削除されている
- [ ] Unitブランチを使用しない場合の既存動作に影響がない
