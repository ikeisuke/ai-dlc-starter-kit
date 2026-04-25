# Unit 003 実装計画: Construction Squash ステップの誤省略抑止

## 対象

- Unit 定義: `.aidlc/cycles/v2.4.1/story-artifacts/units/003-construction-squash-required-clarification.md`
- 対象 Issue: #594
- 主対象ファイル:
  - `skills/aidlc/steps/common/commit-flow.md`（「Squash統合フロー」L72-82 周辺）
  - `skills/aidlc/steps/construction/04-completion.md`（ステップ 7 見出し L92 周辺）

## スコープ

`squash_enabled=true` の環境で AI エージェントが Squash を誤って省略する事故（#594）を抑止する。具体的には:

1. `commit-flow.md` の「Squash統合フロー」冒頭に **前提チェックセクション** を追加し、`rules.git.squash_enabled` を取得して `true` 以外（`false` / 未設定 / 取得失敗を含む）なら **既存の `squash:skipped` シグナル** を返してフロー終了し、ログに `reason: squash_enabled=false (or unset)` を明示する。`true` のときのみ次のステップに進むロジックを明示する
2. `04-completion.md` ステップ 7 の見出しから **「【オプション】」ラベルを除去** し、「`squash_enabled=true` の場合は必須」と本文に明記

**シグナル設計の方針**: 既存の `squash:skipped` シグナル文字列をそのまま使い、新シグナル文字列（`squash:skipped:disabled` 等）は導入しない。これは既存呼び出し元（`04-completion.md` ステップ 7 の `squash:skipped → ステップ8へ`）の分岐記述が「完全一致」前提で書かれており、新シグナル文字列を導入すると AI エージェントの解釈で分岐に取りこぼしが発生するリスクを避けるため。理由情報はログメッセージで補足する。

## 実装方針

### Phase 1（設計）

本 Unit は手順書改訂のみで実コード変更を伴わないため、ドメインモデルと論理設計を**単一ファイル**にまとめて軽量化する（過剰な分割を避ける）。

設計内容:

- **状態モデル**: 「Squash統合フロー」の前提チェック → 実行 → シグナル戻り値の 3 段階を簡潔に表現
- **`commit-flow.md` への前提チェックセクション追加**: 位置（「## Squash統合フロー」直下）、本文構造（`scripts/read-config.sh rules.git.squash_enabled` の実行 + 結果に応じた分岐 + ログメッセージ仕様）
- **`scripts/read-config.sh` の exit code 仕様確認**: 実コード読み合わせで「`true` を返すケース」と「それ以外（`false` / 未設定 / 取得失敗 / ファイル未存在）」の exit code を明確化し、本 Unit では「`true` 以外はすべて `squash:skipped` 扱い」に丸める方針を確定する
- **シグナル文字列の戦略**: 既存の `squash:skipped` をそのまま使う（新文字列を導入しない、後方互換性のため）。理由は echo で stdout に出力（例: `echo "reason: squash_enabled=false (or unset)"`）
- **`04-completion.md` ステップ 7 の見出し改訂と本文補強の差分仕様**
- **既存の後続分岐（ステップ 7a / ステップ 8）への影響評価**: `squash:skipped` 文字列を変更しないため、既存分岐は全く改訂不要であることを明示

### Phase 2（実装）

#### `commit-flow.md` 改訂

「## Squash統合フロー」セクションの本文（現 L73-82）の冒頭に前提チェックブロックを挿入:

```markdown
### 前提チェック【必須】

`scripts/read-config.sh rules.git.squash_enabled` を実行し、結果に応じて分岐:

- `true` を返す（exit 0 + stdout が `true`）: 次のステップ（`/squash-unit` スキル使用）に進む
- 上記以外（`false` / 未設定 / 取得失敗 / ファイル未存在を含むすべての非 `true` ケース）: `squash:skipped` を出力 + 理由を `echo` でログ出力（例: `reason: squash_enabled=false (or unset)`）してフロー終了

**シグナル設計**: 既存の `squash:skipped` 文字列をそのまま使う（新シグナル文字列は導入しない）。呼び出し元（`04-completion.md` ステップ 7）の既存 `squash:skipped` 分岐がそのまま機能する。
```

#### `04-completion.md` 改訂

- ステップ 7 の見出し `### 7. Squash（コミット統合）【オプション】` → `### 7. Squash（コミット統合）`
- 見出し直下に「`rules.git.squash_enabled=true` の場合は本ステップを実施する（必須）。前提チェックは `commit-flow.md` の「Squash統合フロー」冒頭で実施」を 1〜2 行追記

### Phase 2b（検証）

- **検証ケース1**: `rules.git.squash_enabled=true` 環境（本リポジトリ）で `commit-flow.md` を AI エージェントが解釈したとき、前提チェック通過 → squash 実行のフローが選択されることを手順書読み合わせで確認
- **検証ケース2**: `rules.git.squash_enabled=false` 環境を仮想想定し、前提チェックで `squash:skipped` を返してフロー終了し、`04-completion.md` の `squash:skipped` 分岐に従ってステップ 8（通常コミット）に進むことを確認
- **検証ケース3**: `04-completion.md` ステップ 7 の見出しから「【オプション】」が除去され、本文で「必須」が明記されていることを `grep -n "オプション" skills/aidlc/steps/construction/04-completion.md` で確認（0 件であること）
- **検証ケース4（網羅性確認）**: リポジトリ全体で「Squash」+「【オプション】」を組み合わせた誤誘導記述が他の手順書ファイル（`steps/inception/05-completion.md` / `guides/` / `templates/` 等）に残っていないか `grep -rn "Squash.*【オプション】" skills/aidlc/` で確認（0 件であること）
- 既存の `squash:success` / `squash:error` 分岐は変更なしであることを再確認

### Phase 3（完了処理）

- 設計 / コード / 統合 AI レビュー承認（review-flow.md）
- Unit 定義ファイル状態を「完了」に更新
- 履歴記録（`/write-history` で `construction_unit03.md` 追記）
- Markdownlint 実行（`markdown_lint=true`）
- Squash 実行（`/squash-unit` Unit 003）
- Git コミット + force-with-lease push

## 完了条件チェックリスト

- [ ] `commit-flow.md` の「Squash統合フロー」冒頭に前提チェックセクションが追加されている
- [ ] 前提チェックは `scripts/read-config.sh rules.git.squash_enabled` を実行し、結果に応じて 2 分岐（`true` で次ステップへ進む / それ以外で `squash:skipped` を出力 + 理由ログ）する仕様になっている
- [ ] **新シグナル文字列を導入していない**（既存の `squash:skipped` をそのまま使う）。呼び出し元の既存分岐が改訂不要であることを確認済み
- [ ] `scripts/read-config.sh` の exit code 仕様を実コードで確認し、本 Unit の戦略（「`true` 以外はすべて `squash:skipped`」）と整合することを設計で明記
- [ ] `04-completion.md` ステップ 7 の見出しから「【オプション】」ラベルが除去されている
- [ ] `04-completion.md` ステップ 7 の本文に「`squash_enabled=true` の場合は必須」が明記されている
- [ ] 既存の `squash:success` / `squash:skipped` / `squash:error` シグナルの後続分岐は破壊されていない
- [ ] `/squash-unit` スキル本体（`skills/squash-unit/SKILL.md` および `scripts/squash-unit.sh`）には変更を加えていない（呼び出し側責任を維持）
- [ ] `skills/aidlc/` 配下全体で「Squash + 【オプション】」の組み合わせ表記が `04-completion.md` 改訂後に残っていないことを `grep -rn` で確認済み
- [ ] Markdownlint で 0 error
- [ ] 設計 AI レビュー承認
- [ ] コード AI レビュー承認
- [ ] 統合 AI レビュー承認
- [ ] Unit 定義ファイル状態を「完了」に更新
- [ ] 履歴記録（`construction_unit03.md`）
- [ ] Squash 実行（`squash_enabled=true`）
- [ ] Git コミット → force-with-lease push をユーザーに推奨提示（`04-completion.md` ステップ 7a に従い自動実行はしない）

## 依存関係

- 依存する Unit: なし（他 Unit と独立並列実装可能）
- 外部依存: 既存の `scripts/read-config.sh` / `/squash-unit` スキル（参照のみ、変更なし）

## 見積もり

- Phase 1（設計）: 0.1 日
- Phase 2（実装）: 0.1 日
- Phase 2b（検証）: 0.1 日
- Phase 3（完了処理）: 0.2 日

合計: 0.5 日規模（Unit 定義の見積もり 0.5 日と整合）

## リスク・留意点

- **Inception Phase への副次影響**: `commit-flow.md` は Inception / Construction / Operations 共通で参照される。本 Unit の前提チェック追加は Inception Phase 完了時の Squash にも適用されるが、これは意図した副次影響として Unit 定義の境界に明記済み（既に許容範囲）
- **既存 `squash:skipped` 分岐との互換性**: 既存呼び出し元（`04-completion.md` ステップ 7 の `squash:skipped → ステップ8へ`）の分岐記述は完全一致前提のため、新シグナル文字列を導入しない方針とする。`squash:skipped` をそのまま再利用し、診断情報はログメッセージで出力する
- **手順書誤省略の再発防止強度**: 「【オプション】」を除去するだけでなく、本文で「必須」を明示することで AI エージェントの解釈ミスを抑止する。前提チェックの追加と組み合わせて二重防御
- **`squash-unit` スキル本体の不変性**: 呼び出し側で分岐責任を持つ既存設計を維持するため、スキル本体には触れない（DR-006 のパッチスコープ実装本体不変方針と整合）
- **Unit 定義との文言整合**: Unit 定義（責務 L13）は「`false` または未設定時」と記載しているが、本計画では「`false` / 未設定 / 取得失敗 / ファイル未存在」の 4 ケースをすべて「`true` 以外」として `squash:skipped` に丸める方針。Unit 境界の責務逸脱とはみなさず、Unit 定義側を「未設定または取得失敗を含む」と読み替える解釈で進める（設計レビューで確認）
