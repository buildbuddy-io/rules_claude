"""Public API for Claude rules."""

load("//claude/private:claude.bzl", _claude = "claude")
load("//claude/private:flags.bzl", _LocalAuthInfo = "LocalAuthInfo", _local_auth_flag = "local_auth_flag")
load("//claude/private:test.bzl", _claude_test = "claude_test")

claude = _claude
claude_test = _claude_test
LocalAuthInfo = _LocalAuthInfo
local_auth_flag = _local_auth_flag
