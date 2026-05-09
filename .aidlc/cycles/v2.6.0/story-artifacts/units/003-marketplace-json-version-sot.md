# Unit: marketplace.json への version SoT 一本化

## 概要

`.claude-plugin/marketplace.json` の `metadata.version` をバージョン参照の唯一の SoT に確定し、ルート / `skills/aidlc/` / `skills/aidlc-setup/` の `version.txt` 3 ファイルを廃止する。`bin/update-version.sh` を `marketplace.json` 更新主体に再構築し、参照側コード（`SKILL.md` / `01-setup.md` / `env-info.sh` / `lib/version.sh`）を全て書き換える。pre-release / CI ガードを追加。

## 含まれるユーザーストーリー

- ストーリー 1A: marketplace.json への version 参照経路移行
- ストーリー 1B: bin/update-version.sh の marketplace.json 主体化
- ストーリー 1C: pre-release / CI ガード追加
- ストーリー 1D: 冗長 version.txt 3 ファイルの廃止

## 責務

1. **SoT 確定とバックフィル**: `marketplace.json.metadata.version` を `2.0.4` → `2.6.0` に更新
2. **参照側コード移行**: 以下の参照箇所を `marketplace.json` 参照に書き換え
   - `skills/aidlc/SKILL.md`「バージョン表示」セクション（version アクション）
   - `skills/aidlc/steps/inception/01-setup.md` ステップ5a の 3 経路（リモート / スキル / ローカル）
   - `skills/aidlc/scripts/env-info.sh` の `get_starter_kit_version()` 経路
   - `skills/aidlc/scripts/lib/version.sh` の `read_starter_kit_version()` 経路
3. **`bin/update-version.sh` 再構築**: `marketplace.json` を更新主体とし、`version.txt` 系 3 ファイル更新ロジックを削除（または、ファイル削除完了まで段階的に移行）
4. **冗長 `version.txt` ファイル削除**: 参照側コード移行完了後に 3 ファイルを削除
5. **`config.toml.starter_kit_version` の役割明文化**: README または `.aidlc/rules.md` に「アップグレード差分検出のためのローカルキャッシュ値」「正本判定は `marketplace.json` で行う」を追記
6. **pre-release / CI ガード追加**: `marketplace.json` 未更新でのリリースを検出するチェックスクリプトを追加（`bin/` 配下に新規 or 既存 CI workflow 拡張）

## 境界

- `aidlc-setup` の no-op スキップ実装は **Unit 004 の責務**（本 Unit は SoT 一本化のみ）
- リモート version.txt（`raw.githubusercontent.com/.../main/version.txt`）の curl 取得は、新規 SoT である `marketplace.json` に切り替え（リモート JSON 取得 + `dasel`/`jq` 抽出）
- `aidlc-migrate` 側の version 参照ロジックは触らない（`config.toml.starter_kit_version` の用途は維持）

## 依存関係

### 依存する Unit

- なし（Unit 003 は本サイクルの基盤 Unit）

### 外部依存

- `dasel` v3.x（プリフライトで確認済み、JSON パース可）または `jq`（CI 環境でも一般的）
- `curl`（リモート取得）

## 非機能要件（NFR）

- **正確性**: 移行前後でバージョン表示・比較ロジックが同一値を返すこと
- **段階性**: 参照側移行 → ファイル削除の順序を厳守（逆順は CI 破損リスク）
- **観測性**: pre-release / CI ガードで `marketplace.json` 未更新を検出可能

## 技術的考慮事項

- 削除順序の厳守（DR 候補）:
  1. `marketplace.json.metadata.version` バックフィル（2.0.4 → 2.6.0）
  2. 参照側コード書き換え（read 経路を `marketplace.json` に切替、ただし旧 `version.txt` も後方互換で並行参照可とする一時段階を挟む選択肢を Construction Design で検討）
  3. 新規 CI ガード追加（`marketplace.json` 未更新検出）
  4. `update-version.sh` を `marketplace.json` 主体に再構築
  5. 冗長 `version.txt` 3 ファイル削除
  6. 一時的な後方互換並行参照ロジックの除去
- `dasel` で JSON 抽出: `dasel -i json '.metadata.version' < marketplace.json`
- `read-config.sh starter_kit_version` の参照先変更: 既存呼び出し元の互換維持のため、関数内部で `marketplace.json` を参照する形に変更（外部 API 互換維持）
- スキル version (`/aidlc version`) の SKILL.md ロジック更新: 「`version.txt` を読み込む」→「`marketplace.json` から `metadata.version` を読み込む」に変更

## 関連Issue

- #617

## 実装優先度

High

## 見積もり

3〜5 時間（参照箇所の移行 + 削除 + CI ガード + テスト）

---
## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
- **エクスプレス適格性**: -
- **適格性理由**: -
