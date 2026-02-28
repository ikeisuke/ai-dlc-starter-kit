# Unit 005 計画: squash retroactiveモード改善

## 概要

squash-unit.shのretroactiveモードにおけるコミットフォーマット依存リスクを軽減する。gitトレーラー方式（Unit境界の信頼性向上）とハッシュ直接指定方式（最終手段としてのフォーマット非依存な境界指定）を組み合わせて採用する。

## 設計決定

### 比較検討結果

4つの対策候補を比較し、案1+案2の組み合わせを採用。

| 観点 | 1. gitトレーラー | 2. ハッシュ直接指定 | 3. ドライラン必須化 | 4. git notes |
|---|---|---|---|---|
| 信頼性 | 高 | 最高 | 低 | 中 |
| 実装コスト | 低 | 低 | 低 | 中 |
| 根本解決度 | 中 | 高 | 低 | 中 |

**採用理由**:
- gitトレーラー: 日常フローで自動的に信頼性向上。パターンマッチの二重化で表記ゆれ耐性を強化
- ハッシュ直接指定: トレーラーもパターンマッチも失敗した場合の最終手段。テキスト完全非依存
- ドライラン必須化: 案1/2で不要（検出のみで根本解決にならない）
- git notes: rebase時のnotes消失リスクがretroactiveモードとの相性悪

### 不採用の案

- **案3 ドライラン必須化**: 問題の事前検出のみで根本解決にならない
- **案4 git notes**: `git rebase` 実行時に notes が失われるリスクがあり、retroactive モードの核心機能と矛盾する

## 変更対象ファイル

1. `prompts/package/bin/squash-unit.sh` - トレーラー検索ロジック追加、`--from`/`--to`オプション追加、エラーメッセージ改善
2. `prompts/package/prompts/common/commit-flow.md` - Unit-Numberトレーラーの記載、`--from`/`--to`の使用方法、リカバリ手順

## 実装計画

### 変更1: commit-flow.mdにUnit-Numberトレーラー追加

コミットメッセージフォーマットに `Unit-Number: {NNN}` トレーラーを追加する。

**対象テンプレート**（Unit完了系のみ。レビュー前/反映には付与しない）:
- `UNIT_COMPLETE`: `feat: [{{CYCLE}}] Unit {NNN}完了 - {DESCRIPTION}`
- `UNIT_SQUASH_PREP`: `chore: [{{CYCLE}}] Unit {NNN}完了 - 完了準備`

**非対象**: `REVIEW_PRE` / `REVIEW_POST` / `INCEPTION_COMPLETE` / `OPERATIONS_COMPLETE` にはトレーラーを付与しない（境界検出のノイズ防止）。

**トレーラー形式**:
```text
feat: [v1.17.1] Unit 005完了 - squash retroactiveモード改善

Unit-Number: 005
Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
```

### 変更2: squash-unit.shにトレーラー検索ロジック追加

`find_unit_commit_range_git()` にトレーラーベースの境界検出を追加する。

**検索戦略チェーン**（1回のログ走査でsubject+trailersを同時取得）:
1. `--from`/`--to` 指定時: 指定範囲をそのまま使用（トレーラー・パターンマッチをスキップ）
2. `Unit-Number: {NNN}` トレーラーによる境界検出（新規）
3. コミットメッセージのパターンマッチ（既存、フォールバック）

**実装方針**:
- `git log --format="%h %H %s%x00%(trailers:key=Unit-Number,valueonly)"` で件名+トレーラーをNUL区切りで同時取得
- 1回の走査で両方の判定を実行し、トレーラー優先で境界を確定
- トレーラーが見つからない場合は既存のパターンマッチにフォールバック
- フォールバック発生時は警告メッセージを出力: `Warning: Unit-Number trailer not found, falling back to commit message pattern matching`
- **部分的トレーラー不整合**（一部コミットのみトレーラーあり）: 警告を出力し、トレーラー付きコミットのみで判定を試行。判定不能ならパターンマッチにフォールバック

### 変更3: `--from`/`--to`オプション追加

retroactiveモードにハッシュ直接指定オプションを追加する。

**新規オプション**:
- `--from <COMMIT>`: Unit開始コミットのハッシュ（このコミットを含む）
- `--to <COMMIT>`: Unit終了コミットのハッシュ（このコミットを含む）

**動作**:
- `--from`/`--to` が指定された場合、トレーラー検索・パターンマッチをスキップし、指定範囲をそのまま使用
- `--from`/`--to` は両方同時に指定する必要がある（片方のみはエラー）
- `--from`/`--to` と `--base` は**排他**（同時指定はバリデーションエラー）
- `--from`/`--to` 指定時の入力バリデーション: `validate_base_format()` と同じ（英数字・ハイフン・アンダースコアのみ）
- 受け取り後に `git rev-parse` でフルハッシュへ正規化して内部保持
- `--from` が `--to` の祖先であること（またはイコール）を検証

**`--base` との責務の違い**:
- `--base`: 探索範囲の起点（除外境界）。`--base` 以降のコミットからUnit境界を自動検出する
- `--from`/`--to`: 実行範囲の直接指定（包含境界）。自動検出をバイパスする

**ヘルプ更新**:
```text
  --from <COMMIT>       retroactive時のUnit開始コミット（--to と同時指定必須、--baseと排他）
  --to <COMMIT>         retroactive時のUnit終了コミット（--from と同時指定必須、--baseと排他）
```

### 変更4: エラーメッセージ改善

境界検出失敗時のエラーメッセージを具体的にする。

**現在**: `Error: commits for Unit ${unit} not found in cycle ${cycle}`

**改善後**:
```text
Error: commits for Unit ${unit} not found in cycle ${cycle}
Hint: Ensure commit messages follow the pattern 'feat: [${cycle}] Unit ${unit}完了 - ...'
Hint: Or add 'Unit-Number: ${unit}' trailer to commit messages
Hint: Or use --from/--to to specify the commit range explicitly
```

### 変更5: commit-flow.mdにリカバリ手順追加

retroactiveモードで境界検出に失敗した場合のリカバリ手順を追加する。

**追加内容**:
- `--from`/`--to` による手動境界指定の使い方
- `git log --oneline` で対象コミットを特定する方法
- 「dry-run直後に同一履歴で実行」「rebase後はハッシュが変わるため再取得必須」の注意事項

## 設計方針

1. **後方互換**: 既存のパターンマッチ方式は維持。トレーラーは追加の信頼性レイヤー
2. **戦略チェーン**: `--from`/`--to` > トレーラー検索 > パターンマッチの判定優先順位
3. **排他制約**: `--from`/`--to` と `--base` はretroactiveモードで排他（責務が異なるため同時指定不可）
4. **フルハッシュ正規化**: `--from`/`--to` は受け取り後にフルハッシュへ正規化して内部保持
5. **セキュリティ**: `--from`/`--to` は `validate_base_format()` で検証（revset演算子混入防止）
6. **既存テスト影響なし**: 新オプション追加のみ、既存動作は変更しない

## 完了条件チェックリスト

- [x] commit-flow.mdにUnit-Numberトレーラーを追記（UNIT_COMPLETE/UNIT_SQUASH_PREPのみ）
- [x] squash-unit.shにトレーラー検索ロジック追加（統合走査、フォールバック付き）
- [x] squash-unit.shに`--from`/`--to`オプション追加（バリデーション、`--base`排他、フルハッシュ正規化）
- [x] ヘルプメッセージ更新
- [x] エラーメッセージ改善（ヒント付き）
- [x] commit-flow.mdにリカバリ手順追加（`--from`/`--to`使い方、注意事項）
- [x] ドライラン（`--dry-run --retroactive`）での動作確認（既存テスト影響なし確認済み）
