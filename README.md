# rules_claude

Bazel rules for running Claude Code prompts as build actions. Built on top of [tools_claude](https://github.com/buildbuddy-rules/tools_claude).

## Setup

Add the following to your `MODULE.bazel`:

```python
bazel_dep(name = "rules_claude", version = "0.1.0")
git_override(
    module_name = "rules_claude",
    remote = "https://github.com/your-org/rules_claude.git",
    commit = "d2d43d6f070ce1b4d7fca43ae186193a7e6bca94",
)
```

Configure your API key in `.bazelrc`:

```
common --action_env=ANTHROPIC_API_KEY
```

Then export the key in your environment:

```bash
export ANTHROPIC_API_KEY=your-api-key
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

## Rule Reference

### `claude`

Runs Claude Code with the given prompt and input files to produce an output.

| Attribute | Type | Description |
|-----------|------|-------------|
| `srcs` | `label_list` | Input files to be processed by the prompt. |
| `prompt` | `string` | **Required.** The prompt to send to Claude. |
| `out` | `string` | Output filename. Defaults to `<name>.txt`. |

## Requirements

- Bazel 7.0+ with bzlmod enabled
- Valid `ANTHROPIC_API_KEY` environment variable
