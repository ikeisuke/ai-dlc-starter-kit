# Unit 003 実装計画: markdown lint 実行手段の統一エントリポイント化

## 対象 Unit

- **Unit**: 003 - markdown lint 実行手段の統一エントリポイント化
- **関連 Issue**: #709（クローズ対象）
- **検出元**: v2.6.3 Unit 003 統合レビュー Round 1 指摘 #3
- **親 Issue**: #698（/aidlc v 経路の再現性向上）
- **優先度**: Medium（chore / 開発体験改善）
- **depth_level**: standard（Phase 1 設計を実施）

## 背景・目的

`npx markdownlint-cli2` の直接呼び出しが repo 内に散在しており、外部 AI レビュー環境（codex 等）で `command not found` 再現エラーや、参照する設定ファイル・バイナリの取り違えが発生し得る。`npm run lint:md` を **統一エントリポイントとして提供** し、AI レビュー / CI / ローカル開発が **同一エントリポイント経由で起動でき、既存 CI 経路（`markdownlint-cli2-action`）との機能同等性が確認できる** 状態にする。

**バイナリ版固定について**: 本 Unit のスコープでは `npx markdownlint-cli2` 解決に委ね、CI 側 `DavidAnson/markdownlint-cli2-action@v18` との完全な同一バイナリ保証は対象外（最小変更原則）。版固定（`devDependencies` 化 + `package-lock.json` 生成 + CI 整合）は follow-up Issue #713 で別途扱う。

## スコープ

### 含まれるもの（責務）

- **必須対応 1**: リポジトリルートに `package.json` を新規作成し、`scripts.lint:md` に統一エントリポイント定義を追加（正本）
  - コマンド本体は `npx markdownlint-cli2 "docs/translations/**/*.md" "prompts/**/*.md" "*.md"`（既存 CI `.github/workflows/pr-check.yml` の `markdownlint-cli2-action` の `globs` と同一値）。`run-markdownlint.sh` は `.aidlc/cycles/<current cycle>/**/*.md` を含む別 scope を持つが、本 Unit の統一エントリポイントは「AI レビュー / CI / ローカル開発で同一の lint 結果」を担保するために CI scope を SoT とする
  - `markdownlint-cli2` は `npx` 経由で解決し、ローカル `devDependencies` 追加は本 Unit 対象外（最小変更）。版固定は follow-up Issue #713 で扱う
- **必須対応 2**: AI レビュー外部 CLI 実行基盤の SoT である `skills/reviewing-common/reviewing-common-base.md` の 1 箇所に統一コマンド `npm run lint:md` を明記（散在防止のため反映先を 1 箇所に固定）
  - SoT は `package.json` の `scripts.lint:md`。手順書側は「`npm run lint:md` を推奨」と 1 箇所だけ明示
  - 反映スコープは starter kit 内 AI レビュー導線に限定（consumer 一般向け導線・上位スキル横断 docs には未適用）
- **後方互換確認**: 既存 `npx markdownlint-cli2` 呼び出しと同一の設定ファイル（`.markdownlint-cli2.jsonc` / `.markdownlint.json` / `.markdownlintignore`）参照を確認。`skills/aidlc/scripts/run-markdownlint.sh` の既定経路 smoke 実行で実行互換を確認
- **新規エラー 0 件**: `npm run lint:md` で新規 markdownlint 違反が出ないこと

### 含まれないもの（境界 / Unit 定義に準拠）

- `Makefile` ラッパー追加（任意 / 不要）
- 既存 `npx markdownlint-cli2 ...` 直接呼び出しの全置換（後方互換のため残す）
- consumer プロジェクト（Node エコシステム外）の動作保証
- `markdownlint-cli2` のバージョンアップ / 設定変更
- CI ワークフロー（`.github/workflows/pr-check.yml`）の `markdownlint-cli2-action` 差し替え（後方互換維持。本 Unit では SoT 化のみ）
- `scripts/run-markdownlint.sh` の置換（既存契約維持）

## 設計方針

### package.json の最小構成

```json
{
  "name": "ai-dlc-starter-kit",
  "private": true,
  "scripts": {
    "lint:md": "npx markdownlint-cli2 \"docs/translations/**/*.md\" \"prompts/**/*.md\" \"*.md\""
  }
}
```

- `private: true` で npm publish 防止
- `name` のみ最小指定（バージョンは別 SoT である `.claude-plugin/marketplace.json` を変更しない）
- `devDependencies` は追加しない（`npx` 解決に委ねる）。本 Unit のスコープは「統一エントリポイント定義」までで、依存版固定は別 Issue として残せる
- glob は CI ワークフロー（`.github/workflows/pr-check.yml`）の `markdownlint-cli2-action` `globs` と同一値（`docs/translations/**/*.md` / `prompts/**/*.md` / `*.md`）。`.markdownlint-cli2.jsonc` の `ignores`（`docs/aidlc/**` / `docs/cycles/**` / `docs/versions/**`）と組み合わせた既存 CI 挙動と一致する

### docs 反映方針（SoT 1 箇所、starter kit 内レビュー導線限定）

- 反映先: `skills/reviewing-common/reviewing-common-base.md` の 1 箇所に固定（外部 CLI 実行基盤の SoT という性質上、散在防止に有利）
- 反映内容: 「markdown lint の標準実行コマンドは `npm run lint:md` を推奨。`package.json` の `scripts.lint:md` が SoT」とする 1 〜 2 行追記
- 既存 `npx markdownlint-cli2` 記述箇所への置換禁止（後方互換のため残す）
- **適用境界の明示**: 本追記は starter kit 内 AI レビュー導線（reviewing-common 系スキル経由）に限定。consumer プロジェクト一般向けの導線・上位スキル横断 docs（README.md など）には適用しない（consumer が `package.json` 不在でも誤って `npm run lint:md` を要求されないため）

### .gitignore 更新

- `node_modules/` を `.gitignore` に追加（package.json 導入の副作用として将来 `npm install` した場合の漏洩防止）
- 既存 `.gitignore` を Read してから差分追加

## 完了条件チェックリスト

Unit 定義「責務」セクション全項目を網羅:

- [x] `package.json` がリポジトリルートに存在し、`scripts.lint:md` が定義されている
- [x] `npm run lint:md` が exit 0 で完了し、新規 markdownlint エラーが 0 件（14 ファイル lint で 0 errors）
- [x] `npm run lint:md` が `.markdownlint-cli2.jsonc` / `.markdownlint.json` / `.markdownlintignore` を参照する（既存挙動と一致 / Finding ログ確認）
- [x] `skills/reviewing-common/reviewing-common-base.md` の 1 箇所に統一コマンド `npm run lint:md` が明記されている（適用境界注記を含む）
- [x] 既存 `npx markdownlint-cli2` 直接呼び出し箇所が破壊されていない（grep で 9 箇所残存確認）
- [x] `skills/aidlc/scripts/run-markdownlint.sh` の既定経路 smoke 実行が exit 0（5 ファイル lint で 0 errors / 実行互換確認）
- [x] `.gitignore` に `node_modules/` 追加
- [x] follow-up Issue #713（markdownlint-cli2 版固定）起票済み + 受入条件 7 項目追記
- [x] AI レビュー 3 種（設計 2R / コード 1R / 統合 2R）完了
- [x] Unit 定義ファイル（`003-markdown-lint-unified-entrypoint.md`）の実装状態を「完了」に更新
- [x] 履歴記録（`construction_unit03.md`）追記
- [x] Issue #709 クローズ対象として記録（本計画・履歴 / サイクル PR 時にクローズ）

## リスク・考慮事項

- **package.json 新規作成リスク**: 既存に存在しないため、何らかの暗黙の前提（例: 別ツールが「package.json 不在」を期待）に当たる可能性。事前 grep で `package.json` 存在を前提とする / 非存在を前提とする箇所を確認する
- **AI エージェント Bash ツール安全パターン**: 本 Unit は npm script 定義のみで、Bash ツール経由のコマンド置換は発生しない（`$(...)` / backtick 不使用）
- **ドッグフーディング特殊処理禁止**: starter kit 自身か consumer かを判定する分岐を `package.json` / 手順書に埋め込まない。consumer 側は `package.json` を持つかどうかで自然に opt-in 判定される

## 見積もり

0.5 日（最小変更 + docs 更新 + lint 実行確認）

## レビュー観点

- 設計レビュー: package.json 構成の妥当性、SoT 反映箇所の選定、ドッグフーディング特殊処理回避
- コードレビュー: package.json の最小性、glob パターンの既存挙動整合、`.gitignore` 差分
- 統合レビュー: `npm run lint:md` 実行成功、後方互換確認の網羅性
