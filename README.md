
# Simple Tap Game (SwiftUI)

シンプルなiOSゲームのテンプレートです。プレイヤーは画面上の丸をタップして得点を稼ぎ、制限時間内にできるだけ多くタップします。

このフォルダ内のファイルをXcodeプロジェクトにコピーするか、新規のSwiftUI iOS Appで以下のファイル内容を置き換えて使ってください。

## ファイル

- `SimpleTapGameApp.swift` — アプリエントリポイント
- `ContentView.swift` — ゲーム画面の実装

## 動作確認手順（Xcode）

1. Xcodeで「File > New > Project...」を選択し、iOS > App（SwiftUI）で新規プロジェクトを作成します。最低でもiOS 15以降をターゲットにしてください。

2. 生成されたプロジェクト内の `ContentView.swift` と `App` ファイル（例: `MyAppApp.swift`）を本フォルダ内の `ContentView.swift` と `SimpleTapGameApp.swift` の中身で置き換えます。

3. シミュレータか実機でビルドして実行します（⌘R）。

## ゲーム説明

- 制限時間: 30秒
- タップで得点 +1
- タップしたときに丸がランダムに移動し、サイズもランダムに変化します
- 時間切れでスコア表示と再スタートボタン

## カスタマイズ案

- 制限時間や丸の色・アニメーションを変更
- 複数の丸、難易度（速度）を追加
- サウンドやアニメーションで演出強化

## 見た目の変更点

- 背景にリニアグラデーションを追加（`Assets.xcassets` にカラーを追加するとより良く見えます）
- スコアとタイマーの上部ステータスバーを追加
- タップ時のハプティックフィードバックと微妙なパルスアニメーションを追加
- 終了時にブラーを使ったオーバーレイでスコアを強調

必要であれば `Assets.xcassets` に `AccentStart` / `AccentEnd` カラーセットを追加して下さい。

## App Icon 自動生成スクリプト

簡単なアイコン（中央に稲妻、紫→シアンのグラデーション）を自動生成するスクリプトを `Scripts/generate_app_icons.swift` に追加しました。実行すると `SimpleGame/SimpleGame/Assets.xcassets/AppIcon.appiconset/` に各サイズのPNGを出力します。

実行方法（macOS）:

```bash
cd /Users/akira2/projects/simple-ios-game
chmod +x Scripts/generate_app_icons.swift
./Scripts/generate_app_icons.swift
```

実行後、Xcode で `AppIcon` カタログを確認してください。必要なら `Contents.json` に不足サイズを追記してください。

使い方でわからない点があれば教えてください。
