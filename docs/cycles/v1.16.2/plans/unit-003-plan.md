# Unit 003 計画: バージョンファイル更新スクリプト

## 概要

version.txtとdocs/aidlc.tomlのバージョン番号を1コマンドで一括更新するスクリプト `update-version.sh` を新規作成する。

## 前提知識

### 現行の手動手順（docs/cycles/rules.md）
1. `echo "${VERSION}" > version.txt`
2. `sed -i '' "s/^starter_kit_version = .*/starter_kit_version = \"${VERSION}\"/" docs/aidlc.toml`
3. 更新確認（cat version.txt, grep starter_kit_version docs/aidlc.toml）

### 対象ファイル
- `version.txt`: バージョン番号のみ（例: `1.16.1`）
- `docs/aidlc.toml`: `starter_kit_version = "1.16.1"` 行

## 成果物

| ファイル | 内容 |
|--------|------|
| `prompts/package/bin/update-version.sh` | バージョン一括更新スクリプト（新規） |
| `docs/cycles/rules.md` | 手動手順をスクリプト呼び出しに置換 |

## 実装計画

### Phase 1: 設計・計画承認
1. 計画ドキュメント作成（本ファイル）
2. ユーザー承認

### Phase 2: 実装
3. `update-version.sh` 新規作成
4. `docs/cycles/rules.md` 手順更新
5. rsync同期
6. テスト実行
7. AIレビュー
8. ユーザー承認

## スクリプト設計

### 入力
- `--version <version>`: バージョン番号（必須。vプレフィックス付き可: v1.16.2 → 1.16.2）
- `--dry-run`: 実際の書き込みを行わず、変更内容を表示

### 出力形式
```
version_update:success                   # 更新成功
version_update:dry-run                   # dry-run実行
  version_txt:1.16.2                     # version.txtの値
  aidlc_toml:1.16.2                      # aidlc.tomlの値
error:missing-version                    # --version未指定
error:invalid-version-format             # 不正なフォーマット
error:version-txt-not-found              # version.txt不在
error:aidlc-toml-not-found               # docs/aidlc.toml不在
```

**注**: dry-run出力は既存パターンに合わせフラット形式。successの場合も同様に更新後の値を出力。

### 処理フロー
1. 引数解析（--version, --dry-run）
2. バージョンフォーマット検証（SemVer: X.Y.Z形式、vプレフィックス自動除去）
3. 対象ファイル存在確認（version.txt, docs/aidlc.toml）
4. dry-run時: 変更内容表示のみ
5. version.txt書き換え
6. docs/aidlc.toml書き換え（sed -i '' macOS互換）
7. 結果出力

### 終了コード
- 0: 正常終了（更新成功またはdry-run）
- 1: エラー

## 完了条件チェックリスト

- [ ] update-version.sh が新規作成されている
- [ ] --versionオプションでバージョン指定できる
- [ ] vプレフィックス付きバージョンを自動除去する
- [ ] version.txtを正しく更新する
- [ ] docs/aidlc.tomlのstarter_kit_versionを正しく更新する
- [ ] --dry-runで変更内容のみ表示する
- [ ] 不正フォーマット時にエラーを出力する
- [ ] docs/cycles/rules.mdの手動手順がスクリプト呼び出しに更新されている
