# Unit 2: フェーズ遷移ガードレール強化 - ドメインモデル設計

## 概要

AIがフェーズを無視して先走り実装しないよう、各フェーズの責務と禁止事項を明確化する。

## ドメイン分析

### 問題領域

AIエージェントがAI-DLCのフェーズ（Inception → Construction → Operations）を無視して、承認なしに実装を開始してしまう問題。

### 原因分析

1. **setup-cycle.md**: 完了メッセージに「次はInception Phase」とあるが、「実装しないで」の警告がない
2. **inception.md**: 「フェーズの責務分離」セクションはあるが、禁止事項が明示されていない
3. **construction.md**: Phase 1（設計）とPhase 2（実装）の分離は記載されているが、「コードは書かない」の強調が弱い

### 解決アプローチ

各プロンプトに「禁止事項」を明示的に追加し、AIが逸脱しないようガードレールを強化する。

## 変更対象エンティティ（プロンプトファイル）

### 1. setup-cycle.md

**現在の構造**:
- セクション8「完了メッセージ」で次のステップを案内

**追加内容**:
- 完了メッセージに警告を追加
- 位置: 「次のステップ: Inception Phase の開始」の直前

**追加テキスト**:
```markdown
**重要**: Inception Phase で計画を立ててから実装してください。
セットアップ完了後すぐに実装コードを書き始めないでください。
```

### 2. inception.md

**現在の構造**:
- 「フェーズの責務分離」セクション（103-106行目）: 各フェーズの説明のみ

**追加内容**:
- 「フェーズの責務【重要】」セクションを新設
- 位置: 「フェーズの責務分離」セクションを置き換え

**追加テキスト**:
```markdown
### フェーズの責務【重要】

**このフェーズで行うこと**:
- 要件の明確化（Intent作成）
- ユーザーストーリー作成
- Unit定義
- Construction用進捗管理ファイル作成

**このフェーズで行わないこと（禁止）**:
- 実装コードを書く
- テストコードを書く
- 設計ドキュメントの詳細化（Construction Phaseで実施）

**承認なしにConstruction Phaseに進んではいけない**

### フェーズの責務分離
- **Inception Phase**: 要件定義とUnit分解（このフェーズ）
- **Construction Phase**: 実装とテスト（`docs/aidlc/prompts/construction.md`）
- **Operations Phase**: デプロイと運用（`docs/aidlc/prompts/operations.md`）
```

### 3. construction.md

**現在の構造**:
- 「最初に必ず実行すること（5ステップ）」にバックログ確認がない
- Phase 1 タイトル「設計【対話形式、コードは書かない】」

**追加内容A**: バックログ確認ステップ追加
- 位置: ステップ3とステップ4の間に「3.5」として挿入、または「ステップ4」を修正

**追加内容B**: Phase 1 の禁止事項強調
- Phase 1 タイトル直後に警告ボックスを追加

**追加テキストB**:
```markdown
### Phase 1: 設計【対話形式、コードは書かない】

**重要**: このフェーズでは設計ドキュメントのみ作成します。
実装コードは Phase 2 で設計承認後に書きます。
設計レビューで承認を得るまで、コードファイルを作成・編集してはいけません。
```

## 影響範囲

### 直接影響
- 新規セットアップ時の動作
- Inception Phase開始時の動作
- Construction Phase開始時の動作

### パッケージ版への波及
- `prompts/package/prompts/inception.md`
- `prompts/package/prompts/construction.md`

両ファイルに同様の変更を適用する必要がある。

## 受け入れ基準との対応

| 基準 | 対応するエンティティ |
|------|---------------------|
| setup-cycle.mdの完了メッセージに警告が追加されている | setup-cycle.md |
| inception.mdに禁止事項が明記されている | inception.md |
| construction.mdでPhase 1の禁止事項が強調されている | construction.md |
| construction.mdにバックログ確認ステップが追加されている | construction.md |
| パッケージ版にも同様の変更が反映されている | package/prompts/* |
