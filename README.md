# CheerRING — Pro Wrestling Fan Membership LP

プロレスを愛するファンのためのデジタル会員証「CheerRING」のランディングページです。
応援してきた時間をあなたの証として残し、その参加を選手のこれからへ届けていく仕組みです。

## サービス概要

- **コンセプト**: この感動を、永遠に。
- **タグライン**: 「一瞬の熱狂」を、「一生の伴走」に変える。
- **基盤特許**: 特許第7825912号取得済み — CheerLink デジタル会員証システム
- **運営**: powered by CheerLink / 合同会社小林PF

## ファイル構成

```
CheerRING/
├── index.html              # LP本体（単一HTMLファイル）
├── b2b.html                # 団体・プロモーター向け導入提案LP
├── proposal.html           # 提案先別の資料ポータル
├── athlete.html            # 選手向け提案ページ
├── qa.html                 # 商談・検討時のQAページ
├── proposal.css            # 提案ページ共通スタイル
├── hero_bg2.png            # Hero背景画像
├── hero_bg2.webp           # Hero背景画像（Web最適化版）
├── hanxup.png              # 補助画像
├── README.md               # このファイル
└── Document/               # 設計・コピーライト関連資料
    ├── CheerRING_キックオフ統合資料_2026-04-30_v2.md
    └── ...
```

## ローカル確認方法

ブラウザで `proposal.html` を開くと、団体・選手・ファン・QAの各ページへ移動できます。

```bash
# macOSの場合
open index.html
```

開発サーバーで確認したい場合:

```bash
# Python 3
python3 -m http.server 8080
# → http://localhost:8080
```

## GitHub Pages 公開

mainブランチのルート(`/`)を公開ソースに設定すると、自動的に公開されます。

公開URL: `https://manabu619.github.io/cheerring/`

提案資料ポータル: `https://manabu619.github.io/cheerring/proposal.html`

団体向けページ: `https://manabu619.github.io/cheerring/b2b.html`

選手向けページ: `https://manabu619.github.io/cheerring/athlete.html`

商談QAページ: `https://manabu619.github.io/cheerring/qa.html`

## ライセンス

© 2026 CheerLink. All rights reserved.
