# Unit 001: env-info.shバグ修正

## 対象Issue

- #153

## 概要

env-info.shで`starter_kit_version`と`current_branch`が空になる問題を修正する。

## ユーザーストーリー

開発者として、env-info.shを実行した時に正しい環境情報を取得したい。
なぜなら、セットアップ時の判断に必要な情報だから。

## 受け入れ条件

- [x] starter_kit_versionがdocs/aidlc.tomlから正しく取得される
- [x] current_branchがjj/git環境で正しく取得される
- [x] dasel未インストール環境でもフォールバックが動作する

## 実装状態

- **状態**: 完了
- **開始日**: 2026-02-02
- **完了日**: 2026-02-02
- **担当**: @AI
