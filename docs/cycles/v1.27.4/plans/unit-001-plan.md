# Unit 001 計画: migrate-config警告検出のstdout解析移行

## 概要
aidlc-setup.shのStep 5（設定マイグレーション）で、migrate-config.shの警告検出を終了コード判定（exit 2）からstdout解析（`warn:`プレフィックス検出）に変更する。

## 変更対象ファイル
- `prompts/package/skills/aidlc-setup/bin/aidlc-setup.sh`（L370-403、Step 5）

## 実装計画

### 現在の実装（L385-401）
```
set +e
"$MIGRATE_CONFIG" "${MIGRATE_ARGS[@]}"
MIGRATE_EXIT=$?
set -e

case $MIGRATE_EXIT in
    0) ;; # 正常完了
    2) echo "warn:migrate-warnings" ;;
    *) echo "error:migrate-failed" >&2; exit 1 ;;
esac
```

### 変更後の実装方針
1. migrate-config.shの出力を一時変数にキャプチャする
2. 終了コードでエラー判定（0以外はエラー）
3. stdout出力に`warn:`を含む行があれば`warn:migrate-warnings`を出力
4. exit 2の分岐を削除

### 実装イメージ
```
set +e
MIGRATE_OUTPUT="$("$MIGRATE_CONFIG" "${MIGRATE_ARGS[@]}")"
MIGRATE_EXIT=$?
set -e

if [[ $MIGRATE_EXIT -ne 0 ]]; then
    echo "error:migrate-failed" >&2
    exit 1
fi

# stdout出力にwarn:行が含まれるか確認（内部判定のみ、再出力しない）
if echo "$MIGRATE_OUTPUT" | grep -q '^warn:'; then
    echo "warn:migrate-warnings"
fi
```

**注意**: migrate-config.shのstdoutは変数にキャプチャし、上位には再出力しない。stderrは通常通り上位に流れる。

## 完了条件チェックリスト
- [ ] aidlc-setup.shのStep 5でmigrate-config.shの警告検出ロジックがstdout解析に移行されている
- [ ] migrate-config.shのstdout出力を解析して警告有無を判定する方式に変更されている
- [ ] stdoutに`warn:`プレフィックスの行が含まれる場合に`warn:migrate-warnings`を出力する
- [ ] 警告なしで正常完了（stdout出力にwarn:なし、exit 0）の場合、警告メッセージを出力しない
- [ ] 致命的エラー（exit 1以上）の場合、`error:migrate-failed`を出力する
- [ ] 終了コード2による警告判定ロジックが削除されている
