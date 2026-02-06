# Unit 005 計画: セルフアップデート処理の簡略化

## 概要

Operations Phaseのセルフアップデート処理（メタ開発用）を `/aidlc-upgrade` スキル呼び出しに簡略化する。

## 変更対象ファイル

- `docs/cycles/rules.md`

## 実装計画

### 変更内容

`docs/cycles/rules.md` の「カスタムワークフロー」セクション内の「Operations Phase 完了時の必須作業」を以下のように変更:

**現在の記述**:

```
このプロジェクトはメタ開発のため、Operations Phase の最後に以下を実行すること：

```
prompts/setup-prompt.md を読み込んで、AI-DLC 環境をアップグレードしてください
```

**理由**: `prompts/package/` で変更したプロンプト・テンプレートを `docs/aidlc/` に反映するため。

**タイミング**: ステップ6（リリース準備）の前に実行し、rsync による更新を適用してからコミット・PR作成を行う。
```

**変更後の記述**:

```
このプロジェクトはメタ開発のため、Operations Phase のステップ6（リリース準備）の前に以下を実行すること：

```
/aidlc-upgrade
```

**理由**: `prompts/package/` で変更したプロンプト・テンプレートを `docs/aidlc/` に反映するため。
```

## 完了条件チェックリスト

- [ ] `docs/cycles/rules.md` のカスタムワークフロー（Operations Phase完了時の必須作業）を簡略化
- [ ] `/aidlc-upgrade` スキル呼び出しへの置き換え
