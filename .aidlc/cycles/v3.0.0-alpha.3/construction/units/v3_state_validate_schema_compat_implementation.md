# 実装記録: Unit 004 state-validate.sh schema_version 互換性検証（#731）

## 基本情報

- **サイクル**: v3.0.0-alpha.3（Phase 3）
- **Unit**: 004-state-validate-schema-compat
- **関連 Issue**: #731
- **状態**: 完了
- **depth_level**: standard / **review_mode**: required / **automation_mode**: semi_auto

## 実装内容

### 1. `skills/aidlc-v3/scripts/state-validate.sh`（改修）

- サポート対象集合 `SUPPORTED_SCHEMA_VERSIONS=("3.0")`（readonly インデックス配列 / bash 3.2 互換）を追加。`docs/v3/data-model.md` §3 を SoT とするコメント付き。本配列が schema 互換性判定の Single Source of Truth。
- 既存の単一 jq if-elif 検証を **2 段に分割**:
  - 前段 jq: `schema_version` の has + string 型のみ検証（既存メッセージ・挙動を維持）。
  - bash 側で値を supported 集合とループ照合。**未知**は stderr に WARN 案内（migration / §6）+ stdout に `status:warn:unsupported-schema-version:<safe-value>` + **exit 0** で短絡（後段の構造検証を行わない）。
  - 後段 jq: 既知バージョンのみ残りの必須/型/release サブフィールド + ISO 8601 を検証（従来どおり）。
- **status 行 parse 契約保護**: `<safe-value>` は生値から制御文字を `tr -d '[:cntrl:]'` で除去し単一行を保証。生値は stderr 側にのみ表示。

### 2. `skills/aidlc-v3/scripts/state-write.sh`（改修）

- 書き込み前（JSON 妥当性確認後・mktemp 前）に **元ファイル**を `$VALIDATE` で検証する非互換更新ガードを追加（互換性判定は validator を SoT として再利用 / supported 集合を重複定義しない）。
- rc 別ハンドリング:
  - rc=0 かつ先頭行 `status:valid` → 従来どおり更新へ進む。
  - rc=0 かつ先頭行が接頭辞 `status:warn:unsupported-schema-version:` → 更新拒否（exit 1 / ファイル不変 / 接頭辞のみで判定し値内容非依存）。
  - rc=0 かつそれ以外（空 / 未知 status 行）→ validator 出力契約違反として exit 2（fail-safe / コードレビュー指摘 #1 対応）。
  - rc=1（未知以外の invalid）→ 従来動作を維持（post-write 検証で捕捉 / 非後退）。
  - rc=2 → exit 2。
- 拒否は mktemp より前のため temp も作らずファイルに一切触れない。

### 3. `skills/aidlc-v3/scripts/tests/test-state-scripts.sh`（テスト追加）

- validator: 既知 3.0=valid / 未知 4.0・2.0・3.1=warn+exit0 / 非 string・欠落=exit1（非後退）/ 未知+release欠落=warn+exit0（短絡）/ 改行入り未知値=stdout 単一行+接頭辞一致+exit0（parse 契約保護）。
- writer: 未知 4.0 更新拒否=exit1+ファイル不変 / 改行入り未知値も拒否+不変 / 拒否時 temp 不残存 / 既知 3.0 更新=従来どおり成功。

## テスト結果

- `skills/aidlc-v3/scripts/tests/test-state-scripts.sh`: **PASS=88 FAIL=0**（追加前 67 → 21 件追加）。
- `bash -n` / `shellcheck`: 3 スクリプトとも通過（テスト内静的検査）。
- `markdownlint-cli2`（設計・計画・サマリ md）: 0 error。
- **v2 非影響**: `skills/aidlc/`（v2）配下に変更なし（`git status` で確認）。

## レビュー

- 計画レビュー（reviewing-construction-plan / codex / 1R）: 指摘0件。
- 設計レビュー（reviewing-construction-design / codex / 3R）: R1 2件 + R2 1件 全 3 件 resolve / R3 clean。
- コードレビュー（reviewing-construction-code / focus code,security / codex / 2R）: R1 1件（低/security: rc=0 分岐 fail-safe 化）resolve / R2 clean。security は status 行 parse 契約保護・非互換更新ガードが主眼で N/A 範囲を明記。
- 統合レビュー: 本記録作成後に実施。

## 完了条件チェックリスト達成状況

- [x] `state-validate.sh` に schema_version 値の互換性検証を追加（supported 集合 = "3.0"）
- [x] 未知 schema_version を invalid にせず WARN + 案内（exit 0 / parse 可能な status:warn:unsupported-schema-version:<value>）
- [x] `state-write.sh` が未知 schema_version の既存 state を更新しないガード（exit 1 / ファイル不変）
- [x] writer ガードが validator を SoT として再利用（supported 集合を重複定義しない）
- [x] サポート対象値 / 未知値 / 型不正の境界テストを validator・writer 両方に追加
- [x] 既存の必須フィールド・型検証が非後退（既存テスト全 pass）
- [x] writer の既存挙動（許可フィールド・atomic 性・元 invalid 保持）が非後退
- [x] v2 非影響
- [x] bash -n / shellcheck / markdownlint 通過

## 備考

- 終了コード規約（0=valid/WARN, 1=validation error, 2=system error）準拠。「WARN を exit 非 0 にしない」を validator の未知バージョン経路で遵守。
- bash 3.2 互換（連想配列不使用 / インデックス配列ループ）。
