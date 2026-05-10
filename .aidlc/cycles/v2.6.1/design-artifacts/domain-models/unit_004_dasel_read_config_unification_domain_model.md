# Unit 004 ドメインモデル: dasel 直接呼び出しの read-config.sh 経由統一 + 規約追記

## 概要

AI プロンプト（`.md`）と共通ルール（`rules-core.md`）の規約整備に閉じる変更のため、複雑なドメインオブジェクトは持たない。本ドキュメントは「TOML 設定読取の正規経路と禁止呼び出しパターン」を整理する軽量モデル。

## 主要概念

### ConfigReadChannel（設定読取の正規経路）

`.aidlc/config.toml` の読取経路を 3 階層で整理する。AI エージェントは原則として **(1) 正規経路** を使う。

| 階層 | 経路 | 用途 | 利用主体 |
|------|------|------|---------|
| (1) 正規経路 | `bash scripts/read-config.sh <key>`（実行時 = スキルベース相対 / 検証時 = `bash skills/aidlc/scripts/read-config.sh <key>`） | 通常の設定読取（AI プロンプト・ユーザースクリプト・CI スモークテスト） | AI エージェント / 人間 / CI |
| (2) 直接呼び出し（限定） | `cat <file> \| dasel -i toml '<key>'` または `dasel -i toml '<key>' < <file>` | (1) が動作不能な低レイヤー（bootstrap 内部・stdlib 系・aidlc-setup の早期判定） | 共有ライブラリ実装者 |
| (3) 禁止 | `dasel -f <file> '<key>'`（不正フラグ）等の anti-pattern | （いずれの主体でも禁止） | - |

### DaselSyntaxConstraint（dasel CLI v3 の構文制約）

dasel CLI v3 で **「許容される直接呼び出し構文」** と **「禁止構文」** を明示的に分離する。

| 区分 | 構文 | 説明 |
|------|------|------|
| 許容 | `cat <file> \| dasel -i toml '<key>'` | パイプ経由のファイル読み込み + 入力タイプ指定 |
| 許容 | `dasel -i toml '<key>' < <file>` | リダイレクト経由のファイル読み込み + 入力タイプ指定 |
| 禁止 | `dasel -f <file> '<key>'` | dasel v3 で `-f` フラグは未対応（`unknown flag`、exit 80） |
| 禁止 | `dasel -f <file> -r toml '<key>'` | 同上、`-r`/`-f` 混在 |

### PublicApiScriptLayer（公開 API スクリプト層）

`scripts/read-config.sh` は AI-DLC スターターキット全体で共有される設定読取の **公開 API スクリプト** として位置付ける。これにより `.aidlc/rules.md` の「スキル間依存ルール」が禁じる「他スキルの内部実装への依存」に該当しないことを明確化する。

| 規定 | 内容 |
|------|------|
| 公開 API スクリプトの初期メンバー | `scripts/read-config.sh`（aidlc プラグイン内に配置）のみ |
| 利用可能スキル | 全スキル（`aidlc` / `aidlc-feedback` / `aidlc-setup` / `aidlc-migrate` / `reviewing-*`） |
| 内部実装との区別 | `scripts/lib/*` / `scripts/bootstrap.sh` など内部実装は引き続き「他スキル内部実装への依存禁止」の対象 |
| 例外の根拠 | 設定読取の正規経路が全スキルで統一されていないと、AI 誤生成（`dasel -f` 等）が発生する。公開 API として位置付けることで、anti-pattern 拡散を予防する |
| 規定の所在（上位） | `.aidlc/rules.md` の「スキル間依存ルール」に 1 行追記して例外を本体規定する（本 Unit のスコープに含める） |
| 規定の所在（詳細） | `steps/common/rules-core.md` の「設定読み込み」セクション内に「dasel 呼び出し規約」サブセクションを追記して詳細を展開（本 Unit で新設） |
| 将来の拡張 | 公開 API スクリプト層への追加メンバーは別 Issue / Unit で個別評価 |

## 不変条件

1. **正規経路優先**: AI プロンプト内の TOML 読取は (1) 正規経路を第一推奨とする。例外は (2) 直接呼び出しで明示理由を伴う場合のみ
2. **不正フラグ禁止**: `dasel -f` を含む禁止構文は AI プロンプト・規約説明文以外の場所に存在しない
3. **既存正常呼び出しの保護**: 既に許容構文（`cat ... | dasel -i toml`）を使用している箇所のうち、必須置換対象（A）以外は規約で予防し、コード変更不要とする
4. **早期判定段階の例外保護**: `aidlc-setup/01-detect.md` line 97 の dasel 直接呼び出しは「`.aidlc/config.toml` 自身の存在検証段階」（read-config.sh が必須前提とする config.toml 自体の存在確認の前段階）であり、`read-config.sh` 経由化が文脈的に不適切。現状の許容構文は規約 (1) (2) で compliant のため対象外とする（恒久的な技術的根拠、技術的負債ではない）

## 状態遷移

| 遷移元 → 遷移先 | 発火イベント | 動作変化 |
|----------------|------------|---------|
| 既存の `dasel -f` 不正フラグ → 正規経路 | 02-preparation.md の置換 | dasel CLI v3 で実行失敗 → `read-config.sh` 経由で正常終了 |
| 既存の許容構文（`cat ... \| dasel -i toml`） → 正規経路 | feedback.md の置換 | 動作は同等（`read-config.sh` のラッパー化、エラーハンドリングが exit code に整合） |
| 既存の許容構文（01-detect.md） → 維持 | （変更なし、規約セクションで compliant 確認） | 既存挙動維持 |
| anti-pattern 誤生成リスク → 規約セクションで予防 | rules-core.md の規約追記 | AI エージェントが規約を読み込み、`dasel -f` 誤生成を抑制 |

## 依存関係

- 上位: AI エージェント（プロンプトを読み込み実行）、CI（スモークテスト）
- 下位: `scripts/read-config.sh` → `lib/toml-reader.sh` → dasel CLI v3
- 横方向: `.aidlc/rules.md`「スキル間依存ルール」（公開 API 例外を 1 行追記）→ `rules-core.md`「設定読み込み」セクション内に詳細展開 → 全スキル（参照される共通ルール）

## ユビキタス言語

- **正規経路（canonical channel）**: `scripts/read-config.sh` 経由の設定読取
- **直接呼び出し（direct invocation）**: dasel CLI を直接 shell から呼ぶこと
- **不正フラグ（invalid flag）**: dasel CLI v3 で未対応のフラグ（`-f` が代表）
- **anti-pattern**: AI エージェントが誤生成しがちな禁止構文
- **公開 API スクリプト層（public API script layer）**: `scripts/read-config.sh` を全スキルから参照可能とする例外規定（内部実装ではない、公開された呼び出し契約）
