# Unit 002 計画: レビュースキルのタイミングベース化 + レビューフロー修正

## 概要

種別ベースのレビュースキル4つを、タイミングベースの9スキルに再構成する。併せて review-flow.md のレビュー完了条件をレビュワー承認ベースに修正する。

## 設計方針

### stage/focus 分離モデル

スキル名はタイミング（stage）ベースだが、レビュー結果にはfocusメタデータを保持する。

- **stage**: 実行タイミング（例: `construction-code`, `operations-premerge`）→ スキル名に反映
- **focus**: レビュー観点（例: `code`, `security`, `architecture`）→ レビュー結果のメタデータに保持

review-flow.md の分岐（特にsecurity指摘の非公開扱い、バックログ種別決定）はfocusメタデータを参照する。スキル名では判定しない。

### レビュー完了条件の承認モデル

- **承認者**: 外部レビューツール（codex/claude/gemini）またはセルフレビュー
- **承認の入力イベント**: レビュワーが「承認（指摘なし）」を返す、またはユーザーが明示的に承認
- **保存する状態**: `approved` / `changes_requested` をレビュー結果シグナルに追加
- **複数レビュー結果の集約**: 全レビュー種別で `approved` → 全体承認。1つでも `changes_requested` → 再レビュー必要
- **未承認時の遷移**: 修正→再レビュー（最大3回）→指摘対応判断フロー（既存フロー維持）

## 変更対象ファイル

### 削除対象

- `skills/reviewing-code/` (ディレクトリ全体)
- `skills/reviewing-architecture/` (ディレクトリ全体)
- `skills/reviewing-security/` (ディレクトリ全体)
- `skills/reviewing-inception/` (ディレクトリ全体)

### 新規作成

| スキル | focusメタデータ | 主な観点 |
|--------|---------------|---------|
| `reviewing-inception-intent` | inception | Intent品質（旧reviewing-inceptionのIntent部分） |
| `reviewing-inception-stories` | inception | ストーリー品質（旧reviewing-inceptionのストーリー部分） |
| `reviewing-inception-units` | inception | Unit定義品質（旧reviewing-inceptionのUnit部分） |
| `reviewing-construction-plan` | architecture | 計画・アーキテクチャ（旧reviewing-architecture） |
| `reviewing-construction-design` | architecture | 設計品質（旧reviewing-architecture） |
| `reviewing-construction-code` | code, security | コード品質+セキュリティ（旧code + security統合） |
| `reviewing-construction-integration` | code | 設計乖離確認、レビュー/テスト実施状況 |
| `reviewing-operations-deploy` | architecture | デプロイ計画の妥当性 |
| `reviewing-operations-premerge` | code, security | PR全体の品質確認 |

### 更新対象（実行時必須）

- `.claude-plugin/marketplace.json` — 旧スキル削除、新スキル追加
- `skills/aidlc/steps/common/review-flow.md` — CallerContext更新、承認モデル追加、focus参照に変更
- `skills/aidlc/config/settings-template.json` — Skill許可ルール更新

### 更新対象（配布物・説明資料）

- `.aidlc/rules.md` — スキル呼び出し記述更新
- `skills/aidlc/steps/common/ai-tools.md` — スキルカタログ更新
- `skills/aidlc/guides/skill-usage-guide.md` — スキル名一覧・呼び出し例更新
- `skills/aidlc/guides/ai-agent-allowlist.md` — 許可リスト更新
- `skills/aidlc/guides/phase-review-perspectives.md` — レビュー観点ガイド更新

### 更新対象（テスト）

- `skills/aidlc/scripts/tests/test_wildcard_detection.sh` — テスト内のスキル名参照更新

## 実装計画

### Phase 1: 旧スキル廃止 + 新スキル作成

1. 旧スキル4ディレクトリを削除
2. 新スキル9つのSKILL.mdを作成。各スキルにfocusメタデータを記載
3. 各SKILL.mdに共通セクション（実行コマンド、セッション継続、セルフレビューモード）を維持
4. security観点を持つスキル（construction-code, operations-premerge）では、指摘にfocus=securityタグを付与するよう指示

### Phase 2: 参照更新（全ファイル）

1. `marketplace.json` 更新
2. `review-flow.md` のCallerContext・承認モデル・focus参照更新
3. `settings-template.json` のSkill許可ルール更新
4. `.aidlc/rules.md` のスキル呼び出し記述更新
5. `ai-tools.md` のスキルカタログ更新
6. `skill-usage-guide.md` のスキル名一覧更新
7. `ai-agent-allowlist.md` の許可リスト更新
8. `phase-review-perspectives.md` のレビュー観点ガイド更新
9. `test_wildcard_detection.sh` のテスト内スキル名更新

### Phase 3: 検証

1. 旧スキル名参照がゼロであることを grep で確認（`scripts/tests/` 除外不要 — テストも更新済み）
2. 新スキル名が marketplace.json に全て登録されていることを確認
3. focus=security 指摘の非公開扱いロジックがスキル名に依存していないことを確認

## 完了条件チェックリスト

- [ ] 旧スキル4つのディレクトリ削除
- [ ] 新スキル9つの SKILL.md 作成（タイミング固有レビュー観点+focusメタデータ記載）
- [ ] marketplace.json 更新（旧スキル名参照ゼロ、新スキル名全登録）
- [ ] review-flow.md CallerContext マッピング更新
- [ ] review-flow.md 承認モデル追加（approved/changes_requested）
- [ ] review-flow.md security分岐をfocusメタデータ参照に変更
- [ ] .aidlc/rules.md スキル呼び出し更新
- [ ] settings-template.json 許可ルール更新
- [ ] guides（skill-usage-guide, ai-agent-allowlist, phase-review-perspectives）更新
- [ ] テスト内のスキル名参照更新
- [ ] reviewing-construction-code が security 観点を統合（focus=security タグ付与）
- [ ] reviewing-construction-integration が設計乖離確認に観点変更
