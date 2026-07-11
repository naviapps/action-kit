import XCTest

import ActionKit

final class ActionInputDescriptorTests: XCTestCase {
  func testInputDescriptorsExposeRequiredInputFromShape() {
    for kind in ActionKind.allCases {
      XCTAssertEqual(kind.inputDescriptor.requiresInput, kind.inputDescriptor.shape != .none)
    }
  }

  func testInputFreeActionsHaveNoParameterMetadata() {
    for kind in ActionKind.allCases where kind.inputDescriptor.shape == .none {
      let descriptor = kind.inputDescriptor

      XCTAssertEqual(descriptor.shape, .none, "\(kind) should not require input")
      XCTAssertNil(descriptor.parameter, "\(kind) should not expose parameter metadata")
      XCTAssertNil(descriptor.exampleInput, "\(kind) should not expose example input")
    }
  }

  func testInputDescriptorsForInputRequiringKinds() {
    let descriptors: [ActionKind: ActionInputDescriptor?] = Dictionary(
      uniqueKeysWithValues: ActionKind.allCases
        .filter { $0.inputDescriptor.shape != .none }
        .map { ($0, Optional($0.inputDescriptor)) }
    )

    XCTAssertEqual(
      descriptors,
      [
        .keyboardShortcut: Self.descriptor(
          shape: .string,
          parameterName: "shortcut",
          parameterDescription: "Keyboard shortcut string.",
          exampleInput: .string("cmd+shift+k")
        ),
        .openURL: Self.descriptor(
          shape: .string,
          parameterName: "url",
          parameterDescription: "URL string to open.",
          exampleInput: .string("https://example.com")
        ),
        .launchApplication: Self.descriptor(
          shape: .string,
          parameterName: "application",
          parameterDescription: "Application name, bundle identifier, or .app bundle path.",
          exampleInput: .string("Safari")
        ),
        .runShortcut: Self.descriptor(
          shape: .string,
          parameterName: "shortcut",
          parameterDescription: "Shortcuts shortcut name.",
          exampleInput: .string("Morning Routine")
        ),
        .openFolder: Self.descriptor(
          shape: .string,
          parameterName: "folder",
          parameterDescription: "Folder path to open.",
          exampleInput: .string("/Applications")
        ),
        .windowPlacement: Self.descriptor(
          shape: .windowPlacement,
          parameterName: "request",
          parameterDescription: "Focused-window placement request.",
          exampleInput: .windowPlacement(
            .init(
              placement: .grid(columns: 2, rows: 1, column: 0, row: 0, columnSpan: 1, rowSpan: 1)))
        ),
        .windowMove: Self.descriptor(
          shape: .windowMove,
          parameterName: "request",
          parameterDescription: "Focused-window screen movement request.",
          exampleInput: .windowMove(.init(direction: .next))
        ),
      ]
    )
  }

  func testExampleInputsCreateActionsForTheirKinds() {
    for kind in ActionKind.allCases where kind.inputDescriptor.shape != .none {
      let descriptor = kind.inputDescriptor
      guard let exampleInput = descriptor.exampleInput else {
        XCTFail("Missing parameter metadata for \(kind)")
        continue
      }

      XCTAssertEqual(exampleInput.shape, descriptor.shape)
      XCTAssertNotNil(
        kind.makeAction(input: exampleInput), "\(kind) should accept its example input")
    }
  }

  func testParameterGroupsNormalizedMetadata() throws {
    let parameter = try XCTUnwrap(
      ActionInputParameter(
        name: "  url  ",
        description: "\nURL string to open.\t",
        exampleInput: .string("  https://example.com  ")
      )
    )

    XCTAssertEqual(parameter.name, "url")
    XCTAssertEqual(parameter.description, "URL string to open.")
    XCTAssertEqual(parameter.exampleInput, .string("https://example.com"))
  }

  func testParameterRejectsInvalidMetadata() {
    XCTAssertNil(
      ActionInputParameter(
        name: " \n ",
        description: "URL string to open.",
        exampleInput: .string("https://example.com")
      )
    )
    XCTAssertNil(
      ActionInputParameter(
        name: "url",
        description: "\t",
        exampleInput: .string("https://example.com")
      )
    )
    XCTAssertNil(
      ActionInputParameter(
        name: "url",
        description: "URL string to open.",
        exampleInput: .string(" \n ")
      )
    )
  }

  func testDescriptorAcceptsGroupedParameterMetadata() throws {
    let parameter = try XCTUnwrap(
      ActionInputParameter(
        name: "url",
        description: "URL string to open.",
        exampleInput: .string("https://example.com")
      )
    )
    let descriptor = try XCTUnwrap(ActionInputDescriptor(shape: .string, parameter: parameter))

    XCTAssertEqual(descriptor.parameter, parameter)
  }

  func testParameterRoundTripsCodable() throws {
    let parameter = try XCTUnwrap(
      ActionInputParameter(
        name: "url",
        description: "URL string to open.",
        exampleInput: .string("https://example.com")
      )
    )
    let data = try JSONEncoder().encode(parameter)

    XCTAssertEqual(try JSONDecoder().decode(ActionInputParameter.self, from: data), parameter)
  }

  func testRoundTripsCodable() throws {
    let descriptor = ActionKind.openURL.inputDescriptor
    let data = try JSONEncoder().encode(descriptor)

    XCTAssertEqual(try JSONDecoder().decode(ActionInputDescriptor.self, from: data), descriptor)
  }

  func testUsesCanonicalCodableShape() throws {
    let descriptor = ActionKind.openURL.inputDescriptor
    let data = try JSONEncoder().encode(descriptor)
    let payload = try JSONSerialization.jsonObject(with: data) as? [String: Any]

    XCTAssertEqual(payload?["shape"] as? String, "string")
    let parameter = payload?["parameter"] as? [String: Any]
    XCTAssertEqual(parameter?["name"] as? String, "url")
    XCTAssertEqual(parameter?["description"] as? String, "URL string to open.")
    let exampleInput = parameter?["exampleInput"] as? [String: Any]
    XCTAssertEqual(exampleInput?["shape"] as? String, "string")
    XCTAssertEqual(exampleInput?["value"] as? String, "https://example.com")
  }

  func testInputFreeCodableShapeOmitsParameterMetadata() throws {
    let descriptor = ActionKind.copy.inputDescriptor
    let data = try JSONEncoder().encode(descriptor)
    let payload = try JSONSerialization.jsonObject(with: data) as? [String: Any]

    XCTAssertEqual(payload?["shape"] as? String, "none")
    XCTAssertNil(payload?["parameter"])
  }

  func testRejectsMismatchedExampleInputWhenInitializing() {
    let parameter = ActionInputParameter(
      name: "url",
      description: "URL string to open.",
      exampleInput: .string("https://example.com")
    )

    XCTAssertNil(ActionInputDescriptor(shape: .none, parameter: parameter))
  }

  func testRejectsGroupedParameterWhenShapeDoesNotMatch() throws {
    let parameter = try XCTUnwrap(
      ActionInputParameter(
        name: "url",
        description: "URL string to open.",
        exampleInput: .string("https://example.com")
      )
    )

    XCTAssertNil(ActionInputDescriptor(shape: .windowPlacement, parameter: parameter))
  }

  func testNormalizesStringExampleInputWhenInitializing() throws {
    let parameter = try XCTUnwrap(
      ActionInputParameter(
        name: "url",
        description: "URL string to open.",
        exampleInput: .string("  https://example.com  ")
      )
    )
    let descriptor = try XCTUnwrap(
      ActionInputDescriptor(shape: .string, parameter: parameter)
    )

    XCTAssertEqual(descriptor.parameter?.exampleInput, .string("https://example.com"))
    XCTAssertEqual(descriptor.exampleInput, .string("https://example.com"))
  }

  func testRejectsInvalidStringExampleInputWhenInitializing() {
    let parameter = ActionInputParameter(
      name: "value",
      description: "Non-empty string value.",
      exampleInput: .string(" \n ")
    )

    XCTAssertNil(parameter)
  }

  func testRejectsParameterMetadataForInputFreeDescriptor() {
    let parameter = ActionInputParameter(
      name: "unused",
      description: "Should not be exposed.",
      exampleInput: .string("https://example.com")
    )

    XCTAssertNil(ActionInputDescriptor(shape: .none, parameter: parameter))
  }

  func testRejectsIncompleteRequiredInputDescriptor() {
    XCTAssertNil(ActionInputDescriptor(shape: .string))
  }

  func testRejectsBlankRequiredParameterMetadata() {
    XCTAssertNil(
      ActionInputParameter(
        name: "  \n ",
        description: "URL string to open.",
        exampleInput: .string("https://example.com")
      )
    )

    XCTAssertNil(
      ActionInputParameter(
        name: "url",
        description: "\t ",
        exampleInput: .string("https://example.com")
      )
    )
  }

  func testRejectsMismatchedExampleInputWhenDecoding() {
    let data = """
      {
        "shape": "window-placement",
        "parameter": {
          "name": "request",
          "description": "Focused-window placement request.",
          "exampleInput": {
            "shape": "string",
            "value": "window placement"
          }
        }
      }
      """.data(using: .utf8)!

    XCTAssertThrowsError(try JSONDecoder().decode(ActionInputDescriptor.self, from: data))
  }

  func testRejectsParameterMetadataForInputFreeDescriptorWhenDecoding() {
    let data = """
      {
        "shape": "none",
        "parameter": {
          "name": "unused",
          "description": "Should not be exposed.",
          "exampleInput": {
            "shape": "string",
            "value": "https://example.com"
          }
        }
      }
      """.data(using: .utf8)!

    XCTAssertThrowsError(try JSONDecoder().decode(ActionInputDescriptor.self, from: data))
  }

  func testRejectsNullParameterMetadataForInputFreeDescriptorWhenDecoding() {
    let data = """
      {
        "shape": "none",
        "parameter": null
      }
      """.data(using: .utf8)!

    XCTAssertThrowsError(try JSONDecoder().decode(ActionInputDescriptor.self, from: data))
  }

  func testRejectsIncompleteRequiredInputDescriptorWhenDecoding() {
    let data = """
      {
        "shape": "string"
      }
      """.data(using: .utf8)!

    XCTAssertThrowsError(try JSONDecoder().decode(ActionInputDescriptor.self, from: data))
  }

  func testRejectsUnknownDescriptorFieldsWhenDecoding() {
    let data = """
      {
        "shape": "none",
        "metadata": {}
      }
      """.data(using: .utf8)!

    XCTAssertThrowsError(try JSONDecoder().decode(ActionInputDescriptor.self, from: data))
  }

  func testRejectsInvalidParameterWhenDecoding() {
    let data = """
      {
        "name": "url",
        "description": "URL string to open.",
        "exampleInput": {
          "shape": "string",
          "value": "  "
        }
      }
      """.data(using: .utf8)!

    XCTAssertThrowsError(try JSONDecoder().decode(ActionInputParameter.self, from: data))
  }

  func testRejectsUnknownParameterFieldsWhenDecoding() {
    let data = """
      {
        "name": "url",
        "description": "URL string to open.",
        "exampleInput": {
          "shape": "string",
          "value": "https://example.com"
        },
        "metadata": {}
      }
      """.data(using: .utf8)!

    XCTAssertThrowsError(try JSONDecoder().decode(ActionInputParameter.self, from: data))
  }

  private static func descriptor(
    shape: ActionInputShape,
    parameterName: String,
    parameterDescription: String,
    exampleInput: ActionInput
  ) -> ActionInputDescriptor? {
    guard
      let parameter = ActionInputParameter(
        name: parameterName,
        description: parameterDescription,
        exampleInput: exampleInput
      ),
      let descriptor = ActionInputDescriptor(shape: shape, parameter: parameter)
    else {
      return nil
    }

    return descriptor
  }
}
