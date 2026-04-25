# PRFAQ: AI-DLC Starter Kit v2.4.1

## Press Release（プレスリリース）

**見出し**: AI-DLC Starter Kit v2.4.1 — merge/CI フロー堅牢化 + Markdown 手順書明確化 patch リリース

**副見出し**: v2.4.0 以降に発見された 5 件の patch 級 Issue を解消し、Operations 7.13 の `merge_method` 設定保存漏れ・必須 Checks の報告抜け・Construction Squash の誤省略・aidlc-setup 判定の誤判定・Milestone step.md の不明瞭点をまとめて修正します。

**発表日**: 2026-04 リリース予定

**本文**:

**[背景]** v2.4.0 リリース（Milestone 運用本採用）直後、実運用で以下の 5 件の課題が観測されました:

1. Operations Phase 7.13 で `merge_method=ask` + 設定保存を選択すると、`.aidlc/config.toml` の変更が PR に未追従のまま残る（jailrun v0.3.1 で実観測、#601）
2. GitHub Actions の必須 Checks が paths フィルタ非該当や Draft 状態で PASS 報告されず、PR が merge 不可になる（複数案件で発生、#598）
3. Construction Phase の Squash ステップが「【オプション】」ラベルで AI エージェントに誤省略される（visitory プロジェクトで 2 Unit 連続発生、#594）
4. aidlc-setup `01-detect` の複数条件チェックが `&&` 短絡評価で検出漏れを起こす（norigoro で誤判定事例、#600）
5. Milestone 関連 step.md の不明瞭点が構造審査（empirical-prompt-tuning 由来）で検出された（#602）

**[プロダクト]** AI-DLC Starter Kit v2.4.1 は、これら 5 件を 5 つの独立 Unit として並列解消します:

- **Unit 001**: Operations 7.13 にマージ前コミット+push ガードを追加し、3 分岐（コミット+push / follow-up PR / 破棄）の終了条件を手順書に明示
- **Unit 002**: 3 CI workflow に「常に PASS 報告する仕組み」を追加し、paths フィルタ / Draft skip / Draft→Ready 遷移のいずれでも required check を安定化
- **Unit 003**: `commit-flow.md` 冒頭に前提チェックを追加、`04-completion.md` ステップ 7 から「【オプション】」を除去して必須であることを明記
- **Unit 004**: `01-detect.md` に独立チェックの具体コマンド例と `&&`/`||` チェーン禁止の注意書きを追加
- **Unit 005**: Milestone step.md 4 ファイル（`02-preparation.md` §16 / `05-completion.md` §1 / `01-setup.md` §11 / `04-completion.md` §5.5）の不明瞭点を最小修正で解消

いずれも既存機能の後方互換性を保ち、Branch protection 設定の変更は不要です。

**[顧客の声]**

- メタ開発者（AI-DLC Starter Kit 本体の利用者）:
  > 「v2.4.0 で Milestone 運用が本採用になって順調に動いていたが、Operations 7.13 の `merge_method=ask` でハマって手動で follow-up PR を立てる必要があった。v2.4.1 でそこが解消されたのが大きい」
- AI-DLC 利用者（外部プロジェクトで AI-DLC を使う開発者）:
  > 「required check が PR を merge できない状態になる事象に何度か遭遇していたが、workflow 側で対応されて admin override を使わなくて済むようになった」
- AI エージェント（Construction Phase の Squash 対応ケース）:
  > 「手順書から『【オプション】』が消えて、`commit-flow.md` に明示的な前提チェックが入ったので、`squash_enabled=true` の環境でスキップせず実行できるようになった」

**[今後の展開]**

- v2.5.0: Operations 7.13 の根本解決（Inception 側で `merge_method` を事前確定する案A）、#605 aidlc-setup のマージ後 HEAD 同期、#586 progress.md 判定仕様 3 層整合化リファクタを候補として検討
- 2026 年以降: Merge Queue（`merge_group` イベント）への段階移行、AI-DLC 振り返りステップ（#590）、config.toml.template 4 階層設計の整理（#592）

## FAQ（よくある質問）

### Q1: v2.4.1 は v2.4.0 にアップグレード済みの環境にどう影響しますか？
A: 手順書改訂 3 件（Unit 001 / 003 / 004 / 005）は Markdown ドキュメントの更新のみで実行系への影響はありません。Unit 002（CI workflow 変更）は 3 workflow にジョブ/step を追加しますが、既存 check 名を維持するため Branch protection 設定の変更は不要です。

### Q2: `merge_method=ask` を使っていない環境には影響がありますか？
A: Unit 001 の修正は `merge_method=ask` 分岐にのみ追加されるガードです。`merge_method=merge` / `squash` / `rebase` の固定設定を使っている PR には影響しません。

### Q3: Unit 002 の実装は案1（独立報告 job）と案2（既存 job 内 PASS step）のどちらですか？
A: Intent 段階では方針（「常に PASS 報告する仕組み」）のみ固定し、具体実装は Construction Phase の設計レビューで 2 案から選定します。outcome は同一（required check が常に PASS 報告される）です。

### Q4: Squash を行いたくない（`squash_enabled=false`）環境はどうなりますか？
A: Unit 003 の前提チェックは `squash_enabled=false` または未設定時に `squash:skipped:disabled` を返してフローを終了します。現行のスキップ動作と等価で、影響ゼロです。

### Q5: `01-detect.md` の修正で既存の CASE 分類は変わりますか？
A: いいえ。既存の CASE_1 / CASE_2 / CASE_3 の分類ロジックは変更せず、独立評価の指針と具体コマンド例の追加のみです。実装本体にガードを追加する案は patch スコープ外（minor 級の責任分界見直し）として明示的に除外しました（DR-006 記録）。

### Q6: Milestone 機能を opt-out 設定で無効化している環境にはどう影響しますか？
A: Unit 005 は step.md の文書明確化のみで、`[rules.github].milestone_enabled` 設定の扱いは変更しません。`milestone_enabled=false`（既定）の環境では Milestone 関連処理が引き続きスキップされます。Unit 005 の SELECTED_ISSUES 空時の挙動（呼び出し側でスキップ）は `milestone_enabled=true` 環境で初めて作用します。

### Q7: この patch で未対応の backlog Issue は？
A: #605（aidlc-setup のマージ後 HEAD 同期）、#586 / #592 / #590 / #591 などは v2.5.0 以降で段階対応します。詳細は `requirements/intent.md` の「含まれないもの」を参照してください。
