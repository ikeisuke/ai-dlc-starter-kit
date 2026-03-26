# Unit 001: エクスプレスモードインスタント起動 - 計画

## 概要

「start express」コマンドでaidlc.tomlの事前設定変更なしにエクスプレスモードを直接起動できるようにする。

## 変更対象ファイル

1. `prompts/package/prompts/AGENTS.md` — フェーズ簡略指示テーブルに「start express」行を追加
2. `prompts/package/prompts/CLAUDE.md` — フェーズ簡略指示テーブルに「start express」行を追加
3. `prompts/package/prompts/common/rules.md` — エクスプレスモード仕様に「コマンドオーバーライド」優先順位を追記
4. `prompts/package/prompts/inception.md` — 「start express」コマンド検出ロジックとdepth_levelオーバーライドを追加

## 実装計画

### 1. AGENTS.md / CLAUDE.md テーブル更新

フェーズ簡略指示テーブルに以下の行を追加:

| 指示 | 対応処理 |
|------|----------|
| 「start express」 | Inception Phase（エクスプレスモード、depth_level=minimalで起動） |

既存テーブルの「start setup」行の下に追加する。

### 2. common/rules.md エクスプレスモード仕様更新

エクスプレスモード仕様セクションに「depth_level解決優先順位」を追記:

1. コマンドオーバーライド（`start express` による `minimal` 指定）
2. 設定ファイル（`aidlc.toml` の `rules.depth_level.level`）
3. デフォルト値（`standard`）

これによりSingle Source of Truth（rules.md）に優先順位ルールが集約され、inception.mdはそれを参照するだけになる。

### 3. inception.md コマンド検出ロジック

inception.md の初期化シーケンスにおいて、Part 2（インセプション準備）のステップ15（Depth Level確認）の前後に「start express」コマンド検出ロジックを追加する。

**検出方法**: ユーザーの初回入力（セッション開始トリガー）が「start express」であるかをtrim+完全一致で判定。

**検出時の動作**:
- `depth_level` をセッション内限定で `minimal` にオーバーライド（`depth_level_source=command_override`）
- ステップ15の `read-config.sh` 呼び出し結果を無視し、`minimal` を使用
- オーバーライド適用時に以下のメッセージを表示（可観測性確保）:
  ```text
  【エクスプレスモード】「start express」コマンドにより depth_level=minimal をセッション内オーバーライドしました（設定ファイルの値は無視されます）
  ```
- 以降のフローは既存のエクスプレスモード仕様（rules.md）に従う

**実装位置**: ステップ15の直前に「ステップ14b: エクスプレスモードインスタント検出」として挿入。

### 4. AGENTS.md サイクル判定への影響

サイクル判定セクションには変更不要。「start express」はInception Phaseとして処理され、ブランチがcycleでない場合は通常のInception開始フローが適用される。

## 完了条件チェックリスト

- [ ] AGENTS.md / CLAUDE.md のフェーズ簡略指示テーブルに「start express」を追加
- [ ] inception.md で「start express」コマンドを検出し、セッション内限定で depth_level=minimal にオーバーライドするロジックを実装
- [ ] 既存のエクスプレスモード仕様（rules.md）との整合性を維持
