# Unit 004 計画: state-validate.sh schema_version 互換性検証（#731）

## 対象 Unit

- **Unit**: 004-state-validate-schema-compat（state-validate.sh schema_version 互換性検証 / #731）
- **サイクル**: v3.0.0-alpha.3（Phase 3）
- **依存 Unit**: なし（`state-validate.sh` は alpha.2 実装済み。本 Unit はその hardening）
- **関連 Issue**: #731（state-validate.sh schema_version 値の互換性検証 / alpha.2 で defer）
- **depth_level**: standard（設計フェーズあり）/ **review_mode**: required

## 目的（1 文）

`state-validate.sh` がサポート対象 `schema_version`（初版 `"3.0"`）と未知バージョンを値レベルで区別し、未知バージョンを `docs/v3/data-model.md` §6 の方針（WARN / migration・手動対応案内 / invalid 扱いにしない）に沿って扱えるようにし、あわせて `state-write.sh` が未知 `schema_version` の既存 `state.json` を更新しないガードを追加して #731 の本質リスク（writer が非互換 state を更新・保持する事故）を最小範囲で塞ぐ。

## 設計方針（前提認識）

- **方針の正本**: `docs/v3/data-model.md` §6（破損・不正・矛盾時の扱い）。`schema_version` 不一致 / 未知バージョンは「復帰不可（WARN。migration / 手動対応を案内）」。schema の正本は §3（必須フィールド・初版 `schema_version="3.0"`）。
- **終了コード規約**: v2 `skills/aidlc/guides/exit-code-convention.md` に準拠（0=正常/valid、1=バリデーションエラー、2=システムエラー）。Unit 技術的考慮事項のとおり **WARN 付き完了を exit 非 0 にしない**（未知 schema_version の validator 結果は exit 0）。
- **既存実装の非後退**: alpha.2 で実装済みの必須フィールド・型・release サブフィールド・ISO 8601 検証（`state-validate.sh`）と writer の許可フィールド・atomic 書き込み（`state-write.sh`）の挙動を変えない。既存テスト（`test-state-scripts.sh`）が全て pass し続けることを非後退の基準とする。
- **DRY（schema 互換性の SoT）**: サポート対象バージョン集合の知識は **validator を Single Source of Truth** とする。writer は書き込み前に validator を**元ファイル**に対して実行し、その出力で未知 schema_version を検知して更新を拒否する。writer 側に supported-version リストを重複定義しない。
- **検証はサンドボックス（`mktemp -d`）**で行い、v2 ドッグフーディング用 `.aidlc/` を一切破壊しない。

## 主要な実装対象

1. **`skills/aidlc-v3/scripts/state-validate.sh`（改修）**:
   - サポート対象 `schema_version` 集合（初版: `"3.0"`）を定義（data-model.md §3 を SoT として参照するコメント付き / Bash 3.2 互換のインデックス配列）。
   - `schema_version` が **string 型であることを確認した後**（型検証は既存）、集合と照合。
   - **未知値の場合**: stderr に WARN（migration・手動対応案内 / §6 参照）を出力し、stdout に `status:warn:unsupported-schema-version:<value>` を出力して **exit 0**。未知 schema のため 3.0 固有の後続フィールド検証は短絡（skip）する。
   - **既知値の場合**: 従来どおり後続の必須フィールド・型・release サブフィールド・ISO 8601 検証を継続し、`status:valid` / exit 0。
2. **`skills/aidlc-v3/scripts/state-write.sh`（改修）**:
   - 書き込み前（JSON 妥当性確認後・mktemp 前）に **元ファイル**を `state-validate.sh` で検証。
   - 出力が `status:warn:unsupported-schema-version:*`（かつ rc=0）の場合、**更新を拒否**し stderr に migration・手動対応案内を出力して **exit 1**（ファイルは一切変更しない）。
   - validator が rc=1（未知 schema_version 以外の invalid）/ rc=2（システムエラー）を返す場合は **従来動作を維持**（rc=1 はそのまま素通しし、既存の post-write 検証で捕捉 / 非後退）。これにより「元が他の理由で invalid な valid-JSON への書き込み → post-write 検証で exit 1・元ファイル保持」という既存テストの振る舞いを変えない。
3. **`skills/aidlc-v3/scripts/tests/test-state-scripts.sh`（テスト追加）**:
   - validator: 既知 `"3.0"` は `status:valid`／未知値（例 `"4.0"` / `"2.0"` / `"3.1"`）は `status:warn:unsupported-schema-version:*` かつ exit 0／`schema_version` 非 string は従来どおり exit 1（型検証が値検証より先）。
   - writer: 未知 schema_version の既存 state への更新は exit 1 かつ**ファイル不変**（before==after）／既知 `"3.0"` への更新は従来どおり成功／既存の異常系・atomic 性テストが非後退。

## 設計フェーズで確定すべき主要判断

| # | 論点 | 選択肢候補 | 備考 |
|---|------|-----------|------|
| D1 | 未知 schema_version 時の validator の出力契約 | (a) stdout に `status:warn:unsupported-schema-version:<value>` + stderr に案内 + exit 0【推奨】/ (b) exit 1（invalid 扱い） | Unit 技術的考慮事項「invalid にしない / WARN 付き完了を exit 非 0 にしない」より (a)。doctor/呼び出し側が parse 可能な status 行を返す。文字列フォーマットを設計で確定 |
| D2 | 未知 schema_version 時に 3.0 固有の後続検証を行うか | (a) 短絡して即 WARN/exit 0（未知 schema は 3.0 必須フィールドを保証しないため検証不能）【推奨】/ (b) 後続も実行 | §6「未知バージョンは migration / 手動対応」。未知 schema に 3.0 ルールを適用するのは不整合。(a) を推奨 |
| D3 | writer ガードの schema 互換性検知方式（DRY） | (a) 元ファイルを validator にかけ `status:warn:unsupported-schema-version:*` を検知して拒否（validator が SoT）【推奨】/ (b) writer 側で jq により schema_version を直接読んで supported リストと照合（リスト重複） | (a) は SoT 一元化。ただし validator rc=1（その他 invalid）時に既存の post-write 検証経路を壊さないよう、rc 別ハンドリングを設計で明記 |
| D4 | writer 拒否時の終了コード | (a) exit 1（バリデーション系の拒否 / ファイル不変）【推奨】/ (b) 新規コード | 終了コード規約は 0/1/2 のみ。更新拒否はシステムエラーでないため exit 1。メッセージで「unsupported schema_version / migration required / file left unchanged」を明示 |
| D5 | supported-version 集合の保持場所 | (a) validator 内に定数（インデックス配列 + data-model §3 SoT 参照コメント）【推奨】/ (b) 共有 lib 新設 | v3 scripts に共有 lib 基盤が未整備。最小範囲のため validator 内定数とし、writer は validator 経由で参照（D3）。共有 lib 新設はスコープ外 |

> schema の正本は `docs/v3/data-model.md` §3、未知バージョン方針は §6、終了コード規約は v2 `guides/exit-code-convention.md`。

## 完了条件チェックリスト

Unit 004「責務」から抽出:

- [x] `state-validate.sh` に `schema_version` 値の互換性検証を追加（型のみでなく値も区別 / supported 集合 = 初版 `"3.0"`）
- [x] 未知 `schema_version` 値を invalid（exit 1）にせず、WARN + migration・手動対応案内として扱う（§6 整合 / exit 0 / parse 可能な `status:warn:unsupported-schema-version:<value>` を出力）
- [x] `state-write.sh` が未知 `schema_version` の既存 `state.json` を更新しないガードを持つ（ファイルを不変のまま保持し migration・手動対応案内を出す / exit 1）
- [x] writer ガードが validator を SoT として再利用し、supported-version リストを重複定義しない（D3）
- [x] サポート対象値 / 未知値 / 型不正の境界テストを validator・writer 両方に追加
- [x] 既存の必須フィールド・型検証（alpha.2 実装）が非後退（既存 `test-state-scripts.sh` が全 pass）
- [x] writer の既存挙動（許可フィールド・atomic 性・元が他要因で invalid な場合の post-write 検証 exit 1・ファイル保持）が非後退
- [x] **v2 非影響**: `skills/aidlc/`（v2）配下に変更がない（`git diff` で確認）
- [x] `bash -n` / shellcheck（利用可能時）/ markdownlint を通過する

## 検証方針

- サンドボックス（`mktemp -d`）に既知/未知 schema_version の state.json フィクスチャを構築し、validator（既知 valid / 未知 warn+exit0 / 型不正 exit1）と writer（未知拒否 exit1+ファイル不変 / 既知更新成功）をアサート（既存 `test-state-scripts.sh` に追記、PASS 件数を増分）。
- v2 ドッグフーディング用 `.aidlc/` は一切変更しない。
- `bash -n` / shellcheck（利用可能時）/ markdownlint。

## スコープ境界（本 Unit に含まれないもの）

- `recovery.md` / migration スクリプトの実装（後続フェーズ。本 Unit は validator + writer の最小ガードに留める）
- `state-write.sh` の一般的な状態遷移制御（`define_completed` / `release.*` の許可・禁止遷移ルール）の本格実装（Phase 3+ の別範囲）
- v3 側 rules への終了コード規約の移植（後続フェーズ）
- 共有 lib による supported-version 集合の外出し（本 Unit は最小範囲 / D5）

## リスク

- **R1**: 未知 schema_version の validator 結果を exit 非 0 にしてしまい §6・終了コード規約に反する → D1/D2 で exit 0 + 短絡 + parse 可能 status を確定し、テストでアサート。
- **R2**: writer ガード追加が既存挙動（元が他要因で invalid な valid-JSON への書き込み）を後退させる → D3 で validator rc 別ハンドリングを明記し、既存 atomic テストの非後退を基準にする。
- **R3**: supported-version 集合の二重定義による drift → D3/D5 で validator を SoT とし writer は validator 経由で参照。
- **R4**: v2 `.aidlc/` 破壊リスク → サンドボックス隔離を徹底。
