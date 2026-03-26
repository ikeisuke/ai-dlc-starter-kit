# Unit 003 計画: プロンプトブランチ管理改善

## 概要

Inception Phase・Operations Phaseのプロンプトを改善し、main最新化チェックの表示、非正規ブランチ時のサイクルブランチ提案、名前付きサイクル候補表示を実装する。

## 変更対象ファイル

- `prompts/package/prompts/inception.md` — ステップ5.5改善 + ステップ7改善
- `prompts/package/prompts/operations-release.md` — main差分チェックステップ追加

## 実装計画

### サブスコープA: Inception Phase ステップ7改善（#307, #303）

**現状**: ステップ7ではmain/masterの場合のみブランチ作成処理があり、「それ以外のブランチ」は次ステップへ進行するだけ。

**変更内容**:

1. setup-branch.sh実行後、出力に含まれる`main_status:`行をパースして表示
   - `up-to-date`: 情報メッセージ「mainブランチは最新です」
   - `behind`: 警告メッセージ「mainブランチに未取り込みの変更があります。マージ/リベースを推奨します」
   - `fetch-failed`: 情報メッセージ「リモートの確認に失敗しました（オフライン環境等）。処理を続行します」
2. 「それ以外のブランチ」の判定を拡張:
   - `cycle/vX.X.X`または`cycle/name/vX.X.X`パターンに一致 → 従来通り次ステップへ進行
   - detached HEADまたは非正規ブランチ → AskUserQuestionで3択を提示:
     1. 新しいサイクルブランチを作成する
     2. 既存のサイクルブランチに切り替える（`cycle/`プレフィックスのブランチが存在する場合のみ表示）
     3. 現在のブランチで続行する（非推奨）

### サブスコープB: Inception Phase ステップ5.5改善（#302）

**現状**: mode=namedの場合、自由テキスト入力でサイクル名を求める。

**変更内容**:

1. mode=namedの場合、`docs/cycles/`配下の既存名前付きサイクル名を検出
2. 既存名がある場合 → AskUserQuestionで選択肢として昇順表示 + 最後に「新規作成」オプション
3. 既存名がない場合 or 読み取り失敗 → 従来通り自由テキスト入力
4. ステップ5.6との重複整理: 5.5で候補表示を統合し、5.6は5.5で未選択の場合の継続確認のみに絞る

### サブスコープC: Operations Phase改善（#307）

**現状**: operations-release.mdにmainとの差分チェックがない。

**変更内容**:

1. ステップ6.6.6（リモート同期チェック）の後、新ステップ「6.6.7 mainブランチとの差分チェック」を追加
2. プロンプト内でAIにgitコマンド実行を指示する形式（setup-branch.shは使用しない。Operations Phaseでは既にブランチが存在するため、Inception Phase用のsetup-branch.shとは異なるコンテキスト）
3. `GIT_TERMINAL_PROMPT=0 git fetch origin` + `git merge-base --is-ancestor`で判定
4. 結果に応じたメッセージ表示:
   - up-to-date: 確認メッセージのみ
   - behind: 警告 + マージ/リベース推奨
   - fetch-failed: 情報メッセージ、処理続行

## 完了条件チェックリスト

- [ ] main最新化チェック結果（main_status行）がステップ7で表示される
- [ ] fetch-failed時の情報メッセージが表示される
- [ ] 非正規ブランチ（cycle/vX.X.X以外）でAskUserQuestionが表示される
- [ ] detached HEADでもAskUserQuestionが表示される
- [ ] main/masterブランチでは従来の処理が維持される
- [ ] mode=namedで既存名前付きサイクル名が選択肢に昇順表示される
- [ ] 「新規作成」オプションが最後に含まれる
- [ ] docs/cycles/ 読み取り失敗時は自由入力にフォールバックする
- [ ] operations-release.mdにmainとの差分チェックステップが追加される
- [ ] 差分ありの場合マージ/リベース推奨が表示される
- [ ] fetch-failed時の情報メッセージが表示される（Operations Phase）
