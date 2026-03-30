# Unit 002: rules.md 不整合修正 - 計画

## 概要

.aidlc/rules.md の3点の不整合（境界ルール・レビュー種別・aidlc-setup同期）を修正する。

## 変更対象ファイル

- `.aidlc/rules.md`（3箇所の修正）

## 修正内容

### 1. docs/development/ 参照と境界ルールの矛盾

**現状**: 「開発者向けドキュメント」セクション（行382-384）で `docs/development/dependency-commands.md` を参照しているが、ファイル参照境界ルールの許可パスに `docs/**` が含まれていない。

**修正**: 許可パス一覧に `docs/development/**` を追加（read権限）。メタ開発向けドキュメントとして限定的に許可。

### 2. AIレビュー種別テーブルに inception が欠落

**現状**: 「AIレビューツールの使用ルール」セクション（行228-229）のレビュー種別テーブルに code / architecture / security のみ記載。review-flow.md には inception も定義されている。

**修正**: テーブルに `inception | skill="reviewing-inception"` を追加。

### 3. aidlc-setup同期セクションの不存在

**現状**: カスタムワークフロー内で「aidlc-setup同期の前に」と参照されているが、既に「aidlc-setup同期【重要】」の見出しと手順が行147-157に存在する。内容の確認・補完のみ。

**修正**: 既存セクションの内容を確認し、参照と整合していることを確認。不足があれば補完。

## 完了条件チェックリスト

- [ ] docs/development/ 参照と境界ルールの整合性修正
- [ ] AIレビュー種別テーブルに inception を追加
- [ ] aidlc-setup同期の見出し整備と同期手順の確認・補完
