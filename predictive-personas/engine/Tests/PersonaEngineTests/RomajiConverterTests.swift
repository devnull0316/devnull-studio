import XCTest
@testable import PersonaEngine

final class RomajiConverterTests: XCTestCase {

    // MARK: - Basic vowels

    func testVowels() {
        XCTAssertEqual(RomajiConverter.toHiragana("a"),  "あ")
        XCTAssertEqual(RomajiConverter.toHiragana("i"),  "い")
        XCTAssertEqual(RomajiConverter.toHiragana("u"),  "う")
        XCTAssertEqual(RomajiConverter.toHiragana("e"),  "え")
        XCTAssertEqual(RomajiConverter.toHiragana("o"),  "お")
        XCTAssertEqual(RomajiConverter.toHiragana("aiueo"), "あいうえお")
    }

    // MARK: - Basic syllables

    func testKRow() {
        XCTAssertEqual(RomajiConverter.toHiragana("ka"), "か")
        XCTAssertEqual(RomajiConverter.toHiragana("ki"), "き")
        XCTAssertEqual(RomajiConverter.toHiragana("ku"), "く")
        XCTAssertEqual(RomajiConverter.toHiragana("ko"), "こ")
        XCTAssertEqual(RomajiConverter.toHiragana("kya"), "きゃ")
        XCTAssertEqual(RomajiConverter.toHiragana("kyu"), "きゅ")
        XCTAssertEqual(RomajiConverter.toHiragana("kyo"), "きょ")
    }

    func testSRow() {
        XCTAssertEqual(RomajiConverter.toHiragana("sa"),  "さ")
        XCTAssertEqual(RomajiConverter.toHiragana("shi"), "し")
        XCTAssertEqual(RomajiConverter.toHiragana("si"),  "し")  // alternate
        XCTAssertEqual(RomajiConverter.toHiragana("su"),  "す")
        XCTAssertEqual(RomajiConverter.toHiragana("sha"), "しゃ")
        XCTAssertEqual(RomajiConverter.toHiragana("shu"), "しゅ")
        XCTAssertEqual(RomajiConverter.toHiragana("sho"), "しょ")
    }

    func testTRow() {
        XCTAssertEqual(RomajiConverter.toHiragana("ta"),  "た")
        XCTAssertEqual(RomajiConverter.toHiragana("chi"), "ち")
        XCTAssertEqual(RomajiConverter.toHiragana("tsu"), "つ")
        XCTAssertEqual(RomajiConverter.toHiragana("te"),  "て")
        XCTAssertEqual(RomajiConverter.toHiragana("to"),  "と")
        XCTAssertEqual(RomajiConverter.toHiragana("cha"), "ちゃ")
        XCTAssertEqual(RomajiConverter.toHiragana("cho"), "ちょ")
    }

    func testNRow() {
        XCTAssertEqual(RomajiConverter.toHiragana("na"), "な")
        XCTAssertEqual(RomajiConverter.toHiragana("ni"), "に")
        XCTAssertEqual(RomajiConverter.toHiragana("nya"), "にゃ")
    }

    // MARK: - "n" special cases

    func testNBeforeConsonantBecomesN() {
        // n before non-y consonant → ん
        XCTAssertEqual(RomajiConverter.toHiragana("nk"),  "んk")   // ん + pending k pass-through
        XCTAssertEqual(RomajiConverter.toHiragana("honki"), "ほんき")  // "hon" = ho+n(→ん)+ki
        XCTAssertEqual(RomajiConverter.toHiragana("sonna"), "そんな") // n before n(consonant)→ん then na→な
        XCTAssertEqual(RomajiConverter.toHiragana("konnichiha"), "こんにちは")
    }

    func testNBeforeVowelStaysAsReading() {
        // "na","ni" etc. match the table directly — "n" is NOT prematurely emitted
        XCTAssertEqual(RomajiConverter.toHiragana("nani"), "なに")
        XCTAssertEqual(RomajiConverter.toHiragana("nani"), "なに")
    }

    func testNAloneIsPending() {
        let (h, p) = RomajiConverter.convert("n")
        XCTAssertEqual(h, "")
        XCTAssertEqual(p, "n")
    }

    func testNNIsN() {
        // "n" before "n" (a consonant) → ん, leaving second "n" which becomes pending
        let (h, p) = RomajiConverter.convert("nn")
        XCTAssertEqual(h, "ん")
        XCTAssertEqual(p, "n")   // second n is pending (might be na, ni, …)
    }

    // MARK: - Double consonant → っ

    func testDoubleConsonant() {
        XCTAssertEqual(RomajiConverter.toHiragana("kka"),   "っか")
        XCTAssertEqual(RomajiConverter.toHiragana("ssa"),   "っさ")
        XCTAssertEqual(RomajiConverter.toHiragana("tta"),   "った")
        XCTAssertEqual(RomajiConverter.toHiragana("ppoi"),  "っぽい")
        XCTAssertEqual(RomajiConverter.toHiragana("matte"), "まって")
        XCTAssertEqual(RomajiConverter.toHiragana("chotto"), "ちょっと")  // cho + t + to
    }

    func testCrossConsonantDigraph() {
        // tchi / ttsu require table entries (doubled t before c/s digraph)
        XCTAssertEqual(RomajiConverter.toHiragana("macchi"),  "まっち")   // doubled c
        XCTAssertEqual(RomajiConverter.toHiragana("matti"),   "まっち")   // doubled t + i (ti=ち)
        XCTAssertEqual(RomajiConverter.toHiragana("itchi"),   "いっち")   // tchi entry
        XCTAssertEqual(RomajiConverter.toHiragana("kittsu"),  "きっつ")   // ttsu entry
    }

    // MARK: - Partial input (pending)

    func testPendingPrefix() {
        // "su" is complete; "k" is a valid prefix → pending
        let (h, p) = RomajiConverter.convert("suk")
        XCTAssertEqual(h, "す")
        XCTAssertEqual(p, "k")
    }

    func testPendingDigraph() {
        let (h, p) = RomajiConverter.convert("sh")
        XCTAssertEqual(h, "")
        XCTAssertEqual(p, "sh")
    }

    func testResolvedHiraganaDropsPending() {
        XCTAssertEqual(RomajiConverter.resolvedHiragana("suk"),  "す")
        XCTAssertEqual(RomajiConverter.resolvedHiragana("suki"), "すき")
        XCTAssertEqual(RomajiConverter.resolvedHiragana("sh"),   "")
        XCTAssertEqual(RomajiConverter.resolvedHiragana("sha"),  "しゃ")
    }

    // MARK: - Case insensitivity

    func testUppercaseInput() {
        XCTAssertEqual(RomajiConverter.toHiragana("SUKI"), "すき")
        XCTAssertEqual(RomajiConverter.toHiragana("KYO"),  "きょ")
    }

    // MARK: - Common words

    func testCommonWords() {
        XCTAssertEqual(RomajiConverter.toHiragana("arigatou"), "ありがとう")
        XCTAssertEqual(RomajiConverter.toHiragana("kawaii"),   "かわいい")
        XCTAssertEqual(RomajiConverter.toHiragana("sugoi"),    "すごい")
        XCTAssertEqual(RomajiConverter.toHiragana("yabai"),    "やばい")
        XCTAssertEqual(RomajiConverter.toHiragana("suki"),     "すき")
        XCTAssertEqual(RomajiConverter.toHiragana("yoroshiku"), "よろしく")
    }

    // MARK: - Hiragana passthrough

    func testHiraganaPassthrough() {
        // Already-hiragana strings should pass through unchanged
        XCTAssertEqual(RomajiConverter.toHiragana("すき"),       "すき")
        XCTAssertEqual(RomajiConverter.toHiragana("ありがとう"), "ありがとう")
    }
}
