# Unit 7: 複数人開発時コンフリクト対策 - 実装計画

## 概要

history.md と backlog.md の複数人開発時コンフリクトを防ぐためのプロンプト・ルール更新。

## ユーザーストーリー

- **ストーリー9**: history.mdコンフリクト対策
- **ストーリー10**: backlog.mdコンフリクト対策

## 対応方針

### history.md
**方針: ファイル分割（フェーズ/Unit単位）**

```
docs/cycles/v1.4.0/history/
  ├── inception.md
  ├── construction_unit1.md
  ├── construction_unit2.md
  ├── construction_unit3.md
  └── operations.md
```

- 各フェーズ/Unitは基本1人が担当するのでコンフリクトしない
- 同じUnit内で複数人作業ならUnit分割すべき
- タイムスタンプ不要でシンプル

### backlog.md
**方針: 共通バックログをファイル分割、サイクルバックログは廃止**

```
docs/cycles/backlog/
  ├── feature-context-reset-proposal.md
  ├── chore-setup-phase.md
  ├── docs-unit-format-update.md
  └── ...
```

**種類（prefix）**:
- `feature-` : 新機能
- `bugfix-` : バグ修正
- `chore-` : メンテナンス・雑務
- `refactor-` : リファクタリング
- `docs-` : ドキュメント改善
- `perf-` : パフォーマンス
- `security-` : セキュリティ

**変更点**:
- 共通バックログ（`docs/cycles/backlog/`）に統一
- サイクル固有バックログ（`docs/cycles/v1.4.0/backlog.md`）は廃止
- 1気づき1ファイルでコンフリクト回避
- 日付はファイル内メタデータで管理
- サイクル完了時の移行処理も不要（シンプル化）

## 実装ステップ

### Phase 1: 設計（対話形式）

1. **ドメインモデル設計**
   - history/backlog の新ファイル構造を設計
   - 既存データの移行方針を決定
   - 成果物: `docs/cycles/v1.4.0/design-artifacts/domain-models/unit7_domain_model.md`

2. **論理設計**
   - 更新対象プロンプト・テンプレートのリストアップ
   - 変更内容の詳細設計
   - 成果物: `docs/cycles/v1.4.0/design-artifacts/logical-designs/unit7_logical_design.md`

3. **設計レビュー**
   - ユーザー承認を得る

### Phase 2: 実装

4. **コード生成**（プロンプト・ルール更新）
   - `prompts/package/prompts/construction.md`: history関連の変更
   - `prompts/package/prompts/operations.md`: history関連の変更
   - `prompts/package/prompts/inception.md`: backlog関連の変更
   - `prompts/package/setup-cycle.md`: history/backlogディレクトリ作成、サイクルbacklog廃止
   - テンプレート更新

5. **テスト生成**
   - 変更後のプロンプトが正しく動作するか確認

6. **統合とレビュー**
   - 既存ドキュメントとの整合性確認
   - 実装記録の作成

## 成果物

- `docs/cycles/v1.4.0/design-artifacts/domain-models/unit7_domain_model.md`
- `docs/cycles/v1.4.0/design-artifacts/logical-designs/unit7_logical_design.md`
- `docs/cycles/v1.4.0/construction/units/unit7_implementation.md`
- `prompts/package/` 配下の該当ファイル更新

## 完了基準

- [ ] history分割方式のプロンプト更新完了
- [ ] backlog分割方式のプロンプト更新完了（共通バックログに統一）
- [ ] テンプレート更新完了
- [ ] 既存ドキュメントとの整合性確認済み
- [ ] 実装記録作成済み

---

作成日: 2025-12-14
更新日: 2025-12-14（方針決定: ファイル分割方式、サイクルバックログ廃止）
