![rules_claude](rules_claude.png)

# rules_claude

Bazel rules and hermetic toolchain for [Claude Code](https://github.com/anthropics/claude-code) - Anthropic's AI coding assistant CLI. Run Claude prompts as build, test, and run actions, or use the toolchain to write your own rules.

## Setup

Add the following to your `MODULE.bazel`:

```python
bazel_dep(name = "rules_claude", version = "0.1.0")
git_override(
    module_name = "rules_claude",
    remote = "https://github.com/buildbuddy-io/rules_claude.git",
    commit = "850a51b31485d6c0d6ea05f66345e97c0d26833f",
)
```

The toolchain is automatically registered. By default, it downloads version `2.1.25` with SHA256 verification for reproducible builds.

### Pinning a Claude Code version

To pin a specific Claude Code CLI version:

```starlark
claude = use_extension("@rules_claude//claude:extensions.bzl", "claude")
claude.download(version = "2.0.0")
```

### Using the latest version

To always fetch the latest version:

```starlark
claude = use_extension("@rules_claude//claude:extensions.bzl", "claude")
claude.download(use_latest = True)
```

## Usage

```python
load("@rules_claude//claude:defs.bzl", "claude", "claude_run", "claude_test")

# Generate documentation from source files
claude(
    name = "generate_docs",
    srcs = ["src/main.py"],
    prompt = "Generate markdown documentation for this Python module.",
    out = "docs.md",
)

# Run a prompt with no input files
claude(
    name = "hello",
    prompt = "Write a haiku about build systems.",
)

# Summarize multiple files
claude(
    name = "summary",
    srcs = [
        "file1.txt",
        "file2.txt",
    ],
    prompt = "Summarize the key points from these files.",
    out = "summary.md",
)

# Generate a complete static marketing website from a README
claude(
    name = "website",
    srcs = ["README.md"],
    prompt = "Generate a complete static marketing website based on this README.",
)

# Interactively refactor code with `bazel run`
claude_run(
    name = "modernize",
    srcs = glob(["src/**/*.py"]),
    prompt = "Refactor this code to use modern Python 3.12 features like pattern matching and type hints.",
)

# Deploy interactively
claude_run(
    name = "deploy",
    srcs = ["main.go"],
    prompt = "Deploy this app to Google Cloud Run. Ask me for any credentials you need and give me links to where I can find them.",
    interactive = True,
)

# Test that documentation is accurate
claude_test(
    name = "validate_readme",
    srcs = ["README.md"],
    prompt = "Walk through this README and verify all the steps work correctly.",
)
```

## Authentication

Claude Code requires an `ANTHROPIC_API_KEY` to function. Since Bazel runs actions in a sandbox, you need to explicitly pass the API key through using `--action_env`.

### Option 1: Pass from environment

To pass the API key from your shell environment, add to your `.bazelrc`:

```
common --action_env=ANTHROPIC_API_KEY
```

Then ensure `ANTHROPIC_API_KEY` is set in your shell before running Bazel.

### Option 2: Hardcode in user.bazelrc

For convenience, you can hardcode the API key in a `user.bazelrc` file that is gitignored:

1. Add `user.bazelrc` to your `.gitignore`:
   ```
   echo "user.bazelrc" >> .gitignore
   ```

2. Create a `.bazelrc` that imports `user.bazelrc`:
   ```
   echo "try-import %workspace%/user.bazelrc" >> .bazelrc
   ```

3. Create `user.bazelrc` with your API key:
   ```
   common --action_env=ANTHROPIC_API_KEY=sk-ant-...
   ```

### Option 3: Local Authentication

As an alternative to providing an API key, you can use local authentication to run Claude with your existing local credentials. This is useful when you already have Claude Code configured on your machine.

Enable local auth mode by adding this config to your `.bazelrc`:

```
common:local_auth --@rules_claude//:local_auth
common:local_auth --action_env=USER
```

Then use:

```bash
bazel build //my:target --config=local_auth
```

When local auth is enabled:
- The action runs locally (not sandboxed)
- Your real `HOME` and `USER` environment variables are used, allowing Claude to access your local configuration and credentials

## Rule Reference

### `claude`

Runs Claude Code with the given prompt and input files to produce an output.

| Attribute | Type | Description |
|-----------|------|-------------|
| `srcs` | `label_list` | Input files to be processed by the prompt. |
| `prompt` | `string` | **Required.** The prompt to send to Claude. |
| `out` | `string` | Output filename. If not specified, outputs to a directory. |
| `outs` | `string_list` | Multiple output filenames. Takes precedence over `out`. |
| `local_auth` | `label` | Flag to enable local auth mode. Defaults to `@rules_claude//:local_auth`. |
| `allowed_tools` | `string_list` | List of allowed tools. If empty, uses `--dangerously-skip-permissions`. See [permissions settings](https://docs.anthropic.com/en/docs/claude-code/settings#permissions-settings). |

### `claude_run`

Creates an executable that runs Claude Code with the given prompt. Use with `bazel run`.

| Attribute | Type | Description |
|-----------|------|-------------|
| `srcs` | `label_list` | Input files to be processed by the prompt. |
| `prompt` | `string` | **Required.** The prompt to send to Claude. |
| `out` | `string` | Output filename to include in the prompt. |
| `outs` | `string_list` | Multiple output filenames to include in the prompt. |
| `allowed_tools` | `string_list` | List of allowed tools. If empty, uses `--dangerously-skip-permissions`. See [permissions settings](https://docs.anthropic.com/en/docs/claude-code/settings#permissions-settings). |

### `claude_test`

Runs Claude Code with the given prompt as a Bazel test. The agent evaluates the prompt and writes a result file with `PASS` or `FAIL` on the first line, followed by an explanation.

| Attribute | Type | Description |
|-----------|------|-------------|
| `srcs` | `label_list` | Input files to be processed by the prompt. |
| `prompt` | `string` | **Required.** The prompt describing what to test and the pass/fail criteria. |
| `local_auth` | `label` | Flag to enable local auth mode. Defaults to `@rules_claude//:local_auth`. |
| `allowed_tools` | `string_list` | List of allowed tools. If empty, uses `--dangerously-skip-permissions`. See [permissions settings](https://docs.anthropic.com/en/docs/claude-code/settings#permissions-settings). |

## Toolchain API

The rules above are built on a hermetic, cross-platform toolchain that you can use directly to write your own rules.

### In genrule

Use the toolchain in a genrule via `toolchains` and make variable expansion:

```starlark
load("@rules_claude//claude:defs.bzl", "CLAUDE_TOOLCHAIN_TYPE")

genrule(
    name = "my_genrule",
    srcs = ["input.py"],
    outs = ["output.md"],
    cmd = """
        export HOME=.home
        $(CLAUDE_BINARY) --dangerously-skip-permissions -p \
            'Read $(location input.py) and write API documentation to $@'
    """,
    toolchains = [CLAUDE_TOOLCHAIN_TYPE],
)
```

The `$(CLAUDE_BINARY)` make variable expands to the path of the Claude Code binary.

**Note:** The `export HOME=.home` line is required because Bazel runs genrules in a sandbox where the real home directory is not writable. Claude Code writes configuration and debug files to `$HOME`, so redirecting it to a writable location within the sandbox prevents permission errors. The `--dangerously-skip-permissions` flag allows Claude to read and write files without interactive approval.

### In custom rules

Use the toolchain in your rule implementation:

```starlark
load("@rules_claude//claude:defs.bzl", "CLAUDE_TOOLCHAIN_TYPE")

def _my_rule_impl(ctx):
    toolchain = ctx.toolchains[CLAUDE_TOOLCHAIN_TYPE]
    claude_binary = toolchain.claude_info.binary

    out = ctx.actions.declare_file(ctx.label.name + ".md")
    ctx.actions.run(
        executable = claude_binary,
        arguments = [
            "--dangerously-skip-permissions",
            "-p",
            "Read {} and write API documentation to {}".format(ctx.file.src.path, out.path),
        ],
        inputs = [ctx.file.src],
        outputs = [out],
        env = {"HOME": ".home"},
        use_default_shell_env = True,
    )
    return [DefaultInfo(files = depset([out]))]

my_rule = rule(
    implementation = _my_rule_impl,
    attrs = {
        "src": attr.label(allow_single_file = True, mandatory = True),
    },
    toolchains = [CLAUDE_TOOLCHAIN_TYPE],
)
```

### In tests

For tests that need to run the Claude binary at runtime, use the runtime toolchain type. This ensures the binary matches the target platform where the test executes:

```starlark
load("@rules_claude//claude:defs.bzl", "CLAUDE_RUNTIME_TOOLCHAIN_TYPE")

def _claude_test_impl(ctx):
    toolchain = ctx.toolchains[CLAUDE_RUNTIME_TOOLCHAIN_TYPE]
    claude_binary = toolchain.claude_info.binary

    test_script = ctx.actions.declare_file(ctx.label.name + ".sh")
    ctx.actions.write(
        output = test_script,
        content = """#!/bin/bash
export HOME="$TEST_TMPDIR"
{claude} --version
""".format(claude = claude_binary.short_path),
        is_executable = True,
    )
    return [DefaultInfo(
        executable = test_script,
        runfiles = ctx.runfiles(files = [claude_binary]),
    )]

claude_test = rule(
    implementation = _claude_test_impl,
    test = True,
    toolchains = [CLAUDE_RUNTIME_TOOLCHAIN_TYPE],
)
```

### Toolchain types

There are two toolchain types depending on your use case:

- **`CLAUDE_TOOLCHAIN_TYPE`** - Use for build-time actions (genrules, custom rules). Selected based on the execution platform. Use this when Claude's output isn't platform-specific.

- **`CLAUDE_RUNTIME_TOOLCHAIN_TYPE`** - Use for tests or run targets where the Claude binary executes on the target platform.

### Public API

From `@rules_claude//claude:defs.bzl`:

| Symbol | Description |
|--------|-------------|
| `claude` | Rule for running Claude prompts as build actions |
| `claude_run` | Rule for running Claude prompts with `bazel run` |
| `claude_test` | Rule for running Claude prompts as tests |
| `CLAUDE_TOOLCHAIN_TYPE` | Toolchain type for build actions (exec platform) |
| `CLAUDE_RUNTIME_TOOLCHAIN_TYPE` | Toolchain type for test/run (target platform) |
| `ClaudeInfo` | Provider with `binary` field containing the Claude Code executable |
| `claude_toolchain` | Rule for defining custom toolchain implementations |
| `LocalAuthInfo` | Provider for local auth flag |
| `local_auth_flag` | Rule for defining local auth build settings |

## Supported platforms

- `darwin_arm64` (macOS Apple Silicon)
- `darwin_amd64` (macOS Intel)
- `linux_arm64`
- `linux_amd64`

## Requirements

- Bazel 7.0+ with bzlmod enabled
- Valid `ANTHROPIC_API_KEY` environment variable, or local authentication enabled

## Acknowledgements

Claude and Claude Code are trademarks of Anthropic, PBC.
