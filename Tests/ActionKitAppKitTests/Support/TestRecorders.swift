import ActionKitAppKit
import Foundation

actor AutomationDeniedRecorder {
  private(set) var called = false
  private(set) var appleScriptErrorNumber: Int?

  func record(appleScriptErrorNumber: Int?) {
    called = true
    self.appleScriptErrorNumber = appleScriptErrorNumber
  }
}

final class LogRecorder: @unchecked Sendable {
  private let lock = NSLock()
  private var entries: [(ActionExecutorConfiguration.LogLevel, String)] = []

  func record(_ level: ActionExecutorConfiguration.LogLevel, _ message: String) {
    lock.withLock {
      entries.append((level, message))
    }
  }

  func contains(level: ActionExecutorConfiguration.LogLevel, message: String) -> Bool {
    lock.withLock {
      entries.contains { $0 == level && $1 == message }
    }
  }
}

final class InvocationRecorder: @unchecked Sendable {
  private let lock = NSLock()
  private var count = 0

  func record() {
    lock.withLock {
      count += 1
    }
  }

  var invocationCount: Int {
    lock.withLock {
      count
    }
  }
}
