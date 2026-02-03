"""Claude Code toolchain definitions."""

ClaudeInfo = provider(
    doc = "Information about the Claude Code CLI.",
    fields = {
        "binary": "The Claude Code executable file.",
    },
)

def _claude_toolchain_impl(ctx):
    """Implementation of the Claude toolchain."""
    default_info = DefaultInfo(files = depset([ctx.file.claude]))
    toolchain_info = platform_common.ToolchainInfo(
        claude_info = ClaudeInfo(
            binary = ctx.file.claude,
        ),
    )
    template_variable_info = platform_common.TemplateVariableInfo({
        "CLAUDE_BINARY": ctx.file.claude.path,
    })
    return [default_info, toolchain_info, template_variable_info]

claude_toolchain = rule(
    implementation = _claude_toolchain_impl,
    attrs = {
        "claude": attr.label(
            doc = "The Claude Code CLI binary.",
            allow_single_file = True,
            mandatory = True,
        ),
    },
    doc = "Defines a Claude Code toolchain.",
)

CLAUDE_TOOLCHAIN_TYPE = "@rules_claude//claude:toolchain_type"
CLAUDE_RUNTIME_TOOLCHAIN_TYPE = "@rules_claude//claude:runtime_toolchain_type"
