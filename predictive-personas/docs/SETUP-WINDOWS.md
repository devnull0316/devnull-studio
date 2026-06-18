# Windows で開発を始める

エンジン層は **Windows だけで開発・テストできる**。iOS シェルに載せる段階で初めて Mac（クラウドMac可）が要る。

---

## 1. Swift を Windows に入れる

おすすめは公式インストーラ **swiftly**（`https://www.swift.org/install/windows/`）。

- Microsoft Store または winget で導入する方法も公式に案内されている。
- 必要なもの：Windows 10/11（x64）、Visual Studio の C++ ビルドツール（Swift が依存）。インストーラの指示に従えば入る。

確認：
```powershell
swift --version
```

> この環境（Linux）では Swift 6.3.2 で全テストの通過を確認済み。Windows でも同じ Foundation API のみを使っているので同様に動く。

---

## 2. エンジンをビルド・テスト・実行

```powershell
cd predictive-personas\engine
swift build          # ビルド
swift test           # ユニットテスト（14本）
swift run persona-demo   # ペルソナ切替・持ち運びのデモ
```

`swift test` が全部パスすれば環境OK。`persona-demo` は「zeta用 / 日常用 を作る → 別々に学習 → 切り替えると候補が変わる → export して別端末に import」までを実演する。

---

## 3. 編集環境
- **VS Code + Swift 拡張**（公式、`swiftlang.swift-vscode`）が Windows で一番楽。補完・ビルド・テストが統合される。
- エンジン層は UIKit を使わないので、Windows の VS Code だけで完結する。

---

## 4. iOS に載せる段階で必要になるもの（M2〜）
ここから先だけ Mac が要る。詳細は `docs/DISTRIBUTION.md`。

- **クラウドMac**（例：MacinCloud / XcodeClub / Macly。月$15〜35〜）を Windows からリモート操作、または中古 Mac mini(M1)。
- **Xcode**（クラウドMac上）。
- **Apple Developer Program $99/年**（実機テスト・TestFlight 配布に必須。18歳=日本では成人で登録可）。
- iOS シェルから `engine` を Swift Package として参照（ローカルパス依存）。

---

## トラブル時
- `swift build` が C++ ツール不足で失敗 → Visual Studio Build Tools を入れ直す（swift.org の Windows ガイド参照）。
- 文字化け → ソース/ターミナルを UTF-8 に。
- Foundation の一部APIが Windows で未対応エラー → そのAPIはエンジン層で使わない（クロスプラットフォーム維持。`docs/ARCHITECTURE.md` の「制約」）。
