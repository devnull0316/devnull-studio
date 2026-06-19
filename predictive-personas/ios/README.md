# iOS シェル層（M2）

エンジン層（`../engine`、Foundationのみ）を **iOSのキーボード拡張＋本体アプリ**に載せるコード。

> ⚠️ **このフォルダは Linux/Windows ではビルドできない**（UIKit / iOS SDK / 署名が要る）。
> ここにあるのは「Mac か xtool に載せればそのまま動く」状態まで仕上げたソース一式。
> エンジン層と同じ2層構成の方針（→ `../docs/ARCHITECTURE.md`）。

---

## 構成

```
ios/
├── Shared/                     ← 本体アプリと拡張の両方に含めるファイル
│   ├── AppGroup.swift          App Group ID と共有データの場所
│   └── PersonaService.swift    PersonaEngine + PersonaStore のラッパ（disk共有）
├── HostApp/                    ← 本体アプリ（SwiftUI）
│   ├── PredictivePersonasApp.swift
│   ├── PersonaViewModel.swift  ObservableObject（変更→保存→再読込）
│   ├── Views/
│   │   ├── RootView.swift           タブ（ペルソナ / 共有 / 設定）
│   │   ├── PersonaListView.swift    一覧・切替・作成・削除
│   │   ├── ImportExportView.swift   アップロード/ダウンロード（プリセット）
│   │   └── KeyboardSetupView.swift  キーボード有効化の案内
│   ├── Info.plist
│   └── HostApp.entitlements     App Group
└── Keyboard/                   ← キーボード拡張（UIKit）
    ├── KeyboardViewController.swift  UIInputViewController 本体
    ├── CandidateBar.swift           候補バー
    ├── KeyboardLayout.swift         ローマ字QWERTYの行定義
    ├── Info.plist                   NSExtension（keyboard-service）
    └── Keyboard.entitlements        App Group
```

### データの流れ
```
本体アプリ ──┐                            ┌── キーボード拡張
 編集/切替   ├─► PersonaStore(App Group) ◄─┤  complete / learn / 切替
            └──  state.json + personas/   └──
```
両プロセスが **同じ App Group コンテナ**を読む。アプリで作ったペルソナが拡張に出る。
ライブ通知は無く、各側が自然なタイミング（アプリ前面化・キーボード表示）で再読込する（PoC割り切り）。

---

## 動くもの（このPoCで示せること）
- ローマ字入力 → `RomajiConverter` でかな化 → marked text表示
- **アクティブなペルソナの学習データから候補を出す**（候補バー）
- **キーボード上の 👤 ボタンでペルソナを即切替**＝同じ入力でも候補が変わる（製品の核）
- 確定で `learn`、次語予測（`predictNext`）
- 本体アプリ：一覧・切替・作成・削除・プリセットのアップロード/ダウンロード
- Full Access オフで動作（学習データは端末内のみ・外部送信なし）

## まだやらないこと
- 本格的なかな漢字変換辞書（LOUDS＋分割ロードは後段、→ DECISIONS D2）
- CloudKit 同期（export/import の上に後で乗せる）
- 濁点・小書き・記号・数字などフルIMEの作り込み

---

## ビルド手順

共通の前提：**$99 Apple Developer アカウント**（App Group とプロビジョニングに必須、→ DECISIONS D8）。

### 置き換えが必要なプレースホルダ
| 場所 | 値 |
|---|---|
| `Shared/AppGroup.swift` の `identifier` | 自分の App Group ID |
| `HostApp/HostApp.entitlements` | 同上（完全一致させる） |
| `Keyboard/Keyboard.entitlements` | 同上（完全一致させる） |
| 各 `Info.plist` の `$(PRODUCT_BUNDLE_IDENTIFIER)` | Bundle ID（拡張は本体の子、例 `…app.keyboard`） |
| `Keyboard/Info.plist` の `NSExtensionPrincipalClass` | `<拡張モジュール名>.KeyboardViewController` |

### ルートA：xtool（Linux / WSL / Mac、Macなしで実機サイドロード）
推奨ルート（→ DECISIONS D11）。開発ループ（ビルド→実機）を回す用。
1. xtool をインストール（`xtool.sh` 参照、App Extensions は v1.14.0+）
2. 本体アプリ＋キーボード拡張（appex）の2ターゲットを定義
   - 拡張のビルド方法・entitlements指定は xtool の appex ドキュメント参照
3. `PersonaEngine` をローカル依存（`../engine`）として追加
4. `Shared/` の2ファイルを **両ターゲット**に含める
5. `xtool build` → 実機にサイドロード（`xtool install`）
6. 端末で「設定 → 一般 → キーボード」から追加して動作確認

### ルートB：Xcode（クラウドMac / 実機Mac）
TestFlight 提出時に確実なルート。
1. **App** テンプレートで新規プロジェクト（SwiftUI / iOS 16+）
2. ターゲット追加：**Custom Keyboard Extension**
3. ローカルパッケージ追加：File → Add Packages → `../engine` を選び `PersonaEngine` を本体・拡張の両方にリンク
4. ファイル追加（Target Membership に注意）：
   - `Shared/*` → **本体・拡張の両方**
   - `HostApp/*` → 本体のみ
   - `Keyboard/*` → 拡張のみ
5. Signing & Capabilities：両ターゲットに **App Groups** を追加し同じIDを選択。Full Access は **オフ**のまま
6. 各ターゲットの Info.plist／entitlements をこのフォルダの内容に合わせる
7. 実機 or Simulator で実行 → キーボードを有効化

> Simulator はクラウドMac側のみ（xtoolはSimulator不可・実機のみ、→ DECISIONS D7）。

---

## 受験デモの撮り方（メモ）
1. ペルソナを2つ作る（例：「日常用」「zeta用」）
2. それぞれで違う確定を数回（同じ「すき」に別の表記を学習させる）
3. 任意のアプリで `suki` と打つ → 候補を見せる → 👤 で切替 → **同じ入力で候補が変わる**瞬間を撮る
4. これが「予測変換を人格レイヤーとして切り替える」を1カットで見せる絵になる
