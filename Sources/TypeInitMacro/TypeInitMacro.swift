@attached(member, names: named(init))
public macro TypeInit() = #externalMacro(
    module: "TypeInitMacroMacros",
    type: "TypeInitMacro"
)
