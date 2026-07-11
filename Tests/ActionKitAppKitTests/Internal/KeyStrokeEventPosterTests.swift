import ApplicationServices
import XCTest

import ActionKitAppKit

final class KeyStrokeEventPosterTests: XCTestCase {
  func testPostKeyStrokePostsKeyDownThenKeyUp() {
    let recorder = KeyEventRecorder()
    let poster = KeyStrokeEventPoster(
      makeKeyEvent: { virtualKey, flags, keyDown in
        recorder.recordRequest(virtualKey: virtualKey, flags: flags, keyDown: keyDown)
        guard let event = Self.keyEvent(virtualKey: virtualKey, keyDown: keyDown) else {
          XCTFail("Test CGEvent creation should succeed.")
          return nil
        }
        return event
      },
      postKeyEvent: { event in
        let isNonRepeating = event.getIntegerValueField(.keyboardEventAutorepeat) == 0
        recorder.recordPostedEvent(isNonRepeating: isNonRepeating)
      }
    )

    let result = poster.postKeyStroke(virtualKey: 12, flags: [.maskCommand, .maskShift])

    XCTAssertTrue(result)
    XCTAssertEqual(recorder.requestedEvents.map(\.virtualKey), [12, 12])
    XCTAssertEqual(
      recorder.requestedEvents.map(\.flags),
      [[.maskCommand, .maskShift], [.maskCommand, .maskShift]]
    )
    XCTAssertEqual(recorder.requestedEvents.map(\.keyDown), [true, false])
    XCTAssertEqual(recorder.postedNonRepeatingEvents, [true, true])
  }

  func testPostKeyStrokeDefaultFactoryAppliesVirtualKeyAndFlags() {
    let recorder = KeyEventRecorder()
    let poster = KeyStrokeEventPoster(
      postKeyEvent: { event in
        recorder.recordPostedEvent(
          virtualKey: CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode)),
          flags: event.flags,
          keyDown: event.type == .keyDown
        )
      }
    )

    let result = poster.postKeyStroke(virtualKey: 12, flags: [.maskCommand, .maskShift])

    XCTAssertTrue(result)
    XCTAssertEqual(recorder.postedEvents.map(\.virtualKey), [12, 12])
    XCTAssertEqual(
      recorder.postedEvents.map(\.flags),
      [[.maskCommand, .maskShift], [.maskCommand, .maskShift]]
    )
    XCTAssertEqual(recorder.postedEvents.map(\.keyDown), [true, false])
  }

  func testPostKeyStrokeDoesNotPostPartialEventWhenKeyUpCreationFails() {
    let recorder = KeyEventRecorder()
    let poster = KeyStrokeEventPoster(
      makeKeyEvent: { virtualKey, flags, keyDown in
        recorder.recordRequest(virtualKey: virtualKey, flags: flags, keyDown: keyDown)
        guard keyDown else { return nil }
        guard let event = Self.keyEvent(virtualKey: virtualKey, keyDown: true) else {
          XCTFail("Test CGEvent creation should succeed.")
          return nil
        }
        return event
      },
      postKeyEvent: { _ in recorder.recordPostedEvent(isNonRepeating: true) }
    )

    let result = poster.postKeyStroke(virtualKey: 12, flags: [])

    XCTAssertFalse(result)
    XCTAssertEqual(recorder.requestedEvents.map(\.virtualKey), [12, 12])
    XCTAssertEqual(recorder.requestedEvents.map(\.flags), [[], []])
    XCTAssertEqual(recorder.requestedEvents.map(\.keyDown), [true, false])
    XCTAssertEqual(recorder.postedEventCount, 0)
  }

  func testPostKeyStrokeDoesNotCreateKeyUpWhenKeyDownCreationFails() {
    let recorder = KeyEventRecorder()
    let poster = KeyStrokeEventPoster(
      makeKeyEvent: { virtualKey, flags, keyDown in
        recorder.recordRequest(virtualKey: virtualKey, flags: flags, keyDown: keyDown)
        return nil
      },
      postKeyEvent: { _ in recorder.recordPostedEvent(isNonRepeating: true) }
    )

    let result = poster.postKeyStroke(virtualKey: 12, flags: [.maskCommand])

    XCTAssertFalse(result)
    XCTAssertEqual(recorder.requestedEvents.map(\.virtualKey), [12])
    XCTAssertEqual(recorder.requestedEvents.map(\.flags), [[.maskCommand]])
    XCTAssertEqual(recorder.requestedEvents.map(\.keyDown), [true])
    XCTAssertEqual(recorder.postedEventCount, 0)
  }

  private static func keyEvent(virtualKey: CGKeyCode, keyDown: Bool) -> CGEvent? {
    CGEvent(keyboardEventSource: nil, virtualKey: virtualKey, keyDown: keyDown)
  }
}

private final class KeyEventRecorder: @unchecked Sendable {
  private let lock = NSLock()
  private var requests: [(virtualKey: CGKeyCode, flags: CGEventFlags, keyDown: Bool)] = []
  private var nonRepeatingPosts: [Bool] = []
  private var posts: [(virtualKey: CGKeyCode, flags: CGEventFlags, keyDown: Bool)] = []

  func recordRequest(virtualKey: CGKeyCode, flags: CGEventFlags, keyDown: Bool) {
    lock.withLock {
      requests.append((virtualKey, flags, keyDown))
    }
  }

  func recordPostedEvent(isNonRepeating: Bool) {
    lock.withLock {
      nonRepeatingPosts.append(isNonRepeating)
    }
  }

  func recordPostedEvent(virtualKey: CGKeyCode, flags: CGEventFlags, keyDown: Bool) {
    lock.withLock {
      posts.append((virtualKey, flags, keyDown))
    }
  }

  var requestedEvents: [(virtualKey: CGKeyCode, flags: CGEventFlags, keyDown: Bool)] {
    lock.withLock {
      requests
    }
  }

  var postedEvents: [(virtualKey: CGKeyCode, flags: CGEventFlags, keyDown: Bool)] {
    lock.withLock {
      posts
    }
  }

  var postedNonRepeatingEvents: [Bool] {
    lock.withLock {
      nonRepeatingPosts
    }
  }

  var postedEventCount: Int {
    lock.withLock {
      nonRepeatingPosts.count + posts.count
    }
  }
}
