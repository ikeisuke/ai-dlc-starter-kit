# ドメインモデル: バージョン三角モデル比較

## エンティティ

### VersionSource（値オブジェクト）
バージョン情報の取得元を表す。

| 属性 | 型 | 説明 |
|------|-----|------|
| name | string | ソース名（remote / skill / local） |
| version | semver \| null | 取得したバージョン（取得失敗時はnull） |
| available | boolean | 取得成功したか |
| error_reason | string \| null | 取得失敗時の理由 |

### VersionTriangle（集約）
3つのVersionSourceを保持し、比較パターンを判定する。

| 属性 | 型 | 説明 |
|------|-----|------|
| remote | VersionSource | リモートリポジトリ（GitHub main/version.txt） |
| skill | VersionSource | インストール済みスキル（スキルベースディレクトリ/version.txt） |
| local | VersionSource | ローカル設定（.aidlc/config.toml/starter_kit_version） |

### ComparisonResult（値オブジェクト）
比較判定の結果を表す。

| 属性 | 型 | 説明 |
|------|-----|------|
| pattern | enum | 比較パターン（下記7種） |
| actions | Action[] | 提示するアクションのリスト |
| warnings | string[] | 警告メッセージのリスト |

## 比較パターン（enum）

| パターン | 判定条件 | 期待アクション |
|---------|---------|--------------|
| ALL_MATCH | remote = skill = local | アクションなし |
| REMOTE_NEWER | remote > skill = local | スキル更新促進 |
| SKILL_OLDER | remote = local > skill | スキル更新促進 |
| LOCAL_OLDER | remote = skill > local | `/aidlc setup` 促進 |
| LOCAL_AHEAD | local > remote = skill | 警告表示 |
| MULTIPLE_MISMATCH | 上記以外 | スキル更新→ローカル更新の順 |
| COMPARISON_FAILED | いずれか取得失敗 | 取得可能分のみ比較 + 警告 |

## ドメインサービス

### VersionComparisonService
VersionTriangleの3点を比較し、ComparisonResultを生成する。

**判定フロー**:
1. 全ソースのavailableを確認 → いずれかfalseなら COMPARISON_FAILED
2. 全バージョン一致 → ALL_MATCH
3. remote > skill = local → REMOTE_NEWER
4. remote = local > skill → SKILL_OLDER
5. remote = skill > local → LOCAL_OLDER
6. local > remote = skill → LOCAL_AHEAD
7. それ以外 → MULTIPLE_MISMATCH

### FallbackService
スキルバージョン取得失敗時に、従来の2点間比較（remote vs local）にフォールバックする。
