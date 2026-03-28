# 論理設計: スキルリソース移設・重複削除

## 概要

ファイル移動・削除・シンボリックリンク更新の実行手順を詳細化する。

## コンポーネント構成

### 1. ファイル移動コンポーネント

git mvによる移動。3カテゴリを順次実行。

#### 1.1 guides移動（18ファイル）

```text
docs/aidlc/guides/*.md → skills/aidlc/guides/
```

前提: `skills/aidlc/guides/` を事前に作成。

#### 1.2 tests移動（11ファイル）

```text
docs/aidlc/tests/*.sh → skills/aidlc/scripts/tests/
```

既存ファイル `test_wildcard_detection.sh` と重複なし（確認済み）。

#### 1.3 kiro移動（1ファイル）

```text
docs/aidlc/kiro/agents/aidlc.json → kiro/agents/aidlc.json
```

前提: `kiro/agents/` を事前に作成。

### 2. シンボリックリンク更新コンポーネント

#### 2.1 .kiro/agents/（1件、移動に伴う更新）

```text
.kiro/agents/aidlc.json: ../../docs/aidlc/kiro/agents/aidlc.json → ../../kiro/agents/aidlc.json
```

#### 2.2 .agents/skills/（6件、既存の壊れたリンク修正）

| リンク | 新ターゲット |
|--------|-------------|
| aidlc-setup | ../../skills/aidlc-setup |
| reviewing-architecture | ../../skills/reviewing-architecture |
| reviewing-code | ../../skills/reviewing-code |
| reviewing-inception | ../../skills/reviewing-inception |
| reviewing-security | ../../skills/reviewing-security |
| squash-unit | ../../skills/squash-unit |

#### 2.3 .kiro/skills/（6件、既存の壊れたリンク修正）

.agents/skills/ と同一のターゲット構成。

### 3. 重複削除コンポーネント

git rmによる��除。全ファイルはskills/aidlc/（正本）のコピーまたは旧版。

#### 3.1 docs/aidlc/ 配下の重複

```text
git rm -r docs/aidlc/prompts/       # skills/aidlc/steps/ の旧コピー
git rm -r docs/aidlc/templates/      # skills/aidlc/templates/ の旧コピー
git rm docs/aidlc/lib/validate.sh    # skills/aidlc/scripts/lib/validate.sh と一致
git rm -r docs/aidlc/.github/        # ルート .github/ の旧コピー
```

#### 3.2 docs/aidlc/ 空ディレクトリの残り確認

移動・削除後に残存ファイルを確認:

```text
find docs/aidlc/ -type f  # 0件であること
git rm -r docs/aidlc/     # ディレクトリごと削除
```

#### 3.3 prompts/package/ の削除

```text
git rm -r prompts/package/  # docs/aidlc/ のパッケージングコピー（96ファイル）
```

## 実行順序

```text
Step 1: mkdir（移動先ディレクトリ作成）
Step 2: git mv（guides, tests, kiro）
Step 3: ln -sf（シンボリックリンク更新 13件）
Step 4: git rm（重複削除）
Step 5: git rm（docs/aidlc/ 削除）
Step 6: git rm（prompts/package/ 削除）
Step 7: 検証
```

## 検証項目

| 項目 | 検証方法 |
|------|---------|
| guides移動 | `ls skills/aidlc/guides/ \| wc -l` = 18 |
| tests移動 | `ls skills/aidlc/scripts/tests/ \| wc -l` = 12 |
| kiro移動 | `test -f kiro/agents/aidlc.json` |
| symlink有効性 | `find .agents .kiro -type l` の各リンクが `test -e` で存在確認 |
| docs/aidlc/削除 | `test ! -d docs/aidlc/` |
| prompts/package/削除 | `test ! -d prompts/package/` |

## スコープ外（他Unitの責務）

- `{{aidlc_dir}}/guides/...` パス参照の更新（Unit 002）
- `aidlc_dir` 設定キーの廃止（Unit 002）
- `bin/check-*.sh` のデフォルトパス変更（Unit 003）
- `prompts/setup/` 配下のパス更新（Unit 003）
