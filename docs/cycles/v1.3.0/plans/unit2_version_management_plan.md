# Unit 2: バージョン管理改善 実装計画

## 対象ユーザーストーリー

- **US-2**: Operations Phaseのバージョン更新修正（Must-have）
- **US-3**: 初回セットアップ時のバージョン提案改善（Could-have）

## 現状の課題

1. **version.txt と aidlc.toml の不整合**: Operations Phase でバージョンを更新しても、aidlc.toml の starter_kit_version が更新されない可能性がある
2. **アップグレード検出の問題**: バージョン情報が分散しているため、次サイクルで正しく認識されない
3. **初回セットアップ時のバージョン提案**: 既存プロジェクトのバージョン情報を考慮していない

## 実装方針

### Phase 1: 設計（ドキュメント分析と方針決定）

#### ステップ 1: 現状調査
- `prompts/operations.md` のバージョン更新手順を確認
- `prompts/setup-prompt.md` のバージョン関連処理を確認
- `aidlc.toml` と `version.txt` の関係性を整理

#### ステップ 2: ドメインモデル設計
- バージョン管理に関するドメインモデルを設計
- 各バージョン情報源の役割と更新タイミングを定義

#### ステップ 3: 論理設計
- バージョン更新フローの設計
- 初回セットアップ時のバージョン調査フローの設計

### Phase 2: 実装

#### ステップ 4: Operations Phase の修正
- `prompts/operations.md` にバージョン更新手順を追加/修正
- version.txt と aidlc.toml の同時更新手順を明記

#### ステップ 5: セットアッププロンプトの修正
- `prompts/setup-prompt.md` に既存バージョン調査ステップを追加
- package.json、pyproject.toml 等の調査手順を追加

#### ステップ 6: テストと検証
- 修正内容のレビュー
- 実装記録の作成

## 成果物

1. `docs/cycles/v1.3.0/design-artifacts/domain-models/unit2_version_management_domain_model.md`
2. `docs/cycles/v1.3.0/design-artifacts/logical-designs/unit2_version_management_logical_design.md`
3. `prompts/operations.md`（修正）
4. `prompts/setup-prompt.md`（修正）
5. `docs/cycles/v1.3.0/construction/units/unit2_version_management_implementation.md`

## 受け入れ基準（チェックリスト）

### US-2
- [ ] version.txt更新時にaidlc.tomlも同時に更新される手順が明確である
- [ ] アップグレード検出ロジックが正しく動作する
- [ ] バージョン更新手順がドキュメント化されている

### US-3
- [ ] package.json、pyproject.toml等のバージョン情報を調査する手順が追加されている
- [ ] 既存バージョンがある場合、それを考慮した提案がされる
