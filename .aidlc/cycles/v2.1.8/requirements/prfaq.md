# PRFAQ: AI-DLC設定体系の整理と安定性向上

## プレスリリース

**AI-DLC Starter Kit v2.1.8 — 設定体系の統合と環境互換性の向上**

AI-DLC Starter Kit v2.1.8では、Git関連の設定キーを `[rules.git]` セクションに統合し、設定ファイルの見通しを大幅に改善しました。これまで `rules.branch`, `rules.worktree`, `rules.unit_branch`, `rules.squash`, `rules.commit` の5つのセクションに分散していた設定が、1つのセクションで一元管理できるようになります。

また、`.aidlc/rules.md` と `.aidlc/operations.md` の内容を整理し、設定的な項目と手順的な記述を明確に分離。さらに、dasel v3環境でのセットアップ時バージョン比較エラーを修正し、環境互換性を向上させました。

旧キー形式との後方互換性は維持されるため、既存のconfig.toml設定はそのまま動作します。

## FAQ

### Q: 既存のconfig.tomlを書き換える必要がありますか？
A: いいえ。旧キー形式（`rules.branch.mode` 等）はフォールバックで引き続き動作します。ただし、新規プロジェクトでは新キー形式（`rules.git.*`）の使用を推奨します。

### Q: dasel v2でも引き続き動作しますか？
A: はい。v2/v3の両方で動作するように更新されています。

### Q: `.aidlc/rules.md` の内容はどう変わりますか？
A: config.tomlで管理可能な設定的項目は移行され、rules.mdにはプロジェクト固有のガイドラインや手順説明のみが残ります。
