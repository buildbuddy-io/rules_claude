"""Claude run rule that creates an executable to run prompts via bazel run."""

load(":toolchain.bzl", "CLAUDE_TOOLCHAIN_TYPE")

def _shell_quote(s):
    """Quote a string for safe use in shell scripts."""
    return "'" + s.replace("'", "'\"'\"'") + "'"

def _claude_run_impl(ctx):
    """Implementation of the claude_run rule."""
    toolchain = ctx.toolchains[CLAUDE_TOOLCHAIN_TYPE]
    claude_binary = toolchain.claude_info.binary

    # Build the prompt
    prompt = ctx.attr.prompt

    # If there are source files, include instructions about them
    src_paths = []
    for src in ctx.files.srcs:
        src_paths.append(src.short_path)

    # Construct the prompt with file references
    full_prompt = prompt
    if src_paths:
        full_prompt = "Input files: " + ", ".join(src_paths) + ". " + full_prompt

    # Add output instruction if out/outs specified
    if ctx.attr.outs:
        full_prompt = full_prompt + " Write the outputs to these files: " + ", ".join(ctx.attr.outs)
    elif ctx.attr.out:
        full_prompt = full_prompt + " Write the output to " + ctx.attr.out

    prompt_flag = "" if ctx.attr.interactive else "-p"
    permissions_flags = "--dangerously-skip-permissions"
    if ctx.attr.allowed_tools:
        permissions_flags = "--allowedTools " + " ".join(ctx.attr.allowed_tools)
    script = ctx.actions.declare_file(ctx.label.name + ".sh")
    script_content = """#!/bin/bash
set -e
SCRIPT_DIR="$(pwd)"
cd "$BUILD_WORKING_DIRECTORY"
exec "$SCRIPT_DIR/{claude_binary}" {permissions_flags} {prompt_flag} {prompt} "$@"
""".format(
        permissions_flags = permissions_flags,
        claude_binary = claude_binary.short_path,
        prompt_flag = prompt_flag,
        prompt = _shell_quote(full_prompt),
    )
    ctx.actions.write(
        output = script,
        content = script_content,
        is_executable = True,
    )
    runfiles = ctx.runfiles(files = ctx.files.srcs + [claude_binary])
    return [DefaultInfo(
        files = depset([script]),
        executable = script,
        runfiles = runfiles,
    )]

claude_run = rule(
    implementation = _claude_run_impl,
    attrs = {
        "srcs": attr.label_list(
            allow_files = True,
            doc = "Input files to be processed by the prompt.",
        ),
        "prompt": attr.string(
            mandatory = True,
            doc = "The prompt to send to Claude.",
        ),
        "out": attr.string(
            doc = "Output filename.",
        ),
        "outs": attr.string_list(
            doc = "Multiple output filenames.",
        ),
        "interactive": attr.bool(
            default = False,
            doc = "If True, runs in interactive mode.",
        ),
        "allowed_tools": attr.string_list(
            doc = "List of allowed tools. If empty, uses --dangerously-skip-permissions. See https://docs.anthropic.com/en/docs/claude-code/settings#permissions-settings",
        ),
    },
    executable = True,
    toolchains = [CLAUDE_TOOLCHAIN_TYPE],
    doc = "Creates an executable that runs Claude Code with the given prompt. Use with 'bazel run'.",
)
