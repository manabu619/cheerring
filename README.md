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
├── index.html              # LP本体（単一HTMLファイル・GitHub Pages root）
├── 404.html                # GitHub Pages カスタム404
├── html/                  # サブページ（HTML）
│   ├── b2b.html            # 団体・プロモーター向け導入提案LP
│   ├── proposal.html       # 提案先別の資料ポータル
│   ├── athlete.html        # 選手向け提案ページ
│   ├── qa.html             # 商談・検討時のQAページ
│   ├── proposal.css        # 提案ページ共通スタイル
│   └── CheerRING_選手向け提案書.html
├── assets/
│   ├── images/             # LP用画像（hero_bg2.webp等）
│   └── models/             # 図解画像（B2Bページ用）
└── README.md               # このファイル
```

内部検討資料、作業メモ、財務・法務資料はこの公開リポジトリには含めません。

## ローカル確認方法

```bash
# macOSの場合
open index.html        # ファン向けLP
open html/proposal.html  # 資料ポータル（各ページへの入口）
```

開発サーバーで確認したい場合（相対パスを正しく解決するため推奨）:

```bash
# Python 3
python3 -m http.server 8080
# → http://localhost:8080
# → http://localhost:8080/html/proposal.html
```

## GitHub Pages 公開

mainブランチのルート(`/`)を公開ソースに設定すると、自動的に公開されます。

公開URL: `https://manabu619.github.io/cheerring/`

提案資料ポータル: `https://manabu619.github.io/cheerring/html/proposal.html`

団体向けページ: `https://manabu619.github.io/cheerring/html/b2b.html`

選手向けページ: `https://manabu619.github.io/cheerring/html/athlete.html`

商談QAページ: `https://manabu619.github.io/cheerring/html/qa.html`

## ライセンス

© 2026 CheerLink. All rights reserved.
