# Intent（開発意図）

## プロジェクト名

AI-DLC スターターキット v1.11.0

## 開発の目的

AI-DLCの開発体験を向上させるため、以下の改善を実施する：

1. **プロンプトの効率化**（対象: `prompts/package/prompts/operations.md`, `prompts/package/prompts/common/`）
   - Operations Phaseのステップ0で変更有無を一括確認し、確認なしで進行可能に（#98）
   - 各フェーズ・Unitでタスク管理機能の活用を追加（#129）※ツール非依存の抽象的指示
   - AIレビュー完了条件を明示化し、再レビュー漏れを防止（#137）
2. **セキュリティガイドの整備**（対象: `prompts/package/guides/`）
   - サンドボックス環境での実行ガイド作成（#26）
   - AIエージェント向け許可リストガイド作成（#29）
3. **設定管理の改善**（対象: `prompts/package/templates/`, `prompts/setup-prompt.md`）
   - aidlc.tomlのテンプレート化（新規セットアップ時）
   - 既存プロジェクト向けマイグレーションスクリプト維持（#90）
4. **ドキュメントの完全性向上**（対象: `README.md`）
   - 不足バージョン情報の追加: v1.0.1, v1.1.0, v1.7.x, v1.9.x, v1.10.0（#136）

## ターゲットユーザー

- AI-DLCスターターキットを使用する開発者
- AIエージェント（Claude Code、Cursor、Cline等）を活用した開発を行うチーム

## ビジネス価値

- **開発効率向上**: Operations Phaseの確認削減により繰り返しサイクルの高速化
- **品質向上**: AIレビュー完了条件の明示化により、レビュー漏れを防止
- **セキュリティ向上**: サンドボックス・許可リストガイドにより安全なAI活用を促進
- **保守性向上**: aidlc.tomlテンプレート化により設定管理を簡素化

## 成功基準

**完了条件**（以下すべてを満たすこと）:

### 1. 挙動確認（判定者: 開発者、判定方法: プロンプト実行による手動確認）

| Issue | 対象ファイル | 確認条件 |
|-------|------------|---------|
| #98 | `prompts/package/prompts/operations.md` | ステップ0で「変更したい項目はありますか？」→「いいえ」選択時に、ステップ1-5の確認をスキップして自動進行する |
| #129 | `prompts/package/prompts/inception.md`, `prompts/package/prompts/construction.md`, `prompts/package/prompts/operations.md` | 全フェーズの各ステップ/Unit開始時に「タスク管理機能を活用」の指示が追加される（ツール非依存） |
| #137 | `prompts/package/prompts/common/review-flow.md` | AIレビューで指摘0件の場合のみ「【AIレビュー完了】指摘0件」メッセージが再レビュー分岐の前に出力される |

### 2. ファイル生成確認（判定方法: ファイル存在・参照確認）

| Issue | 生成ファイル | 参照元 |
|-------|------------|--------|
| #26 | `prompts/package/guides/sandbox-environment.md` | - |
| #29 | `prompts/package/guides/ai-agent-allowlist.md` | - |
| #90 | `prompts/package/templates/aidlc.toml.template` | `prompts/setup-prompt.md` |
| #136 | `README.md` （v1.0.1, v1.1.0, v1.7.x, v1.9.x, v1.10.0 セクション追加） | - |

### 3. リグレッション確認（影響ファイル・フロー別）

| 対象ファイル | 確認フロー |
|------------|-----------|
| `prompts/package/prompts/operations.md` | #98: 「変更あり」選択時は従来通りステップ1-5で各ステップの確認が入る |
| `prompts/package/prompts/inception.md`, `prompts/package/prompts/construction.md`, `prompts/package/prompts/operations.md` | #129: 既存のタスク管理関連ルールが維持される |
| `prompts/package/prompts/common/review-flow.md` | #137: 指摘がある場合は従来通り「修正→再レビュー」のフローが動作する。指摘0件時は再レビュー分岐に進まない |
| `prompts/setup-prompt.md` | #90: 既存プロジェクトのアップグレード時にマイグレーションが正常動作する |

## 完了後の運用タスク

- 7件のIssue（#26, #29, #90, #98, #129, #136, #137）をクローズ

## 期限とマイルストーン

- **マイルストーン**: v1.11.0リリース
- **期限**: 特になし（品質優先）

## 制約事項

- `docs/aidlc/` は直接編集禁止（`prompts/package/` を編集し、rsyncで反映）
  - 運用手順: `docs/cycles/rules.md` 「メタ開発の意識」セクション参照
- 既存のaidlc.toml設定との後方互換性を維持
  - 新規設定項目追加時は `prompts/setup-prompt.md` のマイグレーションセクションで対応
- メタ開発の意識を保持（スターターキット自体の開発）

## スコープ外（今回対応しないもの）

- 他のオープンIssue（#31, #99, #104, #116 等）
- Inception Phase、Construction Phaseのプロンプト構造変更（#98, #129, #137 以外）
- 既存ガイドの改修（`prompts/package/guides/` の既存ファイル）
- setup-prompt.md の大規模リファクタリング（#90 のテンプレート追加のみ対応）

## 対象Issue

| グループ | Issue | タイトル |
|---------|-------|---------|
| A. プロンプト改善 | #98 | Operations Phase: ステップ0で変更有無を確認 |
| A. プロンプト改善 | #129 | フェーズ・Unitタスク管理にAIツールのToDo機能活用 |
| A. プロンプト改善 | #137 | AIレビュー完了条件の明示化 |
| B. ガイド作成 | #26 | サンドボックス環境での実行ガイド作成 |
| B. ガイド作成 | #29 | AIエージェント向け許可リスト推奨機能 |
| C. 設定改善 | #90 | aidlc.tomlのテンプレート作成・反映方式の検討 |
| D. ドキュメント | #136 | README.mdに不足しているバージョンセクションを追加 |

## 不明点と質問（Inception Phase中に記録）

[Question] グループ分けと優先順位（A→B→C→D）でよいか
[Answer] はい、この順番で進める

[Question] #90（aidlc.tomlテンプレート）の対応方式
[Answer] テンプレートからの生成方式 + マイグレーションのハイブリッド（新規はテンプレート生成、既存はマイグレーション）

[Question] #26と#29の関係性
[Answer] 別々のUnitで対応
