# AI-DLC共通ルール

## 実行前の検証

- **MCPレビュー推奨**: Codex MCP利用可能時は重要な変更前にレビュー
- **指示の妥当性検証**: 実行前に指示が明確か、リスクはないか確認

## フェーズ固有のルール

- **Inception Phase**: Intent作成は対話形式、Unit定義では依存関係を明確化
- **Construction Phase**: 設計と実装を分離（Phase 1で設計、Phase 2で実装）
- **Operations Phase**: デプロイ前にチェックリスト確認、ロールバック手順必須

## 質問と深掘り

ユーザーとの対話で質問する際は、以下のルールに従う：

**質問の目的**:

- 曖昧な要件を明確化する
- 前提条件や制約を確認する
- 複数の解釈がある場合に意図を特定する

**深掘りのテクニック**:

- 「具体的には？」で詳細を引き出す
- 「例えば？」で具体例を求める
- 「なぜ？」で背景・理由を確認する
- ユースケースやシナリオを聞いて理解を深める

**注意事項**:

- 質問の概要を先に提示し、その後は一問一答形式で進める（各フェーズのハイブリッド方式に従う）
- 回答を得てから次の質問に進む
- 独自の解釈で進めず、必ず確認する

## バックログ管理

バックログの保存先は `docs/aidlc.toml` の `[rules.backlog].mode` で設定する。

| mode | 保存先 | 説明 |
|------|--------|------|
| git | `docs/cycles/backlog/*.md` | ローカルファイルがデフォルト（他の保存先も許容） |
| issue | GitHub Issues | GitHub Issueがデフォルト（他の保存先も許容） |
| git-only | `docs/cycles/backlog/*.md` | ローカルファイルのみ（Issue作成禁止） |
| issue-only | GitHub Issues | GitHub Issueのみ（ローカルファイル作成禁止） |

**排他モード（`*-only`）の場合**: 指定された保存先のみを使用し、他の保存先への記録は行わない。

## 禁止事項

- 既存履歴の削除・上書き（historyは追記のみ）
- 承認なしでの次ステップ開始
- 独自判断での重要な決定（必ず質問する）

## コンテキスト要約時の情報保持

会話が長くなりコンテキストが自動要約（コンパクション）される際、以下のAI-DLC関連情報を必ず保持すること：

**保持必須の情報**:

- **現在のサイクル**: 例: `v1.9.1`
- **現在のフェーズ**: `Inception` / `Construction` / `Operations`
- **作業中のUnit**: Unit名と番号（例: `Unit 005: コンテキスト情報保持`）
- **Unitの進行状況**: 現在のステップ（例: `Phase 2: 実装 - ステップ4`）
- **完了済みUnit**: 完了したUnit番号のリスト
- **次に実行すべきアクション**: 中断時の継続ポイント
- **automation_mode**: `semi_auto` または `manual`（コンパクション後に `read-config.sh` で再取得。詳細は `common/compaction.md` を参照）

**保持形式の例**:

```text
[AI-DLC Context]
- Cycle: v1.9.1
- Phase: Construction
- Current Unit: 005 (コンテキスト情報保持) - Phase 2 実装中
- Completed Units: 001
- Next Action: AGENTS.md への変更完了後、テスト実行
- Automation Mode: semi_auto
```
