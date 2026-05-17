# 論理設計: Unit 004 defaults.toml 二重 SoT 同期ガード

## ステップ 0: 事前コード読込み

> 適用条件: depth_level != minimal の場合のみ必須。minimal は設計ステップ自体スキップ可のため N/A。

### (a) Read 対象ファイル + 目的

| ファイル | 目的 |
|---------|------|
| `bin/check-defaults-sync.sh` | 既存スクリプトの拡張ポイントを特定（diff 出力のあと、構造比較を追加挿入） |
| `.github/workflows/pr-check.yml` (line 93-130) | 既存ジョブ構造を維持しつつスクリプト出力契約変更に追従可能か確認 |
| dasel CLI v3 のキーパス列挙インターフェース | `-i toml -r toml -w json` で JSON 化後 jq でキーパス展開する方式の妥当性確認 |

### (b) 設計時に意識すべき挙動

- dasel v3 は `cat file | dasel -i toml '<key>'` で値取得可能。トップキー列挙は `cat file | dasel -i toml -r toml -w json | jq -r 'paths | join(".")'` で実現可能
- 既存ジョブの後方互換維持: exit 0 / 1 のセマンティクスは保持、stdout の `sync:ok` / `sync:mismatch` 形式も維持
- failure contract は stderr に出力し、既存 stdout を汚さない

### (c) 既存実装に基づく代替案検討

- **採用**: 既存スクリプトに「Phase 2: 構造比較」を追加。Phase 1（行ベース diff）の結果を保持しつつ Phase 2 で詳細を出力
- **却下**: スクリプトを完全 dasel ベースに置き換え → コメント・空行除外ロジックを失う、後方互換性低下

## 概要

`bin/check-defaults-sync.sh` を 2 段階比較（Phase 1 diagnostic + Phase 2 gate）に拡張。`.github/workflows/pr-check.yml` の `defaults-sync-check` ジョブには dasel/jq インストールステップを追加する（依存解決の一次防御）。

## アーキテクチャパターン

- **gate 役割分離パターン**:
  - Phase 1 (行ベース diff、既存) は **diagnostic 降格**: 人間可読の補助表示のみ。**exit code 判定には使わない**
  - Phase 2 (構造比較、新規) のみが **gate**: キー集合 + 型一致で exit code を決定する正規ガード
  - これによりコメント/整形差分由来の従来 false positive を完全排除（#714 の「構造的予防」設計意図と整合）
- **後方互換維持**: exit code セマンティクス（0=ok / 1=mismatch / 2=error:not-found）を維持しつつ 3=parse-error / 4=tool-missing を拡張
- **stderr 分離**: machine-readable な failure contract は stderr に出力し、人間可読 stdout と分離
- **依存解決二重防御**: (a) `.github/workflows/pr-check.yml` の `defaults-sync-check` ジョブで `dasel` を sha256 検証つき curl ダウンロード + `sudo install` で `/usr/local/bin/dasel` 配置（v3.10.1 pin / SECURITY-10 対策）。`jq` は ubuntu-latest preinstalled + (b) スクリプト内で `command -v dasel` / `command -v jq` の存在確認 → 不在時 `error:tool-missing` で exit 4

## コンポーネント構成

```text
bin/
└── check-defaults-sync.sh    # Phase 1 (既存) + Phase 2 (新規 / 構造比較 gate) を統合実行
.github/workflows/
└── pr-check.yml              # defaults-sync-check ジョブに dasel/jq インストールステップを追加（依存解決の一次防御）
```

## インターフェース設計

### スクリプト I/O 契約

| 出力ストリーム | 形式 |
|---------------|------|
| stdout | `sync:ok` または `sync:mismatch` + Phase 1 (diagnostic) 人間可読差分 + 修復方法 + コマンド例 |
| stderr | machine-readable failure contract（Phase 2 gate 検出時のみ）。形式: `error:key-missing-in-source:<path>` / `error:key-missing-in-copy:<path>` / `error:type-mismatch:<path>:<source_type>:<copy_type>` / `error:parse-error:<file>:<message>` / `error:tool-missing:<tool>` |
| exit code | 0=ok / 1=mismatch (key-missing or type-mismatch) / 2=error:not-found (既存) / 3=error:parse-error (新規) / 4=error:tool-missing (新規) |

### Phase 2 構造比較ロジック（gate / 正規判定）

0. **依存ツール存在確認**: `command -v dasel` / `command -v jq` 不在時 → `error:tool-missing:<tool>` stderr 出力 + exit 4
1. **パース**: `dasel` で正本 TOML を JSON 変換 → jq でキーパス + 値型を列挙。dasel エラー時 → `error:parse-error:<file>:<message>` stderr + exit 3
2. 同様にコピー TOML をキーパス + 値型集合に展開
3. 対称差を計算:
   - 正本にのみあるキー → `error:key-missing-in-copy:<path>` stderr 出力
   - コピーにのみあるキー → `error:key-missing-in-source:<path>` stderr 出力
   - 両方にあるが型不一致 → `error:type-mismatch:<path>:<source_type>:<copy_type>` stderr 出力
4. **gate 判定**: いずれか 1 件でも検出 → exit 1 / すべて一致 → exit 0（Phase 1 は diagnostic のため exit には影響しない）
5. Phase 1 mismatch でも Phase 2 一致なら exit 0（コメント・整形差分由来の false positive を排除）

### 修復方法表示 (stdout 末尾)

```text
修復方法:
  1. 正本側で意図した変更の場合: aidlc-setup 側に同セクションを追加 (手動 Edit)
  2. コピー側に余分なキーがある場合: 正本に合わせて削除
  3. 詳細差分: 上記 diff 出力 + stderr の error: 行を参照
コマンド例:
  diff skills/aidlc/config/defaults.toml skills/aidlc-setup/config/defaults.toml
```

## 処理フロー概要

1. ファイル存在チェック (既存 / 変更なし)
2. Phase 1 (diagnostic): 行ベース diff (既存ロジック流用、`sync:ok` または `sync:mismatch` を stdout 出力)。**gate には使わない**
3. Phase 2 (gate): dasel + jq でキーパス + 型を抽出、対称差を計算、failure contract を stderr 出力
4. exit code: **Phase 2 のみで判定**。Phase 2 一致なら exit 0（Phase 1 mismatch でも exit 0）、Phase 2 不一致なら exit 1。例外: tool-missing=4 / parse-error=3 / not-found=2

## 非機能要件 (NFR)

- パフォーマンス: dasel + jq の追加で +1 秒程度 (TOML ファイル 100 行規模)、CI 全体への影響無視可能
- 後方互換: スクリプトの stdout 形式 + exit code 0/1/2 セマンティクス維持。`pr-check.yml` には dasel/jq インストールステップ追加が必要（依存解決の一次防御）

## 実装上の注意事項

- `dasel -i toml -r toml -w json` は v3 の正規記法。`-f file` は v3 で削除されているため `cat file | dasel -i toml ...` か `dasel -i toml ... < file` を使う
- 本リポジトリ規約: Bash ツール引数文字列にコマンド置換 `$(...)` / backtick を含めない（スクリプト本体内の `$(...)` は OK、Bash ツール呼び出し時の引数文字列のみ禁止）
- スクリプト内 dasel 呼び出しは pipe 経由 (`cat ... | dasel ...`) で統一
- jq 出力の改行・ソート順序の安定性を `LC_ALL=C sort` で保証
