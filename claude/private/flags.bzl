"""Common providers and flags for Claude rules."""

# Flag for enabling local auth mode
LocalAuthInfo = provider(fields = ["value"])

def _local_auth_flag_impl(ctx):
    return LocalAuthInfo(value = ctx.build_setting_value)

local_auth_flag = rule(
    implementation = _local_auth_flag_impl,
    build_setting = config.bool(flag = True),
)
