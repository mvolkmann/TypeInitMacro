// An attached "member" macro adds members to a type.
// In this case we want to add an initializer to a class or struct.
@attached(member, names: named(init))
public macro TypeInit() = #externalMacro(
    module: "TypeInitMacroMacros",
    type: "TypeInitMacro"
)
