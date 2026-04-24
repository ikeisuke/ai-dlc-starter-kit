# PRFAQ: AI-DLC Starter Kit v2.4.0

## Press Release（プレスリリース）

**見出し**: AI-DLC Starter Kit v2.4.0 — サイクル管理を GitHub Milestone 運用へ本採用、メタ開発時の整合性バグも同時解消

**副見出し**: 90 件超蓄積した `cycle:v*` ラベル運用を GitHub Milestone ベースへ正式移行。Inception/Operations フローに Milestone 作成・close 手順を組み込み、進捗バーと close 状態でサイクル進行が一目で把握できる。あわせてメタ開発時のバージョン三角検証を妨げていた `update-version.sh` のバグと、関連 Issue を持たないサイクルの PR Ready 化が失敗する bug も解消する。

**発表日**: 2026 年 4 月下旬（v2.4.0 リリース予定）

**本文**:

[背景] AI-DLC サイクル管理はこれまで `cycle:vX.Y.Z` 形式の GitHub ラベルで運用されてきたが、v1.7.2 〜 v2.0.10 まで **90 件超のサイクルラベルが累積**し、ラベル選択 UI のノイズ・持ち越し表現の煩雑さ・進捗可視化の欠如という課題を抱えていた。v2.3.6 で GitHub Milestone ベース運用（Kubernetes/release モデル）を試験運用し、UI 挙動・進捗バー表示・closed 折りたたみが十分実用に耐えると確認。v2.4.0 でこれを **本採用** する。加えて、メタ開発時のバージョン三角検証が機能していない #596 の bug と、関連 Issue を持たないサイクルで `operations-release.sh pr-ready` が `closes_list` 空配列エラーで止まる #588 も同サイクルで解消する。

[プロダクト] v2.4.0 では次のフロー変更が適用される:

1. **Inception Phase**: サイクルバージョン確定時に GitHub Milestone を作成し、対象 backlog / feedback Issue を自動的に紐付ける Markdown 手順（AI/人間が `gh api` を順次実行）が追加される
2. **Operations Phase**: サイクル完了時に対象 PR/Issue の Milestone 紐付けを確認し、Milestone を close する手順が追加される。Milestone 不在時は 4 段階優先順位（closed 1+→停止 / open 2+→停止 / open 1→再利用 / 両方 0→fallback 作成）で判定し fallback で復旧する
3. **ドキュメント**: `docs/configuration.md` / `README.md` / `skills/aidlc/guides/` / `skills/aidlc/rules.md` のサイクル運用記述が Milestone ベースに書き換えられ、旧ラベル運用の併記は残さず過去サイクル追跡は CHANGELOG / `.aidlc/cycles/v*/` / `cycle:v*` ラベル（deprecated 物理残置）で行う
4. **スクリプト**: `cycle-label.sh` / `label-cycle-issues.sh` は deprecated 化（物理削除は後続サイクル）。`bin/update-version.sh` は `.aidlc/config.toml.starter_kit_version` を更新対象から除外し、出力から `aidlc_toml_*` 行を削除（hidden breaking change、CHANGELOG 明記）。`skills/aidlc/scripts/pr-ops.sh` は `closes_list[@]` / `relates_list[@]` の空配列展開を `set -u` 環境で安全化
5. **v2.4.0 サイクル自体の Milestone**: 自己参照回避のため Inception 完了処理の運用タスクとして手動で作成・close（v2.5.0 以降は標準手順が自動適用）

[顧客の声]

- メタ開発者 A 氏: 「`cycle:v*` ラベルが UI から消えてくれて視界がすっきりした。Milestone の進捗バーでどの Issue がまだ残っているかが一目で分かる」
- AI-DLC 利用者 B 氏: 「関連 Issue のないサイクルで pr-ready のスクリプトが落ちなくなったので、毎回手動で `gh pr ready` を叩く必要がなくなった」
- メタ開発者 C 氏: 「`bin/update-version.sh` が `.aidlc/config.toml` を触らなくなったことで、やっとメタ開発リポジトリでもアップグレードモードの試験ができる」

[今後の展開] v2.5.0 以降で、過去 v2 サイクル（v2.0.0〜v2.3.5）の遡及 Milestone 化、v1 系サイクルラベル約 90 件の一括削除、v2 系サイクルラベルの整理（Unit D-F）を段階実施する。Milestone 進捗バッジ（shields.io 等）の README 追加、`starter_kit_version` 代替判定条件（`version.txt` + `.claude-plugin/` ベース等）の追加検討もバックログに登録済み。

## FAQ（よくある質問）

### Q1: v2.3.6 で試験運用した Milestone #1 は削除されますか？

A: いいえ、そのまま維持されます。v2.3.6 試験運用は本採用の一部として継続し、削除・リセットは行いません。

### Q2: 既存の `cycle:v*` ラベルはどうなりますか？

A: v2.4.0 では **deprecated 化のみ**で物理削除は行いません。`cycle-label.sh` / `label-cycle-issues.sh` のスクリプト先頭コメントに DEPRECATED 注記を追加し、フローからの呼び出しは削除します。v1 系ラベル約 90 件の一括削除は blast radius が大きいため、本採用フロー（A-C）の稼働確認後に後続サイクル（Unit E）で段階実施します。

### Q3: v2.4.0 サイクル自身の Milestone はどう作成されますか？

A: Inception 完了時に**手動**で Milestone `v2.4.0` を作成し、対象 Issue（#597 / #595 / #596 / #588）と本サイクル PR を紐付けます。自己参照を避けるため（Unit B で更新する自動 Milestone 作成手順を v2.4.0 自身に適用すると、手順の検証と実使用が二重化してしまう）、本サイクル限定の運用タスク T1 として扱います。v2.5.0 以降のサイクルでは、Unit B の更新済み Markdown 手順が標準手順として自動適用されます。

### Q4: `bin/update-version.sh` の変更は breaking change ですか？

A: はい、hidden breaking change です。スクリプトの出力フォーマット（dry-run / 成功時）から `aidlc_toml_current` / `aidlc_toml_new` / `aidlc_toml:${VERSION}` 行が削除されます。これらの行に依存する自動化や手順書を持つ利用者は v2.4.0 アップグレード時に追従修正が必要です。CHANGELOG の `#596` 節（v2.4.0 リリースノート）に具体的な変更内容を明記します。

### Q5: トークンスコープ制約で `gh issue edit --milestone` が失敗する環境ではどうなりますか？

A: Inception Phase の Milestone 紐付け手順、Operations Phase の close 手順ともに、`gh api --method PATCH repos/OWNER/REPO/issues/NUMBER -F milestone=N` 形式の REST API 直叩きフォールバック手順を明示します（`tools:gh-api-fallback` スキル参照）。`gh api repos/OWNER/REPO/milestones --method POST` と併せて、`gh milestone` サブコマンド非存在の環境でも全操作が REST API 経由で完結します。

### Q6: 持ち越し Issue（サイクルをまたいで対応する Issue）はどう扱われますか？

A: GitHub Milestone の 1 Issue = 1 Milestone 制約に合わせて、「次サイクル Milestone への**付け替え**」または「Backlog（Milestone 未割当）として保持」の 2 択に集約されます。現行ラベル運用の煩雑な「持ち越し表現」が不要になり、運用が単純化されます。

### Q7: 翻訳ドキュメント（`docs/translations/`）への波及はありますか？

A: v2.4.0 では波及対象外です。本サイクルでは `docs/configuration.md` / `README.md` / `skills/aidlc/guides/` / `skills/aidlc/rules.md` の英語 / 日本語 1 次ドキュメントのみ更新します。翻訳ドキュメントへの反映は後続サイクルで別途検討します。
