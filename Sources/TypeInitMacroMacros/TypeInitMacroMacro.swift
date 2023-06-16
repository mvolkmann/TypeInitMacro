import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
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

public struct TypeInitMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [SwiftSyntax.DeclSyntax] {
        // Verify that this macro was applied to a class or struct.
        var typeDecl: DeclGroupSyntax? = declaration.as(ClassDeclSyntax.self)
        if typeDecl == nil {
            typeDecl = declaration.as(StructDeclSyntax.self)
        }
        if typeDecl == nil { throw TypeInitError.onlyClassOrStruct }

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
        return PartialSyntaxNodeString(stringLiteral: initialCode)
    }
}

@main
struct struct_initial_macroPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        TypeInitMacro.self,
    ]
}
