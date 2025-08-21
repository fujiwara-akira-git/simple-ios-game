AppIcon プレースホルダ

このフォルダには App アイコン用の `Contents.json` とプレースホルダ `AppIcon-1024.png`（代替）があります。

推奨ワークフロー：高品質な 1024x1024 PNG（例: `source-icon-1024.png`）を用意し、以下のコマンドで各サイズを生成してファイル名を置き換えてください。

ターミナルでプロジェクトルートから実行:

```bash
# 例: source-icon-1024.png を用意してから実行
sips -Z 1024 source-icon-1024.png --out AppIcon-1024.png
sips -Z 180 source-icon-1024.png --out AppIcon-60@3x.png
sips -Z 120 source-icon-1024.png --out AppIcon-60@2x.png
sips -Z 152 source-icon-1024.png --out AppIcon-76@2x.png
sips -Z 76  source-icon-1024.png --out AppIcon-76@1x.png
sips -Z 167 source-icon-1024.png --out AppIcon-83.5@2x.png
sips -Z 60  source-icon-1024.png --out AppIcon-20@3x.png
sips -Z 40  source-icon-1024.png --out AppIcon-20@2x.png
sips -Z 87  source-icon-1024.png --out AppIcon-29@3x.png
sips -Z 58  source-icon-1024.png --out AppIcon-29@2x.png

# 生成後、Xcode を再起動（またはクリーン）して確認してください。
```

もし私に自動生成させたい場合は「自動生成して」と言ってください。代替案として、アイコンのデザイン（色・シンボル）を指示いただければ私が1024pxのPNGを生成して、ここで各サイズに変換して追加します。
