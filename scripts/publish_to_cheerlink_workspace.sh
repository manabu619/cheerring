#!/usr/bin/env bash
# =============================================================================
# CheerRING LP モックアップを cheerlink-workspace にPR提出するスクリプト
#
# 配置先: docs/business/cheerring/lp-mockup/
#   ← 統合資料v2 の「あなたが触るのはここ」に該当
#   （新保さんの主戦場 = docs/business/cheerring/ 配下）
#
# 実行方法:
#   bash scripts/publish_to_cheerlink_workspace.sh
# =============================================================================

set -e
set -u

log()  { printf "\033[1;36m[INFO]\033[0m %s\n" "$*"; }
ok()   { printf "\033[1;32m[ OK ]\033[0m %s\n" "$*"; }
warn() { printf "\033[1;33m[WARN]\033[0m %s\n" "$*"; }
err()  { printf "\033[1;31m[ERR ]\033[0m %s\n" "$*" >&2; }
sec()  { printf "\n\033[1;37m=== %s ===\033[0m\n" "$*"; }

# ----- 設定 -----
CHEERLINK_DIR="$HOME/ForClaudeCode/CheerLink"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DEST_REL="docs/business/cheerring/lp-mockup"
BRANCH="feature/cheerring-260501-lp-mockup"
PR_TITLE="docs(cheerring): LPモックアップ追加 — copy修正版反映済み"

# =============================================================================
sec "0. 事前確認"
# =============================================================================
if [ ! -d "$CHEERLINK_DIR/.git" ]; then
  err "$CHEERLINK_DIR にcheerlink-workspaceが見つかりません。"
  echo "    先に setup_cheerring.sh を実行してください。"
  exit 1
fi
ok "cheerlink-workspace: $CHEERLINK_DIR"
ok "コピー元: $SRC_DIR"

# =============================================================================
sec "1. main ブランチを最新化"
# =============================================================================
cd "$CHEERLINK_DIR"
log "現在のブランチ: $(git rev-parse --abbrev-ref HEAD)"

# 未コミット変更があれば警告
if ! git diff-index --quiet HEAD -- 2>/dev/null; then
  warn "未コミットの変更があります。一旦stashします..."
  git stash push -m "auto-stash-by-publish-script-$(date +%s)"
  STASHED=1
else
  STASHED=0
fi

log "main に切り替え..."
git checkout main
log "git pull origin main..."
git pull origin main
ok "main 最新化完了"

# =============================================================================
sec "2. 新規ブランチ作成"
# =============================================================================
if git rev-parse --verify "$BRANCH" >/dev/null 2>&1; then
  warn "ブランチ $BRANCH は既に存在します。切り替えます。"
  git checkout "$BRANCH"
  git merge --no-edit main || true
else
  git checkout -b "$BRANCH"
  ok "ブランチ作成: $BRANCH"
fi

# =============================================================================
sec "3. ファイル配置"
# =============================================================================
mkdir -p "$DEST_REL"
log "配置先: $CHEERLINK_DIR/$DEST_REL"

# LP本体・画像・コピーライト関連をコピー（.DS_Storeは除外）
cp "$SRC_DIR/index.html"               "$DEST_REL/"
cp "$SRC_DIR/hero_bg2.png"             "$DEST_REL/"
cp "$SRC_DIR/hanxup.png"               "$DEST_REL/"
cp "$SRC_DIR/コピーライト_修正版.md"    "$DEST_REL/"
cp "$SRC_DIR/コピーライト.md"           "$DEST_REL/"
ok "ファイルコピー完了"

# =============================================================================
sec "4. README 配置"
# =============================================================================
cat > "$DEST_REL/README.md" <<'EOF'
# CheerRING LPモックアップ

このフォルダは、CheerRING LP のデザイン・コピー検討用モックアップです。

> **位置づけ**: Next.js本体 (`src/frontend/lib/config/sports/prowrestling.ts`) への移植元となる「参考実装」。
> このHTMLをそのまま本番に載せるのではなく、ここで固めたコピー・配色・構成を `prowrestling.ts` に展開していきます。

## ファイル構成

| ファイル | 内容 |
|---------|------|
| `index.html` | LP本体（単一HTML / 外部依存なし）。ブラウザで開けばそのまま確認可 |
| `hero_bg2.png` | Heroセクション背景画像 |
| `hanxup.png` | 補助画像 |
| `コピーライト.md` | 初版コピー案 |
| `コピーライト_修正版.md` | 採用版コピー（HEROスクリプト・SOLUTION・CTA改稿反映済み） |

## コア・コピー

- **HERO**: 「この感動を、永遠に。」
- **タグライン**: 「一瞬の熱狂」を、「一生の伴走」に変える。
- **基盤特許**: 特許第7825912号取得済み — CheerLink デジタル会員証システム

## ローカル確認

```bash
open docs/business/cheerring/lp-mockup/index.html
```

または:

```bash
cd docs/business/cheerring/lp-mockup
python3 -m http.server 8080
# → http://localhost:8080
```

## 公開版（参考）

manabu619アカウントでの参考公開先:
- リポジトリ: https://github.com/manabu619/cheerring
- GitHub Pages: https://manabu619.github.io/cheerring/

## 次のアクション

1. ふみのりさんレビュー → 配色・コピーの方向性確定
2. `prowrestling.ts` の `hero` / `painPoints` / `supporterGains` 等への移植計画作成
3. 必要画像の `public/images/prowrestling/` への正式配置
EOF
ok "README.md 作成"

# =============================================================================
sec "5. commit"
# =============================================================================
git add "$DEST_REL"
if git diff --cached --quiet; then
  warn "コミット対象の変更がありません（既に同内容で存在の可能性）"
else
  git commit -m "docs(cheerring): LPモックアップを lp-mockup/ に追加

- HTMLベースの単一ファイルLP（外部依存なし）
- Hero画像・コピーライト初版/修正版を同梱
- コピー修正版反映済み:
  - HEROスクリプト「倒れた姿へ叫んだ声援・立ち上がる姿に力をもらった」
  - SOLUTION見出し「一瞬の熱狂を、一生の伴走に変える」
  - CTAサブコピーを「ただの思い出で終わらせない」表現に変更
- 位置づけ: prowrestling.ts への移植元となる参考実装

Refs: docs/team/00 キックオフ統合資料 §4「あなたが触るのはここ」"
  ok "commit 作成"
fi

# =============================================================================
sec "6. push"
# =============================================================================
log "push..."
git push -u origin "$BRANCH"
ok "push 完了"

# =============================================================================
sec "7. PR 作成"
# =============================================================================
PR_BODY=$(cat <<'EOF'
## 概要

CheerRING LPのデザイン・コピー検討用モックアップを `docs/business/cheerring/lp-mockup/` に追加します。

## 配置先と意図

統合資料v2 §4「あなたが触るのはここ」の `docs/business/cheerring/` 配下に配置。
Next.js本体 (`prowrestling.ts`) には**直接触れていません**。
このモックアップは「prowrestling.ts への移植元」として使う想定です。

## 含まれるもの

- `index.html` — 単一HTMLのLP（外部依存なし）
- `hero_bg2.png` / `hanxup.png` — 画像アセット
- `コピーライト.md` / `コピーライト_修正版.md` — コピー検討資料
- `README.md` — フォルダの位置づけ説明

## コピー修正版で変えた箇所

- **HEROスクリプト**: 「倒れた姿へ叫んだ声援・立ち上がる姿に力をもらった」
- **SOLUTION見出し**: 「一瞬の熱狂」を、「一生の伴走」に変える。
- **CTAサブコピー**: 「ただの思い出で終わらせない」表現へ変更

## ローカル確認

```bash
open docs/business/cheerring/lp-mockup/index.html
```

## 触っていない領域

- `src/frontend/` 配下は今回未変更
- `pages/wrestling/`・`data/lp/LP_wrestling.json`・`lib/config/verticals.config.ts` は未変更
- `supabase/`・`src/backend/`・`pages/api/`・各種設定ファイル も未変更

## 次のステップ（このPRマージ後）

1. ふみのりさんレビューで配色・コピー方向性確定
2. `prowrestling.ts` への移植計画作成（別PR）
3. 必要画像を `public/images/prowrestling/` へ正式配置（別PR）
EOF
)

# 既にPRが存在するかチェック
if gh pr view "$BRANCH" >/dev/null 2>&1; then
  warn "ブランチ $BRANCH のPRは既に存在します"
  PR_URL=$(gh pr view "$BRANCH" --json url --jq .url)
  ok "既存PR: $PR_URL"
else
  log "PR を作成..."
  gh pr create \
    --base main \
    --head "$BRANCH" \
    --title "$PR_TITLE" \
    --body "$PR_BODY"
  PR_URL=$(gh pr view "$BRANCH" --json url --jq .url)
  ok "PR作成完了"
fi

# =============================================================================
sec "8. 完了"
# =============================================================================
echo ""
ok "fumi5150/cheerlink-workspace へのPR提出が完了しました！"
echo ""
echo "  ブランチ: $BRANCH"
echo "  PR URL:  $PR_URL"
echo ""
echo "  次のアクション:"
echo "    1) PR URL を Google Chat でふみのりさんに共有"
echo "    2) Vercel Preview がコメントされるか確認"
echo "    3) レビュー → Approve → merge を待つ"
echo ""

# stashを戻す
if [ "$STASHED" = "1" ]; then
  warn "実行前にstashした変更があります。必要なら git stash pop で復元してください。"
fi
