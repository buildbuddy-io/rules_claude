"""Public API for Claude rules."""

load("//claude/private:claude.bzl", _claude = "claude")
load("//claude/private:flags.bzl", _LocalAuthInfo = "LocalAuthInfo", _local_auth_flag = "local_auth_flag")
load("//claude/private:run.bzl", _claude_run = "claude_run")
load("//claude/private:test.bzl", _claude_test = "claude_test")
load(
    "//claude/private:toolchain.bzl",
    _CLAUDE_RUNTIME_TOOLCHAIN_TYPE = "CLAUDE_RUNTIME_TOOLCHAIN_TYPE",
    _CLAUDE_TOOLCHAIN_TYPE = "CLAUDE_TOOLCHAIN_TYPE",
    _ClaudeInfo = "ClaudeInfo",
    _claude_toolchain = "claude_toolchain",
)

# Rules
claude = _claude
claude_run = _claude_run
claude_test = _claude_test

# Flags
LocalAuthInfo = _LocalAuthInfo
local_auth_flag = _local_auth_flag

# Toolchain
claude_toolchain = _claude_toolchain
ClaudeInfo = _ClaudeInfo
CLAUDE_TOOLCHAIN_TYPE = _CLAUDE_TOOLCHAIN_TYPE
CLAUDE_RUNTIME_TOOLCHAIN_TYPE = _CLAUDE_RUNTIME_TOOLCHAIN_TYPE
