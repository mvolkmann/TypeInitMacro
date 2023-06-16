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

    func testOnStruct() {
        assertMacroExpansion(
            """
            @TypeInit
            struct Book {
                var id: Int
                var title: String
                var subtitle: String
                var description: String
                var author: String
            }
            """,
            // TODO: Why is there a blank line at the beginning?
            // TODO: Is that the line of the macro invocation?
            expandedSource:
            """

            struct Book {
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
}
