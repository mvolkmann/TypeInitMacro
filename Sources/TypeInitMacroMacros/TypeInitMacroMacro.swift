import SwiftCompilerPlugin

// This defines DiagnosticMessage, DiagnosticSeverity, and MessageId
import SwiftDiagnostics

// This package parses, inspects, manipulates, and generates Swift source code.
import SwiftSyntax

// This package provides functions for constructing ASTs
// that describe new code to be generated.
import SwiftSyntaxBuilder

// This package defines protocols and types needed to write Swift macros.
import SwiftSyntaxMacros

enum TypeInitError: CustomStringConvertible, Error {
    case onlyClassOrStruct

    var description: String {
        switch self {
        case .onlyClassOrStruct:
            return "@TypeInit can only be applied to a class or struct"
        }
    }
}

private enum TypeInitDiagnostic: String, DiagnosticMessage {
    case onlyClassOrStruct

    var diagnosticID: MessageID {
        MessageID(domain: "TypeInitMacro", id: rawValue)
    }

    var message: String {
        switch self {
        case .onlyClassOrStruct:
            return "@TypeInit can only be applied to a class or struct"
        }
    }

    var severity: DiagnosticSeverity { return .error } // or .warning
}

// This extends MemberMacro because the declaration in
// Sources/TypeInitMacro/TypeInitMacro.swift was @attached(member, ...).
public struct TypeInitMacro: MemberMacro {
    // This method is required by the MemberMacro protocol.
    // It returns an array of AST objects.
    // In this case a single AST representing an initializer is returned.
    public static func expansion(
        of attribute: AttributeSyntax,
        // AST nodes for structs, classes, enums, actors, protocols,
        // and extensions all conform to the DeclGroupSyntax protocol.
        providingMembersOf declaration: some DeclGroupSyntax,
        // context can be used to emit warning and error messages.
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // Verify that this macro was applied to a class or struct.
        var typeDecl: DeclGroupSyntax? = declaration.as(ClassDeclSyntax.self)
        if typeDecl == nil {
            typeDecl = declaration.as(StructDeclSyntax.self)
        }
        if typeDecl == nil {
            // Simple error handling that doesn't add much detail.
            // throw TypeInitError.onlyClassOrStruct

            // More complex error handling that adds more detail.
            // You can also describe suggested fixes
            // which display "Fix" buttons in Xcode.
            let diagnostic = Diagnostic(
                node: Syntax(attribute),
                message: TypeInitDiagnostic.onlyClassOrStruct
            )
            context.diagnose(diagnostic)
            return [] // no new code is generated
        }

        // Get all the variable declarations in the type.
        let members = typeDecl!.memberBlock.members
        let variableDecl = members
            .compactMap { $0.decl.as(VariableDeclSyntax.self) }

        // Get an array containing the variable names.
        let variablesName = variableDecl
            .compactMap { $0.bindings.first?.pattern }

        // Get an array containing the variable types.
        let variablesType = variableDecl
            .compactMap { $0.bindings.first?.typeAnnotation?.type }

        // Generate an initializer.
        let initializer = try InitializerDeclSyntax(
            // This method is defined below.
            TypeInitMacro.generateInitialCode(
                variablesName: variablesName,
                variablesType: variablesType
            )
        ) {
            // Add lines in the body of the initializer
            // that initialize each property.
            for name in variablesName {
                // This creates an AST node from a string of Swift source code.
                ExprSyntax("self.\(name) = \(name)")
            }
        }

        return [DeclSyntax(initializer)]
    }

    // This builds the first line of the initializer function
    // that includes the parameter list.
    // It does not build its body.
    public static func generateInitialCode(
        variablesName: [PatternSyntax],
        variablesType: [TypeSyntax]
    ) -> PartialSyntaxNodeString {
        var initialCode = "init("
        for (name, type) in zip(variablesName, variablesType) {
            initialCode += "\(name): \(type), "
        }
        initialCode = String(initialCode.dropLast(2))
        initialCode += ")"
        // This creates an AST node from a string of Swift source code
        // and returns it.
        return PartialSyntaxNodeString(stringLiteral: initialCode)
    }
}

@main
struct struct_initial_macroPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        TypeInitMacro.self,
    ]
}
