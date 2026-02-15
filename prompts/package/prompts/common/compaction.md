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
