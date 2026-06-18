import Foundation

/// Converts romaji (ASCII romanization) to hiragana incrementally.
///
/// Designed for IME-style partial input: `convert` returns both the fully-resolved
/// hiragana and any trailing romaji that is a valid prefix of a known sequence
/// (i.e., needs more keystrokes to complete). Callers should search on the
/// resolved portion only.
public struct RomajiConverter {

    // MARK: - Mapping table

    static let table: [String: String] = [
        // Vowels
        "a":"あ","i":"い","u":"う","e":"え","o":"お",
        // K row
        "ka":"か","ki":"き","ku":"く","ke":"け","ko":"こ",
        "kya":"きゃ","kyi":"きぃ","kyu":"きゅ","kye":"きぇ","kyo":"きょ",
        // G row
        "ga":"が","gi":"ぎ","gu":"ぐ","ge":"げ","go":"ご",
        "gya":"ぎゃ","gyi":"ぎぃ","gyu":"ぎゅ","gye":"ぎぇ","gyo":"ぎょ",
        // S row
        "sa":"さ","si":"し","su":"す","se":"せ","so":"そ",
        "shi":"し","sha":"しゃ","shu":"しゅ","she":"しぇ","sho":"しょ",
        "sya":"しゃ","syi":"しぃ","syu":"しゅ","sye":"しぇ","syo":"しょ",
        // Z row
        "za":"ざ","zi":"じ","zu":"ず","ze":"ぜ","zo":"ぞ",
        "ji":"じ","ja":"じゃ","ju":"じゅ","je":"じぇ","jo":"じょ",
        "zya":"じゃ","zyi":"じぃ","zyu":"じゅ","zye":"じぇ","zyo":"じょ",
        // T row
        "ta":"た","ti":"ち","tu":"つ","te":"て","to":"と",
        "chi":"ち","cha":"ちゃ","chu":"ちゅ","che":"ちぇ","cho":"ちょ",
        "tsu":"つ",
        "tya":"ちゃ","tyi":"ちぃ","tyu":"ちゅ","tye":"ちぇ","tyo":"ちょ",
        // Cross-consonant っ sequences (t+c digraph cannot be caught by the
        // doubled-consonant rule, so they need explicit entries)
        "tchi":"っち","tcha":"っちゃ","tchu":"っちゅ","tcho":"っちょ","ttsu":"っつ",
        // D row
        "da":"だ","di":"ぢ","du":"づ","de":"で","do":"ど",
        "dya":"ぢゃ","dyi":"ぢぃ","dyu":"ぢゅ","dye":"ぢぇ","dyo":"ぢょ",
        // N row (bare "n" is handled by algorithm, not table)
        "na":"な","ni":"に","nu":"ぬ","ne":"ね","no":"の",
        "nya":"にゃ","nyi":"にぃ","nyu":"にゅ","nye":"にぇ","nyo":"にょ",
        // H row
        "ha":"は","hi":"ひ","hu":"ふ","he":"へ","ho":"ほ",
        "fu":"ふ",
        "hya":"ひゃ","hyi":"ひぃ","hyu":"ひゅ","hye":"ひぇ","hyo":"ひょ",
        "fa":"ふぁ","fi":"ふぃ","fe":"ふぇ","fo":"ふぉ",
        // B row
        "ba":"ば","bi":"び","bu":"ぶ","be":"べ","bo":"ぼ",
        "bya":"びゃ","byi":"びぃ","byu":"びゅ","bye":"びぇ","byo":"びょ",
        // P row
        "pa":"ぱ","pi":"ぴ","pu":"ぷ","pe":"ぺ","po":"ぽ",
        "pya":"ぴゃ","pyi":"ぴぃ","pyu":"ぴゅ","pye":"ぴぇ","pyo":"ぴょ",
        // M row
        "ma":"ま","mi":"み","mu":"む","me":"め","mo":"も",
        "mya":"みゃ","myi":"みぃ","myu":"みゅ","mye":"みぇ","myo":"みょ",
        // Y row
        "ya":"や","yu":"ゆ","yo":"よ","yi":"い","ye":"いぇ",
        // R row
        "ra":"ら","ri":"り","ru":"る","re":"れ","ro":"ろ",
        "rya":"りゃ","ryi":"りぃ","ryu":"りゅ","rye":"りぇ","ryo":"りょ",
        // W row
        "wa":"わ","wi":"うぃ","we":"うぇ","wo":"を","wu":"う",
        // Small kana via x / l prefix
        "xtu":"っ","ltu":"っ",
        "xa":"ぁ","la":"ぁ","xi":"ぃ","li":"ぃ","xu":"ぅ","lu":"ぅ",
        "xe":"ぇ","le":"ぇ","xo":"ぉ","lo":"ぉ",
        "xya":"ゃ","lya":"ゃ","xyu":"ゅ","lyu":"ゅ","xyo":"ょ","lyo":"ょ",
        "xwa":"ゎ","lwa":"ゎ",
        // V (katakana voiced u, common in loan-word chat)
        "va":"ヴぁ","vi":"ヴぃ","vu":"ヴ","ve":"ヴぇ","vo":"ヴぉ",
    ]

    // MARK: - Auxiliary sets (computed once at first use)

    // Characters that can trigger the っ double-consonant rule (step 2 explicitly
    // guards c0 != "n" so "nn" is handled by the ん rule in step 3 instead)
    private static let doubleableConsonants: Set<Character> =
        Set("bcdfghjklmnpqrstvwxyz")

    // Every proper prefix of every table key — used to detect "still typing"
    private static let validPrefixes: Set<String> = {
        var set = Set<String>()
        for key in table.keys where key.count > 1 {
            for i in 1 ..< key.count {
                set.insert(String(key.prefix(i)))
            }
        }
        return set
    }()

    // MARK: - Public API

    /// Convert a romaji string to hiragana using greedy left-to-right matching.
    ///
    /// - Returns: `(hiragana, pending)` where `pending` is any trailing romaji
    ///   that forms a valid prefix of a known mapping but needs more keystrokes.
    ///   Pass-through of non-romaji characters (existing kana, kanji, punctuation)
    ///   is included in `hiragana`.
    public static func convert(_ input: String) -> (hiragana: String, pending: String) {
        var result = ""
        var remaining = input.lowercased()

        while !remaining.isEmpty {
            // 1. Greedy table lookup (up to 4 chars, longest first)
            var matched = false
            for len in stride(from: min(4, remaining.count), through: 1, by: -1) {
                let prefix = String(remaining.prefix(len))
                if let kana = table[prefix] {
                    result += kana
                    remaining = String(remaining.dropFirst(len))
                    matched = true
                    break
                }
            }
            if matched { continue }

            let c0 = remaining.first!

            // 2. Doubled consonant → っ  (consumes first; next iteration handles rest)
            //    "nn" is excluded here so that step 3 can handle it as ん.
            if remaining.count >= 2 {
                let c1 = remaining.dropFirst().first!
                if c0 == c1 && c0 != "n" && doubleableConsonants.contains(c0) {
                    result += "っ"
                    remaining = String(remaining.dropFirst())
                    continue
                }
            }

            // 3. "n" before a consonant that is not y → ん
            //    (Covers "n" before "n": "konn..." = こん + "n..."
            //     Does NOT consume before a vowel or y so that "na","nya" etc. still match.)
            if c0 == "n", remaining.count >= 2 {
                let c1 = remaining.dropFirst().first!
                if doubleableConsonants.contains(c1) && c1 != "y" {
                    result += "ん"
                    remaining = String(remaining.dropFirst())
                    continue
                }
            }

            // 4. Remaining string is a valid prefix → leave as pending
            if validPrefixes.contains(remaining) { break }

            // 5. Lone "n" at end → pending (ambiguous: could be start of na/ni/… or ん)
            if remaining == "n" { break }

            // 6. Unrecognized character → pass through
            result += String(c0)
            remaining = String(remaining.dropFirst())
        }

        return (result, remaining)
    }

    /// Convert romaji to hiragana, appending any pending portion as-is.
    public static func toHiragana(_ romaji: String) -> String {
        let (h, p) = convert(romaji)
        return h + p
    }

    /// Convert romaji and return only the definitively-resolved hiragana.
    /// Pending characters are dropped. Use this for dictionary lookup so that
    /// partially-typed syllables don't pollute the search key.
    public static func resolvedHiragana(_ romaji: String) -> String {
        convert(romaji).hiragana
    }
}
