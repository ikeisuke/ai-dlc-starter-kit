# Intent（開発意図）

## プロジェクト名

ai-dlc-starter-kit v2.6.4（patch サイクル）

## 開発の目的

v2.6.3 サイクルの振り返り由来 Issue（#694）および直近のレビュー / フィードバックから抽出された backlog Issue（#710 / #709 / #708）を解決し、AI-DLC スターターキットの「Operations Phase マージ前フローの SoT 化」「振り返りスキルの起票粒度見直し（段階的改修の前段）」「lint 実行手段の統一化」「`operations-release.sh` のセキュリティ強化拡張」を patch レベルで底上げする。新機能追加は行わず、既知の改善点・SoT 未整備領域・セキュリティ拡張余地の構造的解消に焦点を当てる。

## ターゲットユーザー

- AI-DLC スターターキットを利用する開発者（consumer プロジェクト）
- スターターキット自体をドッグフーディングで開発するメンテナ
- AI エージェント（Claude Code / Codex CLI 等）— 規約・手順の SoT を参照する実行主体

## ビジネス価値

- **マージ前フローの再現性向上**: 属人的だったマージ前 CI 通過確認 + 失敗時修復経路を SoT 化し、サイクル横断で再現可能にする（#694）
- **振り返り運用の柔軟化（段階的改修の前段）**: 振り返り Issue の必須起票を opt-in 化する基盤を整え、Try/改善単位の起票運用への移行を可能にする（#710 / patch スコープ範囲）
- **レビュー / CI / ローカル統一**: markdown lint コマンドを統一エントリポイント化し、外部レビュー（codex）環境での再現性を担保する（#709）
- **セキュリティ強化の段階的拡張**: v2.6.4 では `operations-release.sh` のうち `cmd_record_release_prep_commit`（パストラバーサル経路あり / 必須）に `validate_cycle` を導入して既知の必須経路を閉じ、`cmd_pr_ready` は Construction Phase の影響範囲調査結果に基づき同サイクル内対応または別 Issue 化を判定する（#708）

## 含まれるもの

本サイクルで対応する 4 件の Issue:

| Issue | 種別 | 内容 |
|-------|------|------|
| #694 | docs | Operations Phase マージ前ステップに「CI 通過確認 + 失敗時修復経路 + `check-cycle-phase-completion` 常時実行」フローを SoT 化（`steps/operations/*` 配下に明文化） |
| #710 | refactor | 振り返りスキル `aidlc-retrospective` の Issue 起票方針見直し — patch スコープでは段階的改修の前段として「振り返り Issue 必須起票の opt-in 化基盤導入」「`predecessor_resolve_issue` の後方互換確保」までを実施。デフォルト動作（既存ガード / cap / mirror）は不変 |
| #709 | chore | repo 全体の markdown lint 実行手段を統一化。**正本は `package.json` の `scripts.lint:md`**（npm エコシステム既存のため）。`Makefile` ラッパーは任意 / 必要時のみ追加。AI レビュー / CI / ローカル開発で `npm run lint:md` を統一エントリポイントとする |
| #708 | security | `operations-release.sh` の `--cycle` 受け取りサブコマンドへの `validate_cycle` 検証導入 + 新規 bats テスト追加。**必須対応**: `cmd_record_release_prep_commit`（パストラバーサル経路あり）。**条件付き対応**: `cmd_pr_ready`（Construction Phase で下流の `--cycle` がパス展開に使われるかの影響範囲調査を実施し、調査結果に基づき同サイクル内対応 / 別 Issue 化を判定） |

各 Issue の完了判定は **「v2.6.4 範囲で本 Intent が定義したサブセット受入基準」を SoT** とする（Issue 本文の受入基準は参考情報として扱うが、本サイクルでは Intent のサブセット定義が優先される）。これにより以下 2 件は本サイクルの完了基準として「Issue 本文全体」ではなく **「Intent 内サブセット」** で判定する:

- **#710**: 「振り返り Issue 必須起票の opt-in 化基盤導入」「`predecessor_resolve_issue` の 5 経路解決の後方互換確保」までを v2.6.4 サブセットとする（破壊的変更 = 自動起票完全廃止 / `Retrospective:` タイトル運用見直し / API 破壊的変更 = v2.7.0+ に明示除外）
- **#708**: 「`cmd_record_release_prep_commit` への `validate_cycle` 検証導入 + bats テスト追加」を v2.6.4 サブセットの必須項目とし、`cmd_pr_ready` は条件付き対応（影響範囲調査結果次第）

#709 / #694 は Issue 本文の受入基準を完全充足する（サブセット適用なし）。本 Intent では各 Issue の対応内容を上表で 1 行ずつ要約するに留め、受け入れ基準の細目化・チェック項目の確定は Inception Phase のユーザーストーリー / Unit 定義および Construction Phase の実装計画で行う（AI-DLC のフェーズ分業に従う）。

## 明示的に除外するもの

- #710 のうち **「振り返り Issue 自動起票の完全廃止」「`Retrospective: {cycle}` タイトル運用の本格的見直し」「振り返り Issue API の破壊的変更」は本サイクル対象外**（minor リリース v2.7.0 以降で実施）。本サイクルは opt-in 基盤の導入と後方互換確保までに限定する
- 新機能追加（feature 系 Issue: #700 / #685 / #666 / #664 等）は minor 相当のため対象外
- #694 の関連検討項目（`steps/common/preflight.md` への CI 状態確認組み込み）は本 Issue 本文で「検討」とされており、必須ではないため別 Issue 化を許容（**分離判定基準**: 以下のいずれかに該当する波及変更は別 Issue 化する — (a) 当該 Issue の受け入れ基準を満たすために必須でない変更、(b) patch スコープ（バグ修正・規約整備・docs・refactor・security）を超える変更、(c) 影響範囲が当該 Issue の責務境界を越え、他 Issue の受け入れ基準に影響する変更）
- `cmd_pr_ready` への `validate_cycle` 適用（#708 内 priority: low）の扱いは Construction Phase で「下流で `--cycle` がパス展開に使われるかの影響範囲調査」を行ったうえで判定する（必須対応は `cmd_record_release_prep_commit` のみ、`cmd_pr_ready` は影響範囲確認の上で判断）

## 成功基準

- **4 件すべての Issue について「v2.6.4 範囲で定義した受入基準（サブセット）」を満たす変更が完了している**
- `aidlc-retrospective` の既存テスト・既存ガード（対話必須トークン / cap / mirror）の動作が破壊されていない（#710）
- `operations-release.sh` の新規 bats テスト（`cmd_record_release_prep_commit` の `validate_cycle` 検証 / 必須）が pass し、既存 bats 群に回帰がない（#708）
- markdownlint で新規エラー 0 件 + 統一エントリポイント `npm run lint:md` が AI レビュー / CI / ローカルで同一動作する（同一の markdownlint バイナリ・同一の設定ファイルを参照する）（#709）
- `steps/operations/*` のマージ前ステップに「CI 通過確認 + 失敗時修復経路 + `check-cycle-phase-completion` 常時実行」が SoT として明記されている（#694）
- **互換性の観測点（具体）**:
  - **#710**: `predecessor_resolve_issue` の 5 経路解決（経路 1 milestone+label / 1' label fallback / 2 spool fallback / 3 v2.5.0 互換 / 4 warn+continue）について、既存の各経路が現状通り選択され、`resolution_path` 出力が変わらないこと（既存 bats テストがあれば pass、なければ手動再現で確認）
  - **#710**: `aidlc-retrospective` の既存「対話必須トークン / cap 判定 / mirror 送信判断」の挙動が変わらないこと（既存ガード機構の手動再現で確認）
  - **#694**: `steps/operations/*` の既存ステップ参照経路（他ドキュメントからの相対パス参照・スキル間参照）に破壊なし — `grep -rn "steps/operations/" skills/` で参照先パスが既存通りであることを確認
- 各 Issue が PR で参照・クローズされる

## 期限とマイルストーン

- 単一サイクル（v2.6.4）内で完結
- Inception → Construction → Operations の標準フロー
- Milestone: v2.6.4（`05-completion` で作成・4 Issue を紐付け）

## 制約事項

- **配布物 baseline 規約の遵守**: 規約追記（#694）は SoT セクション（`steps/operations/*` の該当ファイル）を正本とし、他ドキュメントは参照に留める
- **ドッグフーディング特殊処理の禁止**: 本体スクリプト・ライブラリに「starter kit 自身か consumer か」を判定する分岐を埋め込まない（CLAUDE.md 設計原則）
- **後方互換性**: `aidlc-retrospective` 改修（#710）は既存 `predecessor_resolve_issue` の 5 経路解決を破壊しない / デフォルト動作不変。`operations-release.sh` 改修（#708）は既存呼び出し経路の引数形式を変えない。`lint:md` 統一化（#709）は既存の `npx markdownlint-cli2` 直接呼び出しを廃止せず、統一エントリポイントから委譲する形を選択する
- **SKILL.md 本文 500 行制限**: 関連スキル（`aidlc-retrospective` / `aidlc` / Operations Phase 関連）の SKILL.md / index.md 改訂は本文行数制限を超えないこと
- **AI エージェント Bash ツール経由の安全パターン**: 全作業でコマンド置換（`$(...)` / backtick）を Bash ツール引数文字列に含めない
- **`printf -v` 系 result-out 関数の local 命名規約**: 該当パターンを新規導入する場合は v2.6.3 で追加された namespace 規約（`_local_<関数省略名>_<名>`）に従う

## 不明点と質問（Inception Phase中に記録）

[Question] #710 は本文で「minor リリース（v2.7.0 以降）を想定」と明記されているが、本サイクル（patch）では「段階的改修の前段」として opt-in 基盤導入 + 後方互換確保までを実施する方針でよいか
[Answer] ユーザーは v2.6.4 (patch) を選択し、かつ #710 をスコープ含めることを明示選択した。Intent では本サイクルを「段階的改修の前段」と位置付け、破壊的変更（自動起票完全廃止 / Retrospective: タイトル運用の見直し）は v2.7.0+ に明示除外する制約を加えることで合意とする。Construction Phase の Unit 設計時に opt-in 基盤の具体的設計を確定する。
