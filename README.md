# rules_claude

Bazel rules for running Claude Code prompts as build, test, and run actions. Built on top of [tools_claude](https://github.com/buildbuddy-rules/tools_claude), a hermetic, cross-platform Claude Code toolchain that you can use to write your own ruleset.

## Setup

Add the following to your `MODULE.bazel`:

```python
bazel_dep(name = "rules_claude", version = "0.1.0")
git_override(
    module_name = "rules_claude",
    remote = "https://github.com/buildbuddy-rules/rules_claude.git",
    commit = "6c03e1575d6708c45b7279bd4a0941c2e2cdf51b",
)

bazel_dep(name = "tools_claude", version = "0.1.0")
git_override(
    module_name = "tools_claude",
    remote = "https://github.com/buildbuddy-rules/tools_claude.git",
    commit = "bba359bca2d7a675d9f8f0fd0ac537a3415b07de",
)
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

### `claude_run`

Creates an executable that runs Claude Code with the given prompt. Use with `bazel run`.

| Attribute | Type | Description |
|-----------|------|-------------|
| `srcs` | `label_list` | Input files to be processed by the prompt. |
| `prompt` | `string` | **Required.** The prompt to send to Claude. |
| `out` | `string` | Output filename to include in the prompt. |
| `outs` | `string_list` | Multiple output filenames to include in the prompt. |

### `claude_test`

Runs Claude Code with the given prompt as a Bazel test. The agent evaluates the prompt and writes a result file with `PASS` or `FAIL` on the first line, followed by an explanation.

| Attribute | Type | Description |
|-----------|------|-------------|
| `srcs` | `label_list` | Input files to be processed by the prompt. |
| `prompt` | `string` | **Required.** The prompt describing what to test and the pass/fail criteria. |
| `local_auth` | `label` | Flag to enable local auth mode. Defaults to `@rules_claude//:local_auth`. |

## Requirements

- Bazel 7.0+ with bzlmod enabled
- Valid `ANTHROPIC_API_KEY` environment variable, or local authentication enabled
