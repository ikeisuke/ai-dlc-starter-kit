# Unit 002 計画書: daselによるTOML読み込み対応

## 概要

プロンプトファイル群でのTOML設定値の読み込みにdaselを活用し、コードの可読性と堅牢性を向上させる。

## 関連ユーザーストーリー

- ストーリー7: daselによるTOML読み込み改善（#33）

## 対象ファイル

1. `prompts/setup-prompt.md`
2. `prompts/package/prompts/setup.md`
3. `prompts/package/prompts/inception.md`（確認済み: dasel対応済み）
4. `prompts/package/prompts/construction.md`（確認済み: dasel対応済み）
5. `prompts/package/prompts/operations.md`

## 調査結果サマリ

### dasel対応が必要な箇所（4箇所）

| ファイル | 行番号 | 対象フィールド | 現在の手法 |
|----------|--------|----------------|------------|
| setup-prompt.md | 56 | starter_kit_version | grep + sed |
| setup.md | 122 | project.name | awk + gsub |
| setup.md | 233 | starter_kit_version | grep + sed |
| operations.md | 1057 | paths.setup_prompt | grep + sed |

### dasel対応済み箇所（参考: 7箇所）

- `.backlog.mode` 取得: 6箇所（inception.md, construction.md, operations.md）
- `.project.type` 取得: 2箇所（inception.md, operations.md）

### dasel活用のメリット

- 可読性向上（`.starter_kit_version` のようなJSONパス表記）
- メンテナンス性向上（正規表現・sed置換式が不要）
- 構造的アクセス（TOML階層を直接指定）
- 既存パターンとの一貫性（既に7箇所で採用済み）

## フォールバック戦略

### dasel利用可否判定

```bash
if command -v dasel >/dev/null 2>&1; then
    # dasel使用
else
    # フォールバック処理
fi
```

### フォールバック条件

1. **dasel未インストール**: `command -v dasel` が失敗
2. **ファイル不在**: 対象ファイル（docs/aidlc.toml）が存在しない
3. **キー欠損**: dasel実行成功だが空値（exit 0, 出力なし）
4. **TOML構文エラー**: dasel実行失敗（exit != 0, stderr出力）

### フォールバック手段

| 条件 | 対応 | 判定方法 |
|------|------|----------|
| dasel未インストール | 既存grep/sed/awk処理を使用 | `command -v dasel` |
| ファイル不在 | 新規セットアップフローへ（既存動作維持） | `[ -f docs/aidlc.toml ]` |
| キー欠損 | デフォルト値を使用 | 出力が空文字列 |
| TOML構文エラー | エラーメッセージ表示・処理中断 | exit code != 0 && stderr出力あり |

**設計フェーズで詳細化する事項**:
- 各箇所のデフォルト値の明示
- エラー判定の具体的な分岐ロジック

### daselバージョン前提

- **対象**: dasel v2系（v2.0.0以降）
- **コマンド形式**: `dasel -f <file> -r toml '<path>'`
- **エラー時**: exit code 1, stderr出力

### 旧形式（project.toml）への対応方針

- **読み込み対象**: 常に `docs/aidlc.toml` のみ
- **理由**: 旧形式 `docs/aidlc/project.toml` は setup-prompt.md の移行処理で `docs/aidlc.toml` に変換される（行162-165）
- **本Unitでの対応**: dasel読み込み処理は `docs/aidlc.toml` のみを対象とし、旧形式の直接読み込みは行わない
- **互換性**: 移行処理は既存のまま維持（本Unitの対象外）

**前提条件**:
- `setup.md` / `operations.md` は `setup-prompt.md` 実行後（移行完了後）に使用される想定
- `docs/aidlc.toml` 不在時は「ファイル不在」フォールバック（上記）で対応

## 実装計画

### Phase 1: 設計

#### ステップ1: ドメインモデル設計

**成果物**: `docs/cycles/v1.7.3/design-artifacts/domain-models/002_dasel_toml_domain_model.md`

このUnitは「プロンプトファイルの修正」であり、ビジネスドメインは存在しない。
代わりに以下の概念を整理:

- **設定読み込みパターン**: dasel優先 + grep/sedフォールバック
- **フォールバック戦略**: dasel未インストール時の代替処理

#### ステップ2: 論理設計

**成果物**: `docs/cycles/v1.7.3/design-artifacts/logical-designs/002_dasel_toml_logical_design.md`

設計内容:
1. dasel利用可否判定のフロー
2. 各設定値取得の具体的コマンド設計
3. フォールバック処理の設計

#### ステップ3: 設計レビュー

設計内容をユーザーに提示し、承認を得る。

### Phase 2: 実装

#### ステップ4: コード生成

**対象ファイル**:
1. `prompts/setup-prompt.md` - バージョン取得をdasel対応化
2. `prompts/package/prompts/setup.md` - プロジェクト名取得、バージョン取得をdasel対応化
3. `prompts/package/prompts/operations.md` - setup_promptパス取得をdasel対応化

#### ステップ5: テスト生成

手動テスト:
- daselインストール環境での動作確認
- dasel未インストール環境でのフォールバック動作確認
- キー欠損時のデフォルト値確認
- 不正TOML時のエラーハンドリング確認

#### ステップ6: 統合とレビュー

- markdownlint実行
- 最終レビュー

## 完了条件

- [ ] `prompts/setup-prompt.md` でdasel活用パターンが適用されている
- [ ] `prompts/package/prompts/setup.md` でdasel活用パターンが適用されている
- [ ] `prompts/package/prompts/operations.md` でdasel活用パターンが適用されている
- [ ] dasel未インストール時のフォールバック処理が実装されている
- [ ] markdownlintエラーがない
- [ ] レビュー承認済み

## 見積もり

小規模（プロンプトファイルの修正のみ、4箇所）

## リスク

| リスク | 影響度 | 対策 |
|--------|--------|------|
| daselコマンド構文エラー | 低 | テストで検出 |
| フォールバック処理の漏れ | 低 | 既存パターンを踏襲 |
| daselバージョン差異 | 低 | v2系前提を明記、基本コマンドのみ使用 |
