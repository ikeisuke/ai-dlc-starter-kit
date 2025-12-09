# Unit 2: フェーズ遷移ガードレール強化

## 概要
各フェーズで禁止されるアクションを明示し、AIがフェーズを無視して先走り実装しないようにする。

## 対象ストーリー
- US-2: フェーズ遷移ガードレールの強化

## 依存関係
なし

## 修正対象ファイル

| ファイル | 変更内容 |
|----------|----------|
| `prompts/setup-cycle.md` | 完了メッセージに「Inception Phaseで計画を立ててから実装」を追加 |
| `docs/aidlc/prompts/inception.md` | 「フェーズの責務【重要】」セクション追加 |
| `docs/aidlc/prompts/construction.md` | 禁止事項の強調 |
| `prompts/package/prompts/inception.md` | 同上（パッケージ版） |
| `prompts/package/prompts/construction.md` | 同上（パッケージ版） |

## 修正内容

### setup-cycle.md 完了メッセージ追加

```markdown
**重要**: Inception Phase で計画を立ててから実装してください。
セットアップ完了後すぐに実装コードを書き始めないでください。
```

### inception.md 追加セクション

```markdown
## フェーズの責務【重要】

**このフェーズで行うこと**:
- 要件の明確化
- ユーザーストーリー作成
- Unit定義

**このフェーズで行わないこと（禁止）**:
- 実装コードを書く
- テストコードを書く
- 設計ドキュメントの詳細化（Construction Phaseで実施）

**承認なしにConstruction Phaseに進んではいけない**
```

### construction.md Phase 1 強調

```markdown
### Phase 1: 設計【コードは書かない】

**重要**: このフェーズでは設計ドキュメントのみ作成します。
実装コードは Phase 2 で承認後に書きます。
```

## 受け入れ基準
- [ ] setup-cycle.mdの完了メッセージに警告が追加されている
- [ ] inception.mdに禁止事項が明記されている
- [ ] construction.mdでPhase 1の禁止事項が強調されている

## 見積もり
小（プロンプト修正のみ）

## 実装時の注意【重要】

Unit 2 開始時に `docs/cycles/v1.2.3/backlog.md` を確認し、関連する気づきがあれば一緒に対応すること。

関連が想定される気づき:
- コンテキストリセットのタイミング見直し
- Unit開始前のバックログ確認がステップ化されていない
