# Unit 002 計画: session-titleスキル移行

## 概要

session-titleスキルをai-dlc-starter-kitから削除し、外部リポジトリ（claude-skills）からのインストールに移行する。各フェーズプロンプトの参照を更新する。

## 変更対象ファイル

1. `prompts/package/skills/session-title/` - ディレクトリごと削除
2. `prompts/package/prompts/inception.md` - L174-176 session-title呼び出し箇所を更新
3. `prompts/package/prompts/construction.md` - L206-210, L309-313 session-title呼び出し箇所を更新
4. `prompts/package/prompts/operations.md` - L146-150 session-title呼び出し箇所を更新
5. `prompts/package/prompts/common/ai-tools.md` - L29, L63 スキルカタログからsession-titleを削除
6. `prompts/package/guides/skill-usage-guide.md` - L40, L83, L100, L128, L147, L223, L246 参照を更新

## 実装計画

1. `prompts/package/skills/session-title/` ディレクトリを削除
2. フェーズプロンプト（inception/construction/operations）のsession-title呼び出しセクションを「オプショナルスキル」として更新（スキルが利用可能な場合のみ実行、利用不可の場合はスキップ）
3. ai-tools.mdからsession-titleのエントリを削除（スターターキット同梱でなくなるため）
4. skill-usage-guide.mdの参照を更新し、外部リポジトリからのインストール案内を明示

## 完了条件チェックリスト

- [ ] prompts/package/skills/session-title/ ディレクトリの削除
- [ ] inception.md, construction.md, operations.md のsession-title呼び出し箇所の更新
- [ ] common/ai-tools.md, guides/skill-usage-guide.md の参照更新
