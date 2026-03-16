# Unit 004 計画: AI-DLCフェーズ手順の明文化

## 概要

CLAUDE.md にフェーズ簡略指示セクションを追加し、AGENTS.mdを辿らなくても基本的なフェーズ開始手順が分かるようにする。

## 変更対象ファイル

- `prompts/package/prompts/CLAUDE.md` — フェーズ簡略指示セクションを追加

## 実装計画

1. `prompts/package/prompts/CLAUDE.md` の `## Compact Instructions` セクションの直前に `## フェーズ簡略指示` セクションを追加
2. AGENTS.md（`prompts/package/prompts/AGENTS.md`）の既存フェーズ簡略指示表（通常版・Lite版）を記載
3. AGENTS.mdをSSOT（Single Source of Truth）とし、CLAUDE.mdは利便性のための参照コピーである旨を明記。更新時はAGENTS.md側を先に更新し、CLAUDE.mdに反映する運用とする

## 完了条件チェックリスト

- [ ] prompts/package/prompts/CLAUDE.md にフェーズ簡略指示セクションが追加されている
- [ ] 簡略指示表（インセプション、コンストラクション、オペレーション）が記載されている
- [ ] AGENTS.mdとの重複を最小限に抑えた参照構造になっている
- [ ] AGENTS.mdの内容は変更されていない
