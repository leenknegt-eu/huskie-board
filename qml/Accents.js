.pragma library

// Long-press alternatives, Gboard-style. Order = popup order (most common first).
var table = {
    "a": ["à", "á", "â", "ä", "æ", "ã", "å", "ā"],
    "c": ["ç", "ć", "č"],
    "d": ["ð", "ď"],
    "e": ["è", "é", "ê", "ë", "ē", "ė", "ę", "€"],
    "g": ["ğ"],
    "i": ["ì", "í", "î", "ï", "ī", "į"],
    "l": ["ł"],
    "n": ["ñ", "ń", "ň"],
    "o": ["ò", "ó", "ô", "ö", "õ", "ø", "œ", "ō"],
    "r": ["ř"],
    "s": ["ß", "ś", "š"],
    "t": ["þ", "ť"],
    "u": ["ù", "ú", "û", "ü", "ū", "ů"],
    "y": ["ý", "ÿ"],
    "z": ["ž", "ź", "ż"],
    ".": [",", "?", "!", "'", "\"", "-", ":", ";", "/", "@", "#", "&", "(", ")"],
    ",": ["'", "\"", ";", ":", "!", "?"]
};

// Number shown as hint and offered first on the top letter row (q=1 ... p=0)
var digits = { "q": "1", "w": "2", "e": "3", "r": "4", "t": "5", "y": "6", "u": "7", "i": "8", "o": "9", "p": "0" };

function digitFor(ch) {
    var d = digits[ch.toLowerCase()];
    return d ? d : "";
}

// Variants for a key label. Uppercase labels get uppercase variants.
function variants(label, withDigit) {
    if (!label || label.length !== 1) return [];
    var lower = label.toLowerCase();
    var upper = label !== lower;
    var list = table[lower] ? table[lower].slice() : [];
    if (upper) {
        list = list.map(function (v) {
            if (v === "ß") return "ẞ";
            var u = v.toUpperCase();
            return u.length === 1 ? u : v;     // keep chars whose uppercase is multi-letter
        });
    }
    var d = withDigit ? digitFor(lower) : "";
    if (d) list.unshift(d);
    return list;
}
