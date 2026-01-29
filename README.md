# rules_claude

Bazel rules for running Claude Code prompts as build actions. Built on top of [tools_claude](https://github.com/buildbuddy-rules/tools_claude).

## Setup

Add the following to your `MODULE.bazel`:

```python
bazel_dep(name = "rules_claude", version = "0.1.0")
git_override(
    module_name = "rules_claude",
    remote = "https://github.com/buildbuddy-rules/rules_claude.git",
    commit = "d2d43d6f070ce1b4d7fca43ae186193a7e6bca94",
)
```

## Usage

```python
load("@rules_claude//claude:defs.bzl", "claude")

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
| `out` | `string` | Output filename. Defaults to `<name>.txt`. |
| `local_auth` | `label` | Flag to enable local auth mode. Defaults to `@rules_claude//:local_auth`. |

## Requirements

- Bazel 7.0+ with bzlmod enabled
- Valid `ANTHROPIC_API_KEY` environment variable, or local authentication enabled
