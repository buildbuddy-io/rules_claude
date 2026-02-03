"""Repository rule for downloading the Claude Code CLI binary."""

_CLAUDE_VERSION = "2.1.25"
_CLAUDE_BUCKET_URL = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases"

# SHA256 hashes for the default version (2.1.25)
# To find hashes for other versions, fetch the manifest:
#   curl -s "{BUCKET_URL}/{VERSION}/manifest.json" | jq .
_DEFAULT_HASHES = {
    "darwin_arm64": "1023c0334b0bf99ce7a466adbdb24ed0cae0ce4e1138837238e132b3886dd789",
    "darwin_amd64": "13fc5f92b6fec84b674ac7cf506524323f012cf999740733f7377f6fb46bcfd7",
    "linux_arm64": "38016991376efb8b1a83488800a9589694a6e77a7a920c5e654778c68753c776",
    "linux_amd64": "696135f0eccaf7a4070168845146833fa4fc93a6191fe026a7517af4d2e14fec",
}

# Maps internal platform keys to manifest/download path keys
_PLATFORMS = {
    "darwin_arm64": "darwin-arm64",
    "darwin_amd64": "darwin-x64",
    "linux_arm64": "linux-arm64",
    "linux_amd64": "linux-x64",
}

def _get_platform(repository_ctx):
    """Determine the current platform."""
    os_name = repository_ctx.os.name.lower()
    arch = repository_ctx.os.arch

    if "mac" in os_name or "darwin" in os_name:
        os_key = "darwin"
    elif "linux" in os_name:
        os_key = "linux"
    else:
        fail("Unsupported operating system: {}".format(os_name))

    if arch == "aarch64" or arch == "arm64":
        arch_key = "arm64"
    elif arch == "x86_64" or arch == "amd64":
        arch_key = "amd64"
    else:
        fail("Unsupported architecture: {}".format(arch))

    return "{}_{}".format(os_key, arch_key)

def _get_hash_from_manifest(repository_ctx, version, platform_path):
    """Fetch SHA256 hash from the version manifest."""
    manifest_url = "{}/{}/manifest.json".format(_CLAUDE_BUCKET_URL, version)
    repository_ctx.download(
        url = manifest_url,
        output = "manifest.json",
    )
    manifest = json.decode(repository_ctx.read("manifest.json"))
    repository_ctx.delete("manifest.json")
    return manifest.get(platform_path, {}).get("sha256", "")

def _claude_toolchains_impl(repository_ctx):
    """Download the Claude Code binary for the specified or current platform."""
    # Use specified platform or detect current
    platform = repository_ctx.attr.platform
    if not platform:
        platform = _get_platform(repository_ctx)

    if platform not in _PLATFORMS:
        fail("Unsupported platform: {}".format(platform))

    platform_path = _PLATFORMS[platform]

    # Determine version and hash
    use_latest = repository_ctx.attr.use_latest
    version = repository_ctx.attr.version
    sha256 = repository_ctx.attr.sha256

    if use_latest:
        # Fetch latest version
        repository_ctx.report_progress("Fetching latest Claude Code version...")
        repository_ctx.download(
            url = "{}/latest".format(_CLAUDE_BUCKET_URL),
            output = "version.txt",
        )
        version = repository_ctx.read("version.txt").strip()
        repository_ctx.delete("version.txt")
        # Fetch hash from manifest
        sha256 = _get_hash_from_manifest(repository_ctx, version, platform_path)
    elif not version:
        # Use default version with default hash
        version = _CLAUDE_VERSION
        if not sha256:
            sha256 = _DEFAULT_HASHES.get(platform, "")

    # Download the binary
    binary_url = "{}/{}/{}/claude".format(_CLAUDE_BUCKET_URL, version, platform_path)
    repository_ctx.report_progress("Downloading Claude Code {} for {}".format(version, platform))

    download_kwargs = {
        "url": binary_url,
        "output": "claude",
        "executable": True,
    }
    if sha256:
        download_kwargs["sha256"] = sha256
    repository_ctx.download(**download_kwargs)

    # Write version file for reference
    repository_ctx.file("VERSION", version)

    # Create BUILD file
    repository_ctx.file(
        "BUILD.bazel",
        content = '''
package(default_visibility = ["//visibility:public"])

exports_files(["claude"])
''',
    )

claude_toolchains = repository_rule(
    implementation = _claude_toolchains_impl,
    attrs = {
        "version": attr.string(
            doc = "Version to download. If empty, uses default version.",
        ),
        "platform": attr.string(
            doc = "Platform to download for (e.g., 'darwin_arm64'). If empty, detects current platform.",
        ),
        "sha256": attr.string(
            doc = "SHA256 hash of the binary for this platform.",
        ),
        "use_latest": attr.bool(
            default = False,
            doc = "If true, fetches the latest version instead of the default.",
        ),
    },
    doc = "Downloads the Claude Code CLI binary for the specified platform.",
)

CLAUDE_DEFAULT_VERSION = _CLAUDE_VERSION
CLAUDE_DEFAULT_HASHES = _DEFAULT_HASHES
