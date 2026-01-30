"""Claude rule that takes prompt inputs and produces outputs."""

load("@tools_claude//claude:defs.bzl", "CLAUDE_TOOLCHAIN_TYPE")
load(":flags.bzl", "LocalAuthInfo")

def _claude_impl(ctx):
    """Implementation of the claude rule."""
    local_auth = ctx.attr.local_auth[LocalAuthInfo].value
    toolchain = ctx.toolchains[CLAUDE_TOOLCHAIN_TYPE]
    claude_binary = toolchain.claude_info.binary

    # Determine output file
    if ctx.attr.out:
        out = ctx.actions.declare_file(ctx.attr.out)
    else:
        out = ctx.actions.declare_file(ctx.label.name + ".txt")

    # Build the prompt
    prompt = ctx.attr.prompt

    # If there are source files, include instructions about them
    src_paths = []
    for src in ctx.files.srcs:
        src_paths.append(src.path)

    # Construct the full prompt with file references and output path
    full_prompt = prompt
    if src_paths:
        full_prompt = "Input files: " + ", ".join(src_paths) + ". " + full_prompt
    full_prompt = full_prompt + " Write the output to " + out.path

    # Build arguments for claude -p (print mode)
    args = ctx.actions.args()
    args.add("--dangerously-skip-permissions")
    args.add("-p")
    args.add(full_prompt)

    # If local_auth is enabled, run locally without sandbox and use real HOME
    # Otherwise, run sandboxed with a fake HOME
    if local_auth:
        env = None
        execution_requirements = {"local": "1"}
    else:
        env = {"HOME": ".home"}
        execution_requirements = None

    ctx.actions.run(
        executable = claude_binary,
        arguments = [args],
        inputs = ctx.files.srcs,
        outputs = [out],
        env = env,
        execution_requirements = execution_requirements,
        use_default_shell_env = True,
        mnemonic = "Claude",
        progress_message = "Running Claude: %s" % ctx.label,
    )

    return [DefaultInfo(files = depset([out]))]

claude = rule(
    implementation = _claude_impl,
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
            doc = "Output filename. Defaults to <name>.txt if not specified.",
        ),
        "local_auth": attr.label(
            default = "@rules_claude//:local_auth",
            doc = "Flag to enable local auth mode (runs without sandbox, uses real HOME).",
        ),
    },
    toolchains = [CLAUDE_TOOLCHAIN_TYPE],
    doc = "Runs Claude Code with the given prompt and input files to produce an output.",
)
