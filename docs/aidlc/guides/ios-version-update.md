# iOSバージョン更新ガイド

このガイドはiOSプロジェクト（`project.type=ios`）向けのバージョン更新手順を説明します。

## 前提条件確認

AIが `docs/aidlc.toml` をReadツールで読み取り、`[project]` セクションの `type` 値を確認。

**フォールバック規則**: ファイル未存在/読み取りエラー/構文エラー/値未設定時は `general` として扱う。

**判定**:
- `PROJECT_TYPE != "ios"` の場合: このガイドの処理をスキップ
- `PROJECT_TYPE = "ios"` の場合: 以下を実行

## バージョン更新提案

```text
【iOSプロジェクト向け】バージョン更新の確認

project.type=iosのため、Inception Phaseでバージョンを更新することを推奨します。

これにより、Construction Phase中のTestFlight配布が可能になります。

1. はい - バージョンを更新する（推奨）
2. いいえ - Operations Phaseで更新する
```

## 更新手順（「はい」を選択した場合）

### 1. バージョン確認対象の特定

- 運用引き継ぎ（`docs/cycles/operations.md`）に「バージョン確認設定」があれば参照
- なければユーザーに質問: 「バージョン管理ファイルはどれですか？（例: Info.plist, project.pbxproj）」

### 2. 現在のバージョン確認と更新

```bash
# サイクルバージョンからvプレフィックスを除去
CYCLE_VERSION="${{CYCLE}#v}"
echo "更新後のバージョン: ${CYCLE_VERSION}"
```

- 対象ファイルのバージョンを更新（CFBundleShortVersionString等）

### 3. 履歴への記録（重要）

```bash
docs/aidlc/bin/write-history.sh \
    --cycle {{CYCLE}} \
    --phase inception \
    --step "iOSバージョン更新実施" \
    --content "CFBundleShortVersionString を ${CYCLE_VERSION} に更新" \
    --artifacts "[更新したファイル]"
```

**注意**: 「iOSバージョン更新実施」の文言は履歴に必ず含めてください。Operations Phaseでこの記録を確認し、重複更新を防ぎます。

## スコープ外

- ビルド番号（CFBundleVersion）の管理はこの機能のスコープ外です
- ビルド番号はCI/CD（fastlane等）で自動管理することを推奨します
