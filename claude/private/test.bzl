"""Claude test rule that runs prompts and checks for PASS/FAIL results."""

load(":toolchain.bzl", "CLAUDE_RUNTIME_TOOLCHAIN_TYPE")
load(":flags.bzl", "LocalAuthInfo")

def _claude_test_impl(ctx):
    """Implementation of the claude_test rule."""
    local_auth = ctx.attr.local_auth[LocalAuthInfo].value
    toolchain = ctx.toolchains[CLAUDE_RUNTIME_TOOLCHAIN_TYPE]
    claude_binary = toolchain.claude_info.binary

    # Create the test script and result file
    script = ctx.actions.declare_file(ctx.label.name + ".sh")
    result_file = "/tmp/" + ctx.label.name + "_result.txt"

    # Build the prompt
    prompt = ctx.attr.prompt

    # If there are source files, include instructions about them
    src_paths = []
    for src in ctx.files.srcs:
        src_paths.append(src.short_path)

    full_prompt = prompt
    if src_paths:
        full_prompt = "Input files: " + ", ".join(src_paths) + ". " + full_prompt

    # Add instructions for the agent to write PASS/FAIL result
    full_prompt = full_prompt + " Write PASS or FAIL to " + result_file + " - the file must contain just PASS or FAIL, nothing else."

    # If local_auth is enabled, run test locally without sandbox and use real HOME
    # Otherwise, run sandboxed with a fake HOME
    if local_auth:
        env_vars = ""
        execution_info = {"local": "1"}
    else:
        env_vars = "export HOME=.home\n"
        execution_info = {}

    permissions_flags = "--dangerously-skip-permissions"
    if ctx.attr.allowed_tools:
        permissions_flags = "--allowedTools " + " ".join(ctx.attr.allowed_tools)

    # Build the test script content
    script_content = """#!/bin/bash
{env_vars}{claude_binary} {permissions_flags} -p {prompt}
if [ ! -f {result_file} ]; then
    echo "FAIL: Result file was not created at {result_file}"
    exit 1
fi
cat {result_file}
RESULT=$(head -1 {result_file})
if [ "$RESULT" = "PASS" ]; then
    exit 0
else
    exit 1
fi
""".format(
        env_vars = env_vars,
        claude_binary = claude_binary.short_path,
        permissions_flags = permissions_flags,
        prompt = repr(full_prompt),
        result_file = result_file,
    )

    ctx.actions.write(
        output = script,
        content = script_content,
        is_executable = True,
    )

    runfiles = ctx.runfiles(files = ctx.files.srcs + [claude_binary])

    return [
        DefaultInfo(
            executable = script,
            runfiles = runfiles,
        ),
        testing.ExecutionInfo(execution_info),
    ]

claude_test = rule(
    implementation = _claude_test_impl,
    test = True,
    attrs = {
        "srcs": attr.label_list(
            allow_files = True,
            doc = "Input files to be processed by the prompt.",
        ),
        "prompt": attr.string(
            mandatory = True,
            doc = "The prompt to send to Claude. Should describe what to test and the pass/fail criteria.",
        ),
        "local_auth": attr.label(
            default = "@rules_claude//:local_auth",
            doc = "Flag to enable local auth mode (runs without sandbox, uses real HOME).",
        ),
        "allowed_tools": attr.string_list(
            doc = "List of allowed tools. If empty, uses --dangerously-skip-permissions. See https://docs.anthropic.com/en/docs/claude-code/settings#permissions-settings",
        ),
    },
    toolchains = [CLAUDE_RUNTIME_TOOLCHAIN_TYPE],
    doc = "Runs Claude Code with the given prompt. The agent writes PASS/FAIL and explanation to a result file.",
)
