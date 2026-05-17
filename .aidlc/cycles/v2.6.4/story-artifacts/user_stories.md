# ユーザーストーリー - v2.6.4

## Epic: AI-DLC スターターキットの SoT 整備・セキュリティ強化・運用基盤統一

本サイクルは「Operations Phase マージ前フローの SoT 化（#694）」「振り返りスキルの opt-in 基盤導入（#710 / patch サブセット）」「markdown lint 実行手段の統一化（#709）」「`operations-release.sh` への `validate_cycle` 検証拡張（#708）」の 4 軸で構成される patch リリース。Issue 単位での独立完了が可能。

---

### ストーリー 1: Operations Phase マージ前 CI 通過確認 + 修復フローの SoT 化（#694）

**優先順位**: Must-have

As a AI-DLC スターターキットを利用する開発者（consumer プロジェクトのメンテナ）
I want to Operations Phase のマージ前ステップで「CI 通過確認 + 失敗時修復経路 + `check-cycle-phase-completion` 常時実行」が SoT として明文化されている状態
So that 各サイクルで属人的に対応していたマージ前 CI 修復を、サイクル横断で同じ手順で再現できる

**受け入れ基準**:

- [ ] `skills/aidlc/steps/operations/` 配下のマージ前ステップファイル（該当ステップ）に以下 3 セクションが SoT として追加されている:
  - [ ] **マージ前 CI 通過確認**: `gh pr checks <PR>` または `gh run list --branch <branch>` を使った全 CI ジョブ通過確認手順
  - [ ] **CI 失敗時の修復経路**: (a) 修復可能（テスト修正・コード修正）= 通常修正コミット → 再 push → CI 再確認、(b) 修復不能（環境依存・flaky）= マージブロック解除前にユーザー承認必須（`AskUserQuestion`）、(c) 構造的不整合（Unit 跨ぎ）= サイクル内修正として扱い、新規 Issue 化せず（マージ後の振り返り Try で記録）
  - [ ] **`check-cycle-phase-completion` の常時実行**: マージ前ステップで明示的に呼び出すよう SoT 化
- [ ] 関連スキル（`aidlc:reviewing-operations-premerge` 等）との重複・補完関係が明示されている
- [ ] 既存ステップ参照経路に破壊なし（`grep -rn "steps/operations/" skills/` で参照先パスが既存通り）

**技術的考慮事項**:

- 配布物 baseline 規約遵守（SoT セクションを正本とし、他ドキュメントは参照に留める）
- ドッグフーディング特殊処理禁止（starter kit 自身か consumer かを判定する分岐を埋め込まない）

---

### ストーリー 2: `operations-release.sh` への `validate_cycle` 検証拡張（#708）

**優先順位**: Must-have（`cmd_record_release_prep_commit` 必須） / Should-have（`cmd_pr_ready` 条件付き）

As a AI-DLC スターターキットのメンテナ / セキュリティ担当者
I want to `operations-release.sh` の `--cycle` 受け取りサブコマンドに対して、`validate_cycle`（`skills/aidlc/scripts/lib/validate.sh`）による包括的バリデーションが導入されている状態
So that v2.6.3 Unit 002 で `cmd_squash_712` のみに導入されていた `--cycle` 検証をパストラバーサル経路のあるサブコマンドにも網羅的に拡張でき、攻撃面を段階的に縮小できる

**受け入れ基準**:

- [ ] `cmd_record_release_prep_commit` に `validate_cycle` 検証が導入されている（必須）
  - [ ] `--cycle` 引数のパストラバーサル文字列（`../`, 絶対パス, 制御文字等）が `validate_cycle` で拒否される
  - [ ] 新規 bats テストが追加され pass する（不正値 / 正常値の境界ケース網羅）
- [ ] `cmd_pr_ready` の `--cycle` 経路について影響範囲調査が実施されている（条件付き）
  - [ ] 下流（`pr-ops.sh get-related-issues "$cycle"` 等）で `--cycle` がパス展開に使われるかが調査され、結果が `inception/decisions.md` に記録される
  - [ ] 調査結果に基づき、同サイクル内で `validate_cycle` 導入 / 別 Issue 化のいずれかを判定し、実施または defer 記録する
- [ ] 既存 bats 群（`tests/migration/*.bats` 含む）に回帰なし
- [ ] 既存呼び出し経路（CI / Operations Phase ステップから呼ぶ箇所）の引数形式は不変

**技術的考慮事項**:

- v2.6.3 Unit 002 で導入された `cmd_squash_712` の検証パターンを踏襲
- `printf -v` 系 result-out 関数を新規導入する場合は v2.6.3 で追加された namespace 規約（`_local_<関数省略名>_<名>`）に従う
- AI エージェント Bash ツール経由の安全パターン遵守（コマンド置換禁止）

---

### ストーリー 3: markdown lint 実行手段の統一エントリポイント化（#709）

**優先順位**: Should-have

As a AI レビューを実行する開発者・AI エージェント（codex / Claude Code 等）
I want to repo 全体の markdown lint を `npm run lint:md` で実行できる統一エントリポイントが提供されている状態
So that AI レビュー / CI / ローカル開発で同一コマンド・同一バイナリ・同一設定を参照して lint を実行でき、外部レビュー環境での「`command not found` 再現エラー」を回避できる

**受け入れ基準**:

- [ ] `package.json` の `scripts.lint:md` に統一エントリポイントが定義されている（正本）
  - [ ] `npm run lint:md` 実行で既存の `npx markdownlint-cli2` 直接呼び出しと同じ動作になる（同一の markdownlint バイナリ・同一の設定ファイルを参照）
- [ ] `Makefile` ラッパーは任意（必要時のみ追加）。本サイクルでは `package.json` 側の整備までを必須とする
- [ ] 既存の `npx markdownlint-cli2 ...` 直接呼び出しは廃止せず、`lint:md` から委譲する形を選択する
- [ ] AI レビュー手順書（`steps/common/review-flow.md` 等）に統一コマンド `npm run lint:md` の使用が明記されている
- [ ] markdownlint で新規エラー 0 件

**技術的考慮事項**:

- 既存の `npx markdownlint-cli2` 呼び出し経路を破壊しない（後方互換）
- consumer プロジェクトが Node エコシステム外（pure shell プロジェクト等）でも基本動作を阻害しない設計とする

---

### ストーリー 4: 振り返りスキル `aidlc-retrospective` の opt-in 基盤導入 + 後方互換確保（#710 / patch サブセット）

**優先順位**: Should-have

As a AI-DLC スターターキットのメンテナ
I want to 振り返りスキル `aidlc-retrospective` の Issue 起票方針を「振り返り単位の自動起票（現行）」から「Try/改善単位での個別起票（将来）」へ段階的に移行するための opt-in 基盤と後方互換確保が patch スコープで導入されている状態
So that v2.7.0+ で予定されている本格的な再設計（自動起票完全廃止 / `Retrospective:` タイトル運用見直し）に向けて、既存ガード（対話必須トークン / cap / mirror）の動作を破壊することなく段階的改修を進められる

**受け入れ基準**:

- [ ] 振り返り Issue 必須起票の opt-in 化基盤が導入されている
  - [ ] config フラグ（例: `[rules.retrospective].auto_issue_creation` または同等の設定キー）で「振り返り集約 Issue を作成する / しない」を切り替えられる
  - [ ] **デフォルト値での挙動不変**: デフォルト値は現行動作互換（=作成する）に固定し、デフォルト設定のままでは consumer プロジェクトの挙動は一切変わらない
  - [ ] **`false` 経路の実装方針**: `false` 経路を実装するが既定では未発火（明示的に `config.toml` で `false` を設定したユーザーだけが新経路を体験）
- [ ] `predecessor_resolve_issue`（`skills/aidlc/scripts/lib/predecessor-issue.sh`）の 5 経路解決が現状通り動作する後方互換確保（**5 経路の必須チェック手順** = テスト用 cycle で各経路の状況を再現し、`resolution_path` 出力が想定値と一致することを確認。詳細手順は Unit 004 の責務節を参照）
- [ ] `aidlc-retrospective` の既存ガード（対話必須トークン / cap 判定 / mirror 送信判断）の挙動が破壊されていないことを、Unit 004 で定義する **3 ガードの必須チェック手順**（各ガードの再現入力・期待動作・判定条件を固定）で確認
- [ ] 本サイクル対象外項目を関連スキルのドキュメント（SKILL.md / steps 配下）に明示記載し、v2.7.0+ で対応する旨を defer 記録（**対象外**: 振り返り Issue 自動起票の完全廃止 / `Retrospective: {cycle}` タイトル運用見直し / 振り返り Issue API の破壊的変更）

**技術的考慮事項**:

- SKILL.md 本文 500 行制限を超えないこと
- 既存 5 経路解決の後方互換は最優先（既存サイクルの振り返り Issue 検索が動かなくなるのは患者の生死に関わる）
- AI エージェント Bash ツール経由の安全パターン遵守
