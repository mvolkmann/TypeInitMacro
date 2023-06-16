import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import TypeInitMacroMacros
import XCTest

let testMacros: [String: Macro.Type] = [
    "TypeInit": TypeInitMacro.self,
]

final class TypeInitMacroTests: XCTestCase {
    func testOnClass() {
        assertMacroExpansion(
            """
            @TypeInit
            class Book {
                var id: Int
                var title: String
                var subtitle: String
                var description: String
                var author: String
            }
            """,
            expandedSource:
            """

            class Book {
                var id: Int
                var title: String
                var subtitle: String
                var description: String
                var author: String
                init(id: Int, title: String, subtitle: String, description: String, author: String) {
                    self.id = id
                    self.title = title
                    self.subtitle = subtitle
                    self.description = description
                    self.author = author
                }
            }
            """,
            macros: testMacros
        )
    }

    func testOnEnum() {
        assertMacroExpansion(
            """
            @TypeInit
            enum Color {
                case red, green, blue
            }
            """,
            expandedSource:
            """

            enum Color {
                case red, green, blue
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@TypeInit can only be applied to a class or struct",
                    line: 1,
                    column: 1
                )

            ],
            macros: testMacros
        )
    }

    func testOnStruct() {
        // Note that the computed property "description" will not have
        // a corresponding parameter in the generated initializer.
        assertMacroExpansion(
            """
            @TypeInit
            struct Book: CustomStringConvertible {
                var id: Int
                var title: String
                var subtitle: String
                var author: String

                var description: String {
                    "\\(title): \\(description)"
                }
            }
            """,
            // TODO: Why is there a blank line at the beginning?
            // TODO: Is that the line of the macro invocation?
            expandedSource:
            """

            struct Book: CustomStringConvertible {
                var id: Int
                var title: String
                var subtitle: String
                var author: String

                var description: String {
                    "\\(title): \\(description)"
                }
                init(id: Int, title: String, subtitle: String, author: String) {
                    self.id = id
                    self.title = title
                    self.subtitle = subtitle
                    self.author = author
                }
            }
            """,
            macros: testMacros
        )
    }

    func testOnStruct2() {
        // Note that the computed property "description" will not have
        // a corresponding parameter in the generated initializer.
        assertMacroExpansion(
            """
            @TypeInit
            struct Dog: CustomStringConvertible {
                var name: String
                var breed: String

                var description: String {
                    "\\(name) is a \\(breed)"
                }
            }
            """,
            expandedSource:
            """

            struct Dog: CustomStringConvertible {
                var name: String
                var breed: String

                var description: String {
                    "\\(name) is a \\(breed)"
                }
                init(name: String, breed: String) {
                    self.name = name
                    self.breed = breed
                }
            }
            """,
            macros: testMacros
        )
    }
}
