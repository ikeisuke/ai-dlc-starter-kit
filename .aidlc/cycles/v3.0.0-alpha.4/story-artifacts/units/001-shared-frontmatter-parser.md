# Unit: 共有 frontmatter parser ライブラリ集約 + conformance test（T1 + T2'）

## 概要

`skills/aidlc-v3/` の frontmatter パース（スカラー抽出 / dependencies 配列 / frontmatter ブロック抽出 + malformed guard）を `scripts/lib/` の単一共有ライブラリに集約し、3 consumer（validate / next / status）を移行する。あわせて、移行が既存の受理/拒否境界を壊さないことを保証する conformance test suite を整備し、個別構造解釈を禁止する規約を明文化する。リファクタ（T1）とその behavior-preservation を保証する実行可能契約（T2'）を1つの独立検証可能ブロックとして扱う。

## 含まれるユーザーストーリー

- ストーリー 1: 共有 frontmatter parser ライブラリへの集約（T1）
- ストーリー 2: conformance test suite による受理/拒否境界の固定（T2'）

## 責務

- `skills/aidlc-v3/scripts/lib/` への共有 frontmatter parser ライブラリ新設（スカラー抽出 / dependencies 配列パース / frontmatter ブロック抽出 + malformed guard / 拒否理由標準化）
- `work-item-validate.sh` / `work-item-next.sh` / `work-item-status.sh` の個別パース実装撤去 + 共有ライブラリ source への移行
- 共有 parser API の責務境界と「個別 consumer での frontmatter 構造解釈禁止」規約の文書化
- conformance test suite（受理/拒否 fixture）の追加と、3 consumer の同一 fixture 検証
- Unit 完了条件「新たな構造データ読取は共有 parser 使用 + conformance fixture 追加必須」の規約組み込み

## 境界

- **扱わない**: `state-*.sh`（JSON / jq）のパース再設計（schema 検証は state-validate.sh に集約済み / #731）。必要な場合も整合確認・既存テスト維持のみ
- **扱わない**: 禁止パターンの CI 機械検出（Unit 002 / T4）。本 Unit は規約の文書化までで、自動検出の実装は含まない
- **扱わない**: cycle 解決ロジック（Unit 003 / T6）
- **扱わない**: 受理/拒否境界の変更（純粋リファクタ）。ただし #733 既知 malformed クラスは拒否 fixture として明示固定する（意図的拒否強化の範囲）

## 依存関係

### 依存する Unit

- なし（共有ライブラリの基盤となる最初の Unit）

### 外部依存

- bash（3.2/4.0+ 互換）、grep/sed/awk/tr（共有ライブラリ内部での使用は許可）、git（テストハーネス前提）

## 非機能要件（NFR）

- **パフォーマンス**: 共有化による顕著な実行時間増を招かない（既存と同等オーダー）
- **セキュリティ**: 特になし（ローカル parser）
- **スケーラビリティ**: release / reflect / doctor 等の将来 consumer が同一ライブラリを source できる拡張性
- **可用性**: 既存テスト緑を維持（回帰なし）

## 技術的考慮事項

- dynamic scope namespace 化（関数固有プレフィックス）を踏襲。`printf -v` result-out 関数は CLAUDE.md の local 命名規約（`_local_<fn>_<name>`）に従う
- enum 検証の要否（validate=厳格 / next=最小 / status=専用）を引数または関数分割で表現し、3 consumer の既存挙動を保存
- conformance test は既存 `put_wi()` / 自己完結型ハーネス形式を再利用

## 関連Issue

- #733（部分対応）（v3.0.0系 通し振り返り / T1 + T2' の出典。本 Unit は #733 の T1/T2' のみ対応のため Closes ではなく Relates）

## 実装優先度

High

## 見積もり

中（共有ライブラリ設計 + 3 consumer 移行 + conformance test。設計フェーズ Phase 1 を要する規模）

---
## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
- **エクスプレス適格性**: -
- **適格性理由**: -
