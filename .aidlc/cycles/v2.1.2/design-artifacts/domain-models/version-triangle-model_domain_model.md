# ドメインモデル: バージョン三角モデル比較

## エンティティ

### VersionSource（値オブジェクト）
バージョン情報の取得元を表す。

| 属性 | 型 | 説明 |
|------|-----|------|
| name | string | ソース名（remote / skill / local） |
| raw_value | string \| null | 取得した生の値（取得失敗時はnull） |
| version | semver \| null | 正規化後のバージョン（パース失敗時はnull） |
| available | boolean | 取得成功かつパース成功したか |
| error_reason | string \| null | 取得失敗またはパース失敗時の理由（invalid_semver / fetch_failed / empty_value 等） |

**正規化ルール**:
- `v`プレフィックスは除去して比較（`v2.1.1` → `2.1.1`）
- 前後の空白・改行をトリム
- 空文字 → `available=false`, `error_reason=empty_value`
- semverとしてパース不可 → `available=false`, `error_reason=invalid_semver`

### VersionTriangle（集約）
3つのVersionSourceを保持し、比較モードを判定する。

| 属性 | 型 | 説明 |
|------|-----|------|
| remote | VersionSource | リモートリポジトリ（GitHub main/version.txt） |
| skill | VersionSource | インストール済みスキル（スキルベースディレクトリ/version.txt） |
| local | VersionSource | ローカル設定（.aidlc/config.toml/starter_kit_version） |
| comparison_mode | ComparisonMode | 比較モード（取得状態から自動決定） |

### ComparisonMode（enum）
取得成功した情報源の組み合わせに応じた比較モード。

| モード | 条件 | 比較対象 |
|--------|------|---------|
| THREE_WAY | remote, skill, local 全て available | 3点比較 |
| REMOTE_LOCAL | skill のみ unavailable | remote vs local（従来フォールバック） |
| SKILL_LOCAL | remote のみ unavailable | skill vs local |
| REMOTE_SKILL | local のみ unavailable | remote vs skill |
| SINGLE_OR_NONE | 2つ以上 unavailable | 比較スキップ（警告のみ） |

### ComparisonResult（値オブジェクト）
比較判定の結果を表す。

| 属性 | 型 | 説明 |
|------|-----|------|
| pattern | enum | 比較パターン（下記8種） |
| comparison_mode | ComparisonMode | 使用した比較モード |
| actions | Action[] | 提示するアクションのリスト |
| warnings | string[] | 警告メッセージのリスト（unavailableソースの理由含む） |

## 比較パターン（enum）

| パターン | 判定条件 | 期待アクション |
|---------|---------|--------------|
| ALL_MATCH | remote = skill = local（THREE_WAYモードのみ） | アクションなし |
| REMOTE_NEWER | remote > skill = local | スキル更新促進 |
| SKILL_OLDER | remote = local > skill | スキル更新促進 |
| LOCAL_OLDER | remote = skill > local（またはREMOTE_LOCALモードでremote > local） | `/aidlc setup` 促進 |
| LOCAL_AHEAD | local > remote = skill（またはREMOTE_LOCALモードでlocal > remote） | 警告表示 |
| MULTIPLE_MISMATCH | 上記以外（3値が全て異なる等） | スキル更新→ローカル更新の順 |
| PARTIAL_MATCH | 部分比較モード（REMOTE_LOCAL/SKILL_LOCAL/REMOTE_SKILL）で一致 | 「取得可能分は一致」+ unavailableソースの警告 |
| PARTIAL_MISMATCH | 部分比較モードで不一致 | 差分表示 + unavailableソースの警告 + 比較方向に応じたアクション（例: remote > skill → スキル更新案内、skill > remote → 「スキルが先行」警告） |

## ドメインサービス

### VersionComparisonService
ComparisonModeに応じて比較を実行し、ComparisonResultを生成する。

**判定フロー**:
1. 各VersionSourceの`available`状態からComparisonModeを決定
2. ComparisonModeに応じた比較を実行:
   - THREE_WAY: 6パターンの判定（ALL_MATCH/REMOTE_NEWER/SKILL_OLDER/LOCAL_OLDER/LOCAL_AHEAD/MULTIPLE_MISMATCH）
   - REMOTE_LOCAL: remote vs local の2点比較（一致/remote新しい/local新しい）
   - SKILL_LOCAL: skill vs local の2点比較（一致→PARTIAL_MATCH / 不一致→PARTIAL_MISMATCH）
   - REMOTE_SKILL: remote vs skill の2点比較（一致→PARTIAL_MATCH / 不一致→PARTIAL_MISMATCH）
   - SINGLE_OR_NONE: 比較スキップ、警告のみ生成
3. unavailableソースの`error_reason`をwarningsに追加

### スキルバージョン取得の具体的手順

1. `skills/aidlc/SKILL.md` の親ディレクトリ（= `skills/aidlc/`）をベースディレクトリとして特定
2. ベースディレクトリ直下の `version.txt` をReadツールで読み込む（パス: `skills/aidlc/version.txt`）
3. 読み込み成功時: 正規化ルールを適用してバージョンを取得
4. 読み込み失敗時（ファイル不在/空/パース不可）: `available=false` として ComparisonMode を REMOTE_LOCAL に切り替え

**注意**: リポジトリルートの `version.txt` はリリースバージョン管理用であり、スキルバージョンとは別物。混同禁止。
