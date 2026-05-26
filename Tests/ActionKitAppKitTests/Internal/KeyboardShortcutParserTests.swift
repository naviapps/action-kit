import ApplicationServices
import Carbon
import XCTest

@testable import ActionKitAppKit

final class KeyboardShortcutParserTests: XCTestCase {
  func testParsesCommandC() {
    assertParses("⌘C", virtualKey: kVK_ANSI_C, modifiers: .maskCommand)
  }

  func testParsesUnmodifiedKey() {
    assertParses("c", virtualKey: kVK_ANSI_C)
  }

  func testParsesSymbolModifierWithSeparator() {
    assertParses("⌘+C", virtualKey: kVK_ANSI_C, modifiers: .maskCommand)
  }

  func testParsesSymbolModifierWithHyphenSeparator() {
    assertParses("⌘-C", virtualKey: kVK_ANSI_C, modifiers: .maskCommand)
  }

  func testParsesSymbolModifiers() {
    assertParses("⌘⇧C", virtualKey: kVK_ANSI_C, modifiers: [.maskCommand, .maskShift])
  }

  func testParsesControlAndOptionSymbolModifiers() {
    assertParses("⌃⌥C", virtualKey: kVK_ANSI_C, modifiers: [.maskControl, .maskAlternate])
  }

  func testParsesNamedModifiers() {
    assertParses("cmd shift z", virtualKey: kVK_ANSI_Z, modifiers: [.maskCommand, .maskShift])
  }

  func testParsesWhitespaceAroundTokens() {
    assertParses(
      " command + option + c ", virtualKey: kVK_ANSI_C,
      modifiers: [
        .maskCommand, .maskAlternate,
      ])
  }

  func testParsesHyphenKeyWhenPlusSeparatesModifiers() {
    assertParses("cmd+-", virtualKey: kVK_ANSI_Minus, modifiers: .maskCommand)
  }

  func testParsesNamedSymbolKeys() {
    assertParses("cmd+minus", virtualKey: kVK_ANSI_Minus, modifiers: .maskCommand)
    assertParses(
      "cmd+plus", virtualKey: kVK_ANSI_Equal,
      modifiers: [
        .maskCommand, .maskShift,
      ])
  }

  func testParsesShiftedSymbolKeys() {
    assertParses(
      "cmd+?", virtualKey: kVK_ANSI_Slash,
      modifiers: [
        .maskCommand, .maskShift,
      ])
    assertParses(
      "cmd+_", virtualKey: kVK_ANSI_Minus,
      modifiers: [
        .maskCommand, .maskShift,
      ])
    assertParses(
      "cmd+:", virtualKey: kVK_ANSI_Semicolon,
      modifiers: [
        .maskCommand, .maskShift,
      ])
  }

  func testParsesHyphenSeparatedModifiers() {
    assertParses(
      "cmd-shift-z", virtualKey: kVK_ANSI_Z,
      modifiers: [
        .maskCommand, .maskShift,
      ])
  }

  func testParsesLongModifierNames() {
    assertParses(
      "command option c", virtualKey: kVK_ANSI_C,
      modifiers: [
        .maskCommand, .maskAlternate,
      ])
  }

  func testParsesPlusSeparatedLongModifierNames() {
    assertParses(
      "command+option+c", virtualKey: kVK_ANSI_C,
      modifiers: [
        .maskCommand, .maskAlternate,
      ])
  }

  func testParsesUppercaseNamedModifiersWithStableLocale() {
    assertParses(
      "COMMAND+OPTION+C", virtualKey: kVK_ANSI_C,
      modifiers: [
        .maskCommand, .maskAlternate,
      ])
  }

  func testParsesFunctionModifierAliases() {
    assertParses("fn f11", virtualKey: kVK_F11, modifiers: .maskSecondaryFn)
    assertParses("function+f11", virtualKey: kVK_F11, modifiers: .maskSecondaryFn)
  }

  func testParsesExtendedFunctionKeys() {
    assertParses("cmd f20", virtualKey: kVK_F20, modifiers: .maskCommand)
  }

  func testParsesNavigationKeys() {
    assertParses("cmd home", virtualKey: kVK_Home, modifiers: .maskCommand)
    assertParses("shift page-down", virtualKey: kVK_PageDown, modifiers: .maskShift)
    assertParses(
      "fn forward-delete",
      virtualKey: kVK_ForwardDelete,
      modifiers: .maskSecondaryFn
    )
  }

  func testParsesSymbolKeyAliases() {
    assertParses("cmd+⌫", virtualKey: kVK_Delete, modifiers: .maskCommand)
    assertParses("cmd+←", virtualKey: kVK_LeftArrow, modifiers: .maskCommand)
  }

  func testParsesHyphenSeparatedModifierWithHyphenatedKeyName() {
    assertParses("cmd-page-down", virtualKey: kVK_PageDown, modifiers: .maskCommand)
    assertParses(
      "fn-forward-delete",
      virtualKey: kVK_ForwardDelete,
      modifiers: .maskSecondaryFn
    )
  }

  func testRejectsUnknownModifierToken() {
    assertRejects("cmd hyper c")
  }

  func testRejectsUnknownKeyToken() {
    assertRejects("cmd unknown")
  }

  func testRejectsMissingKey() {
    assertRejects("")
    assertRejects("cmd")
    assertRejects("⌘")
  }

  func testRejectsDuplicateModifierTokens() {
    assertRejects("cmd cmd c")
    assertRejects("cmd+cmd+c")
    assertRejects("⌘⌘C")
    assertRejects("⌘cmd+C")
  }

  func testRejectsEmptySeparatorTokens() {
    assertRejects("cmd++c")
    assertRejects("cmd--page-down")
    assertRejects("cmd-page--down")
  }

  func testRejectsRepeatedSymbolSeparators() {
    assertRejects("⌘++C")
    assertRejects("⌘--C")
  }
}

private func assertParses(
  _ shortcut: String,
  virtualKey: Int,
  modifiers: CGEventFlags = [],
  file: StaticString = #filePath,
  line: UInt = #line
) {
  guard let result = KeyboardShortcutParser.parse(shortcut) else {
    return XCTFail("Expected shortcut to parse: \(shortcut)", file: file, line: line)
  }
  XCTAssertEqual(result.virtualKey, keyCode(virtualKey), file: file, line: line)
  XCTAssertEqual(result.modifiers, modifiers, file: file, line: line)
}

private func assertRejects(
  _ shortcut: String,
  file: StaticString = #filePath,
  line: UInt = #line
) {
  XCTAssertNil(KeyboardShortcutParser.parse(shortcut), file: file, line: line)
}

private func keyCode(_ value: Int) -> CGKeyCode {
  CGKeyCode(value)
}
