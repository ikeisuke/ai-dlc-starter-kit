# Unit: pr-ready --body-file 空ファイル検証で PR 本文 null 上書き事故防止

## 概要

`skills/aidlc/scripts/operations-release.sh` の `pr-ready --body-file <path>` および内部 `gh pr edit --body-file` / REST PATCH fallback 経路に、0 バイトファイル / 不在ファイルを実行前検証する処理を追加し、AI エージェント運用時の「mktemp 経由 0 バイトファイル誤渡しによる PR 本文 null 上書き事故」を構造的に予防する。Issue #678 案 A + 案 B を本サイクル必須として実装する。

## 含まれるユーザーストーリー

- ストーリー 2: pr-ready --body-file の空ファイル検証で PR 本文 null 上書き事故を防止

## 責務

- `pr-ready --body-file <path>` の入力検証（0 バイト / 不在）
- REST PATCH fallback 経路（`pr-ready:fallback:rest-patch`）でも同等検証を再実施（二重防御）
- 検証エラー時の機械可読エラーメッセージ出力（tab 区切り `error\t<error_code>\t<context>`）
- bats テスト追加（0 バイト / 不在 / 通常 / fallback 経路）

## 境界

- 「極端に短い本文（warning）」は本 Unit の対象外（Issue #678 案 A の warning ライン）。Intent / user_stories で明示済
- 案 C「テンプレ生成 helper（build-pr-body 等）追加」は本 Unit 対象外（別 Issue で defer）
- `pr-ready` 以外の他サブコマンドの検証強化は本 Unit 対象外

## 依存関係

### 依存する Unit

- なし

### 外部依存

- `gh` CLI（`gh pr edit --body-file` / REST PATCH 経路）
- bash（既存 operations-release.sh の動作環境）
- bats / shellcheck / shellharden（既存テスト環境）

## 非機能要件（NFR）

- **パフォーマンス**: 検証処理によるオーバーヘッドは 100ms 未満
- **セキュリティ**: 検証エラー時に `<path>` をそのまま stderr に出力する際、機密情報のリークを引き起こさない（`<path>` はパス情報のみ、ファイル内容は出力しない）
- **可搬性**: macOS / Linux 双方の bash で動作（`stat` / `wc -c` 等のコマンド可搬性に注意）

## 技術的考慮事項

- `<path>` のサイズ判定は `wc -c` または `stat -c %s` のいずれかで実装する。可搬性を考慮し POSIX wc を優先候補とする
- REST PATCH fallback 経路で `gh api -X PATCH ... -F body=@<path>` の `<path>` を使用する箇所を特定し、本 Unit の検証ヘルパーに通す
- 機械可読エラーメッセージは tab 区切り 3 フィールド（`error\t<error_code>\t<context>`）。AI エージェントが parse して再試行できる形式

## Intent 制約適合

- **破壊的変更なし**: 本文ありの正常な `--body-file` 経路は従来通り動作。空ファイル / 不在ファイルの拒否は本来エラー検出すべき経路の品質改善であり、CHANGELOG で破壊変更ではなく改善として案内
- **ドッグフーディング特殊処理禁止**: 検証ロジックは consumer プロジェクトでも同一動作。自リポジトリ判定による分岐は導入しない
- **コマンド置換禁止**: 検証実装で `$(...)` 形式のコマンド置換を新規導入しない（既存 operations-release.sh の規約踏襲）

## 関連Issue

- #678（致命的バグ / mirror 由来 feedback）

## 実装優先度

High（致命的バグ）

## 見積もり

0.5〜1 日。検証ロジックは小規模（pr-ready / fallback 2 箇所）、bats テストの fixture 整備が大半。

---
## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 完了
- **開始日**: 2026-05-11
- **完了日**: 2026-05-11
- **担当**: Claude (Opus 4.7)
- **エクスプレス適格性**: -
- **適格性理由**: -
