import ApplicationServices
import Carbon
import Foundation

package enum KeyboardShortcutParser {
  package struct ParsedShortcut: Equatable, Sendable {
    package let virtualKey: CGKeyCode
    package let modifiers: CGEventFlags
  }

  private struct KeyEquivalent: Sendable {
    let virtualKey: CGKeyCode
    let impliedModifiers: CGEventFlags

    init(_ virtualKey: Int, impliedModifiers: CGEventFlags = []) {
      self.virtualKey = CGKeyCode(virtualKey)
      self.impliedModifiers = impliedModifiers
    }
  }

  private static let normalizationLocale = Locale(identifier: "en_US_POSIX")

  private static let modifierTokens: [String: CGEventFlags] = [
    "⌘": .maskCommand,
    "⇧": .maskShift,
    "⌥": .maskAlternate,
    "⌃": .maskControl,
    "cmd": .maskCommand,
    "command": .maskCommand,
    "shift": .maskShift,
    "opt": .maskAlternate,
    "option": .maskAlternate,
    "ctrl": .maskControl,
    "control": .maskControl,
    "fn": .maskSecondaryFn,
    "function": .maskSecondaryFn,
  ]

  private static let keyEquivalents: [String: KeyEquivalent] = [
    "a": .init(kVK_ANSI_A), "b": .init(kVK_ANSI_B), "c": .init(kVK_ANSI_C),
    "d": .init(kVK_ANSI_D), "e": .init(kVK_ANSI_E), "f": .init(kVK_ANSI_F),
    "g": .init(kVK_ANSI_G), "h": .init(kVK_ANSI_H), "i": .init(kVK_ANSI_I),
    "j": .init(kVK_ANSI_J), "k": .init(kVK_ANSI_K), "l": .init(kVK_ANSI_L),
    "m": .init(kVK_ANSI_M), "n": .init(kVK_ANSI_N), "o": .init(kVK_ANSI_O),
    "p": .init(kVK_ANSI_P), "q": .init(kVK_ANSI_Q), "r": .init(kVK_ANSI_R),
    "s": .init(kVK_ANSI_S), "t": .init(kVK_ANSI_T), "u": .init(kVK_ANSI_U),
    "v": .init(kVK_ANSI_V), "w": .init(kVK_ANSI_W), "x": .init(kVK_ANSI_X),
    "y": .init(kVK_ANSI_Y), "z": .init(kVK_ANSI_Z),
    "0": .init(kVK_ANSI_0), "1": .init(kVK_ANSI_1), "2": .init(kVK_ANSI_2),
    "3": .init(kVK_ANSI_3), "4": .init(kVK_ANSI_4), "5": .init(kVK_ANSI_5),
    "6": .init(kVK_ANSI_6), "7": .init(kVK_ANSI_7), "8": .init(kVK_ANSI_8),
    "9": .init(kVK_ANSI_9),
    "!": .init(kVK_ANSI_1, impliedModifiers: .maskShift),
    "@": .init(kVK_ANSI_2, impliedModifiers: .maskShift),
    "#": .init(kVK_ANSI_3, impliedModifiers: .maskShift),
    "$": .init(kVK_ANSI_4, impliedModifiers: .maskShift),
    "%": .init(kVK_ANSI_5, impliedModifiers: .maskShift),
    "^": .init(kVK_ANSI_6, impliedModifiers: .maskShift),
    "&": .init(kVK_ANSI_7, impliedModifiers: .maskShift),
    "*": .init(kVK_ANSI_8, impliedModifiers: .maskShift),
    "(": .init(kVK_ANSI_9, impliedModifiers: .maskShift),
    ")": .init(kVK_ANSI_0, impliedModifiers: .maskShift),
    "-": .init(kVK_ANSI_Minus), "minus": .init(kVK_ANSI_Minus),
    "_": .init(kVK_ANSI_Minus, impliedModifiers: .maskShift),
    "=": .init(kVK_ANSI_Equal), "equal": .init(kVK_ANSI_Equal),
    "equals": .init(kVK_ANSI_Equal),
    "plus": .init(kVK_ANSI_Equal, impliedModifiers: .maskShift),
    "[": .init(kVK_ANSI_LeftBracket),
    "{": .init(kVK_ANSI_LeftBracket, impliedModifiers: .maskShift),
    "]": .init(kVK_ANSI_RightBracket),
    "}": .init(kVK_ANSI_RightBracket, impliedModifiers: .maskShift),
    ";": .init(kVK_ANSI_Semicolon),
    ":": .init(kVK_ANSI_Semicolon, impliedModifiers: .maskShift),
    "'": .init(kVK_ANSI_Quote), "\"": .init(kVK_ANSI_Quote, impliedModifiers: .maskShift),
    ",": .init(kVK_ANSI_Comma), "<": .init(kVK_ANSI_Comma, impliedModifiers: .maskShift),
    ".": .init(kVK_ANSI_Period), ">": .init(kVK_ANSI_Period, impliedModifiers: .maskShift),
    "/": .init(kVK_ANSI_Slash), "?": .init(kVK_ANSI_Slash, impliedModifiers: .maskShift),
    "\\": .init(kVK_ANSI_Backslash),
    "|": .init(kVK_ANSI_Backslash, impliedModifiers: .maskShift),
    "`": .init(kVK_ANSI_Grave), "~": .init(kVK_ANSI_Grave, impliedModifiers: .maskShift),
    "return": .init(kVK_Return), "enter": .init(kVK_Return), "↩︎": .init(kVK_Return),
    "tab": .init(kVK_Tab), "⇥": .init(kVK_Tab),
    "space": .init(kVK_Space), "spacebar": .init(kVK_Space),
    "delete": .init(kVK_Delete), "backspace": .init(kVK_Delete), "⌫": .init(kVK_Delete),
    "forward-delete": .init(kVK_ForwardDelete), "forwarddelete": .init(kVK_ForwardDelete),
    "⌦": .init(kVK_ForwardDelete),
    "escape": .init(kVK_Escape), "esc": .init(kVK_Escape), "⎋": .init(kVK_Escape),
    "home": .init(kVK_Home), "↖": .init(kVK_Home),
    "end": .init(kVK_End), "↘": .init(kVK_End),
    "page-up": .init(kVK_PageUp), "pageup": .init(kVK_PageUp), "⇞": .init(kVK_PageUp),
    "page-down": .init(kVK_PageDown), "pagedown": .init(kVK_PageDown),
    "⇟": .init(kVK_PageDown),
    "left": .init(kVK_LeftArrow), "←": .init(kVK_LeftArrow),
    "right": .init(kVK_RightArrow), "→": .init(kVK_RightArrow),
    "down": .init(kVK_DownArrow), "↓": .init(kVK_DownArrow),
    "up": .init(kVK_UpArrow), "↑": .init(kVK_UpArrow),
    "f1": .init(kVK_F1), "f2": .init(kVK_F2), "f3": .init(kVK_F3), "f4": .init(kVK_F4),
    "f5": .init(kVK_F5), "f6": .init(kVK_F6), "f7": .init(kVK_F7), "f8": .init(kVK_F8),
    "f9": .init(kVK_F9), "f10": .init(kVK_F10), "f11": .init(kVK_F11),
    "f12": .init(kVK_F12), "f13": .init(kVK_F13), "f14": .init(kVK_F14),
    "f15": .init(kVK_F15), "f16": .init(kVK_F16), "f17": .init(kVK_F17),
    "f18": .init(kVK_F18), "f19": .init(kVK_F19), "f20": .init(kVK_F20),
  ]

  package static func parse(_ shortcut: String) -> ParsedShortcut? {
    let normalized =
      shortcut
      .lowercased(with: normalizationLocale)
      .trimmingCharacters(in: .whitespacesAndNewlines)
    guard !normalized.isEmpty else { return nil }

    guard let (remaining, symbolModifiers) = consumeLeadingSymbolModifiers(from: normalized) else {
      return nil
    }
    let tokenSource = normalizeTokenSource(remaining, hasSymbolModifiers: !symbolModifiers.isEmpty)
    guard let tokens = tokens(from: tokenSource) else { return nil }
    guard let key = tokens.last, let equivalent = keyEquivalents[key] else {
      return nil
    }

    var modifiers = symbolModifiers
    for token in tokens.dropLast() {
      guard let modifier = modifierTokens[token] else { return nil }
      guard modifiers.insert(modifier).inserted else { return nil }
    }
    modifiers.formUnion(equivalent.impliedModifiers)
    return .init(virtualKey: equivalent.virtualKey, modifiers: modifiers)
  }

  private static func consumeLeadingSymbolModifiers(from shortcut: String)
    -> (remaining: String, modifiers: CGEventFlags)?
  {
    var remaining = shortcut[...]
    var modifiers: CGEventFlags = []
    while let first = remaining.first,
      let modifier = modifierTokens[String(first)]
    {
      guard modifiers.insert(modifier).inserted else { return nil }
      remaining.removeFirst()
    }
    return (String(remaining), modifiers)
  }

  private static func normalizeTokenSource(_ remaining: String, hasSymbolModifiers: Bool) -> String
  {
    var tokenSource = remaining.trimmingCharacters(in: .whitespacesAndNewlines)
    guard hasSymbolModifiers else { return tokenSource }

    if tokenSource.first == "+" || shouldRemoveLeadingHyphenSeparator(from: tokenSource) {
      tokenSource.removeFirst()
      tokenSource = tokenSource.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    return tokenSource
  }

  private static func shouldRemoveLeadingHyphenSeparator(from source: String) -> Bool {
    guard source.first == "-", source != "-" else { return false }
    return source.dropFirst().first != "-"
  }

  private static func tokens(from remaining: String) -> [String]? {
    let trimmed = remaining.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return [] }

    if trimmed.contains("+") {
      return tokens(in: trimmed, separatedBy: "+")
    }

    if trimmed.contains(where: \.isWhitespace) {
      return trimmed.split(whereSeparator: \.isWhitespace).map(String.init)
    }

    if trimmed.contains("-"), trimmed != "-", keyEquivalents[trimmed] == nil {
      return hyphenSeparatedTokens(from: trimmed)
    }

    return [trimmed]
  }

  private static func hyphenSeparatedTokens(from source: String) -> [String]? {
    let parts =
      source
      .split(separator: "-", omittingEmptySubsequences: false)
      .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    guard parts.allSatisfy({ !$0.isEmpty }) else { return nil }

    for keyStartIndex in parts.indices {
      let modifierTokens = parts[..<keyStartIndex]
      guard modifierTokens.allSatisfy({ Self.modifierTokens[$0] != nil }) else { continue }

      let keyToken = parts[keyStartIndex...].joined(separator: "-")
      if keyEquivalents[keyToken] != nil {
        return Array(modifierTokens) + [keyToken]
      }
    }
    return parts
  }

  private static func tokens(in source: String, separatedBy separator: Character) -> [String]? {
    let tokens =
      source
      .split(separator: separator, omittingEmptySubsequences: false)
      .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    guard tokens.allSatisfy({ !$0.isEmpty }) else { return nil }
    return tokens
  }
}
