# PRFAQ: doctor 完全診断化（`[phase]` / `[trace]` 領域追加）

## Press Release（プレスリリース）

**見出し**: AI-DLC v3 の `doctor` が「フェーズ」と「トレース整合」まで診断 — 着手前チェックが完全診断に

**副見出し**: v3.0.0-alpha.8 で `doctor` に `[phase]` / `[trace]` の 2 領域を追加し、9 領域の shallow 診断から 11 領域の完全診断へ拡張しました。

**発表日**: 2026-06-30（v3.0.0-alpha.8）

**本文**:

[背景] v3 診断コマンド `doctor` は alpha.7（Phase 6）で config / state / cycle / work-items / git / gh / pr / scripts + parse-guard の shallow 診断（9 領域）を実装しましたが、「今どのフェーズに居るか（フェーズ導出の整合）」と「intent → work items → designs の参照が揃っているか（trace 整合）」の 2 領域は、フェーズ導出ロジックと cross-artifact 検証の code 化が必要なため alpha.8 へ意図的に defer していました。この 2 領域が未実装のままでは、状態と work item の組み合わせから導かれるフェーズの不整合や、design の欠落を着手前に検出できず、release 直前まで問題が顕在化しないリスクが残ります。

[プロダクト] `doctor` に `[phase]` と `[trace]` を追加しました。`[phase]` は `data-model.md §5` のフェーズ導出規則（define / develop / release 可能 / complete）を code 化し、現在のフェーズを導出根拠付きで表示します（例: `[phase]  OK  develop (derived: define_completed=true, 2 items remaining)`）。`[trace]` は `data-model.md §8` の size×depth_level マトリクスに基づき、design が必須の work item に対応する design ファイルの存在を確認し、欠落を WARN で報告します。いずれも read-only（状態を一切変更しない）で、既存の診断スクリプトを再利用します。

[顧客の声] 「`doctor` 一発で環境・状態だけでなく、フェーズの導出根拠と design の揃い具合まで分かるようになり、着手前の安心感が増した」「フェーズ導出が SoT と一致しているか機械的に確認できるので、状態管理のミスに気づきやすい」。

[今後の展開] 本リリースで doctor が完全診断（11 領域）となり、Epic #736 Phase 6 が真に完了します。次は Phase 7（dogfooding + 本流化 / `skills/aidlc-v3 → skills/aidlc` 置換 / marketplace v3.0.0 化 / v2→v3 migration）へ進み、`/aidlc` = v3 を実現します。

## FAQ（よくある質問）

### Q1: `doctor` はフェーズや状態を書き換えますか？
A: いいえ。`doctor` は read-only の診断のみで、state.json / work item / config を一切変更しません。`[phase]` / `[trace]` も同じ原則を維持し、問題を検出・案内するだけで自動修正はしません。

### Q2: `[phase]` の `complete` はどう判定しますか？
A: `data-model.md §5.1` の評価順1に従い、`release.merge_approved=true`（承認記録）かつ PR が実際に merged 状態の両方が揃ったときのみ `complete` を導出します。gh 利用不可 / PR 番号 null / 取得失敗のいずれかで確認できない場合は `complete` とせず、評価順2以降（develop / release 可能）にフォールバックし、不一致を WARN で併記します。

### Q3: `[trace]` はどこまで見ますか？
A: 本サイクルでは「design が必須の work item に対応する design ファイルが存在するか」の確認に限定します。design 要否は `data-model.md §8` の size×depth_level マトリクスが正本です（`normal × standard` / `normal × comprehensive` / `risky × standard` / `risky × comprehensive` は必須、`tiny × *` / `normal × minimal` は不要、`risky × minimal` は不正組み合わせとして WARN）。intent refs や Traceability セクションの意味検証、dependencies 実在検証（既存 `[work-items]` が担当）は本サイクルの範囲外です。

### Q4: 既存の `[work-items]` 領域と重複しませんか？
A: 重複しません。`[work-items]`（と `work-item-validate.sh`）は dependencies の実在検証などを担い、`[trace]` は cross-artifact trace（design ファイルの存在）に焦点を当てます。役割分担を `doctor.md` に明示します。

### Q5: このサイクルのスコープ外は何ですか？
A: doctor の自動修正機能、`[phase]` / `[trace]` 以外の新規領域、フェーズ導出規則そのものの仕様変更、trace chain 後段（reviews / journal / release / reflect）の診断、Phase 7 本流化、他のオープン backlog（#740 等）は含みません。

### Q6: テストはどう担保しますか？
A: `test-doctor.sh`（自己完結ハーネス / jq 前提 / ネットワーク非依存）を拡張し、`[phase]` の各導出ケースと WARN 異常系、`[trace]` の各ケース（design 必須×存在/欠落、不要、`risky × minimal`、depth_level 未設定→standard）を契約テストで検証し、「全領域 OK」正常系を 11 領域へ拡張します。
