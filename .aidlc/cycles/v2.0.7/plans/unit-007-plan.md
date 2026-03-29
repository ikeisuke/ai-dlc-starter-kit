# Unit 007 計画: バージョン検証一元化

## 概要

`bin/update-version.sh` 内の `starter_kit_version` 読み取りロジックを `version.sh` の既存関数 `read_starter_kit_version()` に統合し、バージョン検証ロジックの重複を解消する。

## 現状の問題（Issue #452）

1. `update-version.sh` (L92-98) が `version.sh` の `read_starter_kit_version()` を使わず独自のsedで `starter_kit_version` を読み取り + match_count検証している
2. `update-version.sh` のsedパターンと `version.sh` の `read_starter_kit_version()` のsedパターンが実質同一だが、重複管理のリスクがある

## スキル境界の考慮【重要】

Unit 001（スキル分離）の設計で確立された不変条件:
- **独立スキルから親スキル配下のスクリプトへの参照がない**
- `aidlc-setup` は「内部依存なし（親スキルへの依存ゼロ）」

したがって `aidlc-setup/scripts/read-version.sh` は変更対象外とする。このスクリプトは `version.txt` の読み取りという異なる責務を持ち、スキル境界を尊重して自己完結を維持する。

## 変更対象ファイル

| ファイル | 変更内容 |
|---------|---------|
| `skills/aidlc/scripts/lib/version.sh` | `read_starter_kit_version()` に match_count検証を追加（重複排除） |
| `bin/update-version.sh` | `read_starter_kit_version()` を使用するようリファクタリング |
| `.aidlc/cycles/v2.0.7/story-artifacts/units/007-version-validation.md` | 責務を実在ファイルベースに更新 |

## 変更対象外

| ファイル | 理由 |
|---------|------|
| `skills/aidlc-setup/scripts/read-version.sh` | スキル境界制約（独立スキルは親スキルに依存しない）。version.txt読み取りという異なる責務 |

## 実装計画

### Phase 1: 設計

1. ドメインモデル設計: `version.sh` の関数責務明確化
2. 論理設計: `read_starter_kit_version()` のAPI契約明文化

### Phase 2: 実装

1. `version.sh` の `read_starter_kit_version()` を拡張:
   - match_count検証を関数内に統合（`update-version.sh` L96-98の重複排除）
   - API契約: 引数=$1(config_path)、stdout=バージョン文字列、終了コード 0:成功 / 1:キー不在・フォーマット不正 / 2:ファイル読取エラー
2. `update-version.sh` のstarter_kit_version読み取り部分を `read_starter_kit_version()` 呼び出しに置換
3. `update-version.sh` のエラーハンドリングを調整（`read_starter_kit_version()` の終了コードに基づくエラーメッセージ出力）
4. 動作確認: 正常系・異常系テスト

## Unit定義との差異

Unit定義の責務に記載の `aidlc-setup.sh` と `check-version.sh` は現在のコードベースに存在しない（Unit 001のスキル分離でリファクタリング済み）。実在するファイルに基づいて計画を策定した。Unit定義ファイルの責務も併せて更新する。

## 完了条件チェックリスト

- [ ] `version.sh` の `read_starter_kit_version()` にmatch_count検証を統合
- [ ] `update-version.sh` から `read_starter_kit_version()` の呼び出し
- [ ] Unit定義の責務を実在ファイルベースに更新
- [ ] 既存動作（正常系・異常系）の維持
