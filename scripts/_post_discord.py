"""Discord webhook poster for BossWatch releases.

Usage:  python scripts/_post_discord.py VERSION
Reads CHANGELOG.md via scripts/extract_changelog.sh, posts to the
DISCORD_RELEASE_WEBHOOK from .env.

This file is dev-only (not packaged — excluded via .pkgmeta) and posts
the same content used for the git tag annotation.
"""
import os, sys, json, subprocess, urllib.request

def load_env(path=".env"):
    if not os.path.exists(path): return
    for ln in open(path, encoding="utf-8"):
        ln = ln.strip()
        if ln and not ln.startswith("#") and "=" in ln:
            k, v = ln.split("=", 1)
            os.environ.setdefault(k, v)

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("usage: python scripts/_post_discord.py VERSION", file=sys.stderr); sys.exit(2)
    version = sys.argv[1]
    load_env()
    webhook = os.environ.get("DISCORD_RELEASE_WEBHOOK")
    if not webhook:
        print("DISCORD_RELEASE_WEBHOOK not set in .env", file=sys.stderr); sys.exit(1)
    body = subprocess.check_output(
        ["bash", "scripts/extract_changelog.sh", version]
    ).decode("utf-8").strip()
    data = json.dumps({
        "username": "BossWatch Releases",
        "embeds": [{
            "title": f"BossWatch v{version}",
            "url": f"https://github.com/Timikana/BossWatch/releases/tag/v{version}",
            "description": body[:4000],
            "color": 0x3498DB,
        }],
    }).encode("utf-8")
    req = urllib.request.Request(
        webhook, data=data,
        headers={"Content-Type": "application/json", "User-Agent": "BWRelease/1.0"})
    with urllib.request.urlopen(req) as r:
        print("Discord:", r.status)
