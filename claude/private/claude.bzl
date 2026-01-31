"""Claude rule that takes prompt inputs and produces outputs."""

load("@tools_claude//claude:defs.bzl", "CLAUDE_TOOLCHAIN_TYPE")
load(":flags.bzl", "LocalAuthInfo")

def _claude_impl(ctx):
    """Implementation of the claude rule."""
    local_auth = ctx.attr.local_auth[LocalAuthInfo].value
    toolchain = ctx.toolchains[CLAUDE_TOOLCHAIN_TYPE]
    claude_binary = toolchain.claude_info.binary

    # Determine outputs: outs (multiple files) > out (single file) > directory
    if ctx.attr.outs:
        outputs = [ctx.actions.declare_file(f) for f in ctx.attr.outs]
        output_paths = ", ".join([f.path for f in outputs])
        output_instruction = " Write the outputs to these files: " + output_paths
    elif ctx.attr.out:
        outputs = [ctx.actions.declare_file(ctx.attr.out)]
        output_instruction = " Write the output to " + outputs[0].path
    else:
        outputs = [ctx.actions.declare_directory(ctx.label.name)]
        output_instruction = " Write the output to the directory at " + outputs[0].path

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
    full_prompt = full_prompt + output_instruction

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
        outputs = outputs,
        env = env,
        execution_requirements = execution_requirements,
        use_default_shell_env = True,
        mnemonic = "Claude",
        progress_message = "Running Claude: %s" % ctx.label,
    )

    return [DefaultInfo(files = depset(outputs))]

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
            doc = "Output filename. If not specified, outputs to a directory.",
        ),
        "outs": attr.string_list(
            doc = "Multiple output filenames. Takes precedence over out.",
        ),
        "local_auth": attr.label(
            default = "@rules_claude//:local_auth",
            doc = "Flag to enable local auth mode (runs without sandbox, uses real HOME).",
        ),
    },
    toolchains = [CLAUDE_TOOLCHAIN_TYPE],
    doc = "Runs Claude Code with the given prompt and input files to produce an output.",
)
