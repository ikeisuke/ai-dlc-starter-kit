# サイクル v1.4.0 バックログ

このファイルはサイクル固有のバックログを管理します。

> 参照: [共通バックログ](../backlog.md) | [完了済み](../backlog-completed.md)

---

## このサイクルで発見した項目

サイクル中に気づいた改善点・技術的負債をここに記録します。

（例）
### [項目タイトル]
- **発見日**: YYYY-MM-DD
- **発見フェーズ**: [Inception / Construction / Operations]
- **概要**: [簡潔な説明]
- **詳細**: [詳細な説明]
- **対応案**: [推奨される対応方法]
- **優先度**: [高 / 中 / 低]

---

## 共通バックログから対応する項目

Inception Phase等で共通バックログ（`docs/cycles/backlog.md`）から選択した項目を転記します。

（例）
### [項目タイトル]
- **元の場所**: docs/cycles/backlog.md
- **転記日**: YYYY-MM-DD
- **対応予定**: [どのUnitで対応するか]

---

## Operations Phase完了時の処理

このファイルの項目は、Operations Phase完了時に以下のルールで処理されます：

| 出自 | 状態 | 移動先 |
|------|------|--------|
| このサイクルで発見 | 対応済み | backlog-completed.md |
| このサイクルで発見 | 未対応 | backlog.md（共通） |
| 共通から転記 | 対応済み | backlog-completed.md（共通から削除） |
| 共通から転記 | 未対応 | 共通に残す（転記を取り消し） |

### [2024-12-14] 気づき: コンテキスト増加時の自動リセット提案
- **関連**: 新規課題 / Unit 4（割り込み対応ルール）に関連する可能性
- **詳細**: Construction Phase でコンテキストが増えてきた場合、AIが自動的に状態を保存してリセット後の再開を提案する機能が欲しい。現在のコンテキストリセット対応は「ユーザーからの発言があった場合」のみだが、AI側から能動的に提案できると良い。
- **提案**: 
  - Construction Phase プロンプトに「コンテキスト量の目安」を追加
  - 一定の作業量（例: ステップ完了時、設計レビュー完了時など）でリセット提案を促すルールを追加
- **優先度**: 中

### [2025-12-14] 気づき: Setup Phase の新設
- **関連**: Unit 2（GitHub Issue確認とセットアップ統合）
- **詳細**: 現在 setup-cycle.md で行っている処理（ブランチ確認、サイクルディレクトリ作成、バージョン提案など）は、Inception Phase の前処理として位置づけが曖昧。Inception/Construction/Operations の3フェーズに加えて、Setup Phase を新設し、セットアップ処理を独立させるのが構造的に正しい。
- **提案**: 
  - Setup Phase を `prompts/package/prompts/setup.md` として新設
  - setup-cycle.md の内容を Setup Phase に移行
  - フロー: Setup → Inception → Construction → Operations
- **優先度**: 中（構造改善、今すぐ必要ではない）
