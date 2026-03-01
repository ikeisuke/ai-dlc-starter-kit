# コンパクション時の対応【自動要約後】

コンテキストがコンパクション（自動要約）された後は、以下を確認・実行する：

1. このプロンプトファイルの内容が保持されているか確認
2. 保持されていない場合、現在のフェーズのプロンプトを読み込む
3. 作業中の進捗情報を確認して作業を継続

**フェーズごとの再読み込みパス**:

| フェーズ | プロンプトパス | 進捗確認先 |
|---------|-------------|-----------|
| Inception | `docs/aidlc/prompts/inception.md` | `docs/cycles/{{CYCLE}}/inception/progress.md` |
| Construction | `docs/aidlc/prompts/construction.md` | Unit定義ファイル（`docs/cycles/{{CYCLE}}/story-artifacts/units/*.md`）の「実装状態」セクション |
| Operations | `docs/aidlc/prompts/operations.md` | `docs/cycles/{{CYCLE}}/operations/progress.md` |

## セミオートモード時のコンパクション対応

`automation_mode=semi_auto`（`common/rules.md` のセミオートゲート仕様を参照）の場合、コンパクション後に以下を実行する:

1. `docs/aidlc/bin/read-config.sh rules.automation.mode --default "manual"` で `automation_mode` を再取得
2. 上記の再読み込み手順（プロンプト・進捗確認）を実行
3. `automation_mode=semi_auto` を確認できた場合、ユーザーに再開確認を求めずに自動的に作業を継続する
4. グローバルフォールバック条件（`common/rules.md` 参照: 設定読取失敗、実行エラー、前提不成立）に該当した場合、ユーザーに状況を報告し従来フローへ
