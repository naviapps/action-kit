extension ActionKind {
  /// The stable semantic identifier for registries, persistence, and tool surfaces.
  public var identifier: String {
    metadata.identifier
  }

  /// The catalog category for the action kind.
  public var category: ActionCategory {
    metadata.category
  }

  /// The host-supplied input shape required to create this action kind.
  public var inputShape: ActionInputShape {
    inputDescriptor.shape
  }

  /// Parameter metadata for building host UIs, schema exporters, and tool surfaces.
  public var inputDescriptor: ActionInputDescriptor {
    metadata.inputDescriptor
  }

  /// Static execution metadata for host policy, action pickers, and tool surfaces.
  public var capabilities: ActionKindCapabilities {
    metadata.capabilities
  }

  /// Creates an action kind from its stable semantic identifier.
  ///
  /// - Parameter identifier: The value exposed by ``identifier``.
  public init?(identifier: String) {
    guard let kind = Self.allCases.first(where: { $0.identifier == identifier }) else {
      return nil
    }
    self = kind
  }

  private var metadata: ActionKindMetadata {
    switch self {
    case .copy, .paste, .cut, .undo, .redo:
      .init(
        identifier: "action.editing.\(identifierPath)",
        category: .editing,
        capabilities: .frontmostApplication(
          isDestructive: self != .copy,
          retryBehavior: self == .copy ? .contextDependent : .unsafe
        )
      )
    case .hideFrontmostApplication, .quitFrontmostApplication:
      .init(
        identifier: "action.frontmost-application.\(identifierPath)",
        category: .frontmostApplication,
        capabilities: .frontmostApplication(
          isDestructive: self == .quitFrontmostApplication,
          retryBehavior: self == .hideFrontmostApplication ? .safe : .unsafe
        )
      )
    case .volumeUp, .volumeDown, .volumeMute, .mediaPlayPause, .mediaNext, .mediaPrevious:
      .init(identifier: "action.media.\(identifierPath)", category: .media, capabilities: .unsafe)
    case .keyboardShortcut:
      .init(
        identifier: "action.keyboard.shortcut",
        category: .keyboard,
        inputDescriptor: .required(
          shape: .string,
          parameterName: "shortcut",
          parameterDescription: "Keyboard shortcut string.",
          exampleInput: .string("cmd+shift+k")
        ),
        capabilities: .frontmostApplication(retryBehavior: .unsafe)
      )
    case .openURL:
      .init(
        identifier: "action.workspace.open-url",
        category: .workspace,
        inputDescriptor: .required(
          shape: .string,
          parameterName: "url",
          parameterDescription: "URL string to open.",
          exampleInput: .string("https://example.com")
        ),
        capabilities: .unsafe
      )
    case .launchApplication:
      .init(
        identifier: "action.workspace.launch-application",
        category: .workspace,
        inputDescriptor: .required(
          shape: .string,
          parameterName: "application",
          parameterDescription: "Application name, bundle identifier, or .app bundle path.",
          exampleInput: .string("Safari")
        ),
        capabilities: .safe
      )
    case .runShortcut:
      .init(
        identifier: "action.workspace.run-shortcut",
        category: .workspace,
        inputDescriptor: .required(
          shape: .string,
          parameterName: "shortcut",
          parameterDescription: "Shortcuts shortcut name.",
          exampleInput: .string("Morning Routine")
        ),
        capabilities: .unsafe
      )
    case .openFolder:
      .init(
        identifier: "action.workspace.open-folder",
        category: .workspace,
        inputDescriptor: .required(
          shape: .string,
          parameterName: "folder",
          parameterDescription: "Folder path to open.",
          exampleInput: .string("/Users/example/Documents")
        ),
        capabilities: .unsafe
      )
    case .lockScreen, .sleepMac, .toggleAppearance:
      .init(
        identifier: "action.system.\(identifierPath)",
        category: .system,
        capabilities: .destructiveUnsafe
      )
    case .missionControl, .showDesktop, .missionControlNextSpace, .missionControlPreviousSpace,
      .missionControlAppExpose, .brightnessUp, .brightnessDown, .showNotificationCenter,
      .captureScreenFull:
      .init(
        identifier: "action.system.\(identifierPath)",
        category: .system,
        capabilities: .unsafe
      )
    case .captureScreenSelection, .captureScreenWindow:
      .init(
        identifier: "action.system.\(identifierPath)",
        category: .system,
        capabilities: .init(requiresInteractiveSelection: true, retryBehavior: .unsafe)
      )
    case .windowMaximize, .windowLeftHalf, .windowRightHalf, .windowTopHalf, .windowBottomHalf,
      .windowCenter, .windowMoveToNextScreen, .windowMoveToPreviousScreen:
      .init(
        identifier: "action.window.\(identifierPath)",
        category: .window,
        capabilities: .focusedWindow(
          retryBehavior: self == .windowMoveToNextScreen || self == .windowMoveToPreviousScreen
            ? .unsafe : .safe
        )
      )
    case .windowPlacement:
      .init(
        identifier: "action.window.placement",
        category: .window,
        inputDescriptor: .required(
          shape: .windowPlacement,
          parameterName: "request",
          parameterDescription: "Focused-window placement request.",
          exampleInput: .windowPlacement(.init(placement: .leftHalf))
        ),
        capabilities: .focusedWindow(retryBehavior: .safe)
      )
    case .windowMove:
      .init(
        identifier: "action.window.move",
        category: .window,
        inputDescriptor: .required(
          shape: .windowMove,
          parameterName: "request",
          parameterDescription: "Focused-window screen movement request.",
          exampleInput: .windowMove(.init(direction: .next))
        ),
        capabilities: .focusedWindow(retryBehavior: .unsafe)
      )
    }
  }

  private var identifierPath: String {
    switch self {
    case .copy: "copy"
    case .paste: "paste"
    case .cut: "cut"
    case .undo: "undo"
    case .redo: "redo"
    case .hideFrontmostApplication: "hide"
    case .quitFrontmostApplication: "quit"
    case .volumeUp: "volume-up"
    case .volumeDown: "volume-down"
    case .volumeMute: "volume-mute"
    case .mediaPlayPause: "play-pause"
    case .mediaNext: "next"
    case .mediaPrevious: "previous"
    case .keyboardShortcut: "shortcut"
    case .openURL: "open-url"
    case .launchApplication: "launch-application"
    case .runShortcut: "run-shortcut"
    case .openFolder: "open-folder"
    case .missionControl: "mission-control"
    case .showDesktop: "show-desktop"
    case .lockScreen: "lock-screen"
    case .sleepMac: "sleep-mac"
    case .missionControlNextSpace: "mission-control-next-space"
    case .missionControlPreviousSpace: "mission-control-previous-space"
    case .missionControlAppExpose: "mission-control-app-expose"
    case .brightnessUp: "brightness-up"
    case .brightnessDown: "brightness-down"
    case .toggleAppearance: "toggle-appearance"
    case .showNotificationCenter: "show-notification-center"
    case .captureScreenFull: "capture-screen-full"
    case .captureScreenSelection: "capture-screen-selection"
    case .captureScreenWindow: "capture-screen-window"
    case .windowMaximize: "maximize"
    case .windowLeftHalf: "left-half"
    case .windowRightHalf: "right-half"
    case .windowTopHalf: "top-half"
    case .windowBottomHalf: "bottom-half"
    case .windowCenter: "center"
    case .windowMoveToNextScreen: "move-to-next-screen"
    case .windowMoveToPreviousScreen: "move-to-previous-screen"
    case .windowPlacement: "placement"
    case .windowMove: "move"
    }
  }
}

private struct ActionKindMetadata {
  let identifier: String
  let category: ActionCategory
  let inputDescriptor: ActionInputDescriptor
  let capabilities: ActionKindCapabilities

  init(
    identifier: String,
    category: ActionCategory,
    inputDescriptor: ActionInputDescriptor = .none,
    capabilities: ActionKindCapabilities
  ) {
    self.identifier = identifier
    self.category = category
    self.inputDescriptor = inputDescriptor
    self.capabilities = capabilities
  }
}

extension ActionInputDescriptor {
  fileprivate static func required(
    shape: ActionInputShape,
    parameterName: String,
    parameterDescription: String,
    exampleInput: ActionInput
  ) -> ActionInputDescriptor {
    guard
      let parameter = ActionInputParameter(
        name: parameterName,
        description: parameterDescription,
        exampleInput: exampleInput
      ),
      let descriptor = ActionInputDescriptor(shape: shape, parameter: parameter)
    else {
      preconditionFailure("Action input descriptor metadata must be shape-compatible.")
    }

    return descriptor
  }
}

extension ActionKindCapabilities {
  fileprivate static let safe = ActionKindCapabilities(retryBehavior: .safe)
  fileprivate static let unsafe = ActionKindCapabilities(retryBehavior: .unsafe)
  fileprivate static let destructiveUnsafe = ActionKindCapabilities(
    isDestructive: true,
    retryBehavior: .unsafe
  )

  fileprivate static func frontmostApplication(
    isDestructive: Bool = false,
    retryBehavior: ActionRetryBehavior = .contextDependent
  ) -> ActionKindCapabilities {
    ActionKindCapabilities(
      requiresFrontmostApplication: true,
      isDestructive: isDestructive,
      retryBehavior: retryBehavior
    )
  }

  fileprivate static func focusedWindow(
    retryBehavior: ActionRetryBehavior = .contextDependent
  ) -> ActionKindCapabilities {
    ActionKindCapabilities(requiresFocusedWindow: true, retryBehavior: retryBehavior)
  }
}
