# Unit 003: workaround時バックログ追加ルール - 実装計画

## 概要
その場しのぎの対応をする際に本質的な対応をバックログに記録するルールを追加する。

## 変更対象ファイル
- `prompts/package/prompts/construction.md`

## 実装内容

### construction.md への追加（行127「割り込み対応フロー」の前に挿入）

以下のセクションを追加:

```markdown
- **Workaround（その場しのぎ対応）実施時のルール【重要】**: 本質的な解決ではなく、暫定的な対応（workaround）を行う場合、以下を必ず実施する

  **必須手順**:
  1. **workaroundの実装**: 暫定的な対応を実装
  2. **バックログへの記録**: 本質的な対応を `docs/cycles/backlog/` に記録
     - prefix: `chore-` または `refactor-`
     - 内容: 本質的な解決策と、なぜworkaroundを選択したかの理由
  3. **コード内TODOコメント**: workaroundを実装したコード箇所に以下形式でコメント
     ```
     // TODO: workaround - see docs/cycles/backlog/{filename}.md
     ```

  **workaroundの例**:
  - 時間的制約で簡易実装を選択した場合
  - 依存ライブラリの問題を回避するための一時的な対処
  - 本質的な設計変更が必要だが、現在のスコープ外の場合
```

## 設計フェーズ
このUnitはプロンプトファイルの修正のみのため、ドメインモデル設計・論理設計は不要。直接実装を行う。

## 完了基準
- [ ] construction.md に workaround 実施時のルールセクションが追加されている
- [ ] 既存の「気づき記録フロー」との整合性が保たれている
- [ ] Unit定義ファイルの「実装状態」が「完了」に更新されている
- [ ] 履歴ファイルに記録されている
- [ ] Gitコミットが作成されている

## 備考
- 関連バックログ: `docs/cycles/backlog/chore-workaround-backlog-rule.md`
- 対応完了後、このバックログファイルは削除可能
