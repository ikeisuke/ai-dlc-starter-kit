---
id: "003"
status: done
size: risky
risk: high
assigned: null
dependencies: ["001"]
---

# Work Item 003: v2 → v3 migration 実装（new-cycle-only + archive-only）

## Goal

v2 consumer が `docs/v3/migration.md` の方針に沿って v3 へ移行できる実装を提供する（Epic #736 7-c）。推奨モード new-cycle-only（v2 config 読み込み → v3 config 生成 + state.json 初期化 / 過去資産は残置）を必須実装とし、archive-only（v2 cycles の所在 index 生成のみ）を併せて実装する。

## Scope

- 含むもの: v2 config.toml 読み込み → v3 config.toml 生成（キーマッピング + 未サポートキーの警告 / エラーにしない）、移行モード選択の人間確認ゲート、変換結果の人間確認ゲート、state.json 初期化（既存 state-init.sh の再利用を優先）、archive-only の index 生成、片方向移行（rollback 不可）警告の明示、テスト（v2 config 世代差フィクスチャを含む）、実装配置（新規スキル or 既存 aidlc-migrate 拡張）の設計判断
- 含まないもの: best-effort モードの実データ変換（units → work-items / progress → state.json / history → journal）→ 後続サイクルへ defer、v2 runtime 互換の維持、v2 EOL の運用実施

## Acceptance Criteria

- [ ] new-cycle-only migration が実行可能である（v2 config → v3 config 生成 + state.json 初期化 + モード選択・変換結果確認の人間ゲート）
- [ ] archive-only migration が実行可能である（v2 cycles の所在 index 生成 / 内容変換なし）
- [ ] 未サポートの v2 config キーは警告され、エラーにならない（migration.md 非互換点 #3 と整合）
- [ ] 片方向移行（rollback 不可）の警告が実行時に明示される
- [ ] best-effort モードは未実装である旨が案内され、選択すると安全に中断する
- [ ] v2 config の世代差フィクスチャを含むテストが pass し、shellcheck / parse-guard が green である

## Traceability

- Intent refs: scope:7-c v2 → v3 migration 実装
- Acceptance refs: AC-3, AC-4, AC-5, AC-6
- Verification: migration テストスイート実行 + 本リポジトリの v2 形式 config を入力とした new-cycle-only のローカル実行確認
- Release note required: yes（7-c マイルストーン / consumer 向け移行手段の提供）

## Size / Risk

- Size: risky
- Risk: high
- Reason: renewal-plan の risky 昇格条件「migration → 自動的に risky」に該当する。片方向移行（rollback 不可）で失敗時の影響が大きく、design + 厚いレビューを必須とする

## Dependencies

- 001（v3 config.toml の終端キー集合が config 変換の変換先 schema となるため）
