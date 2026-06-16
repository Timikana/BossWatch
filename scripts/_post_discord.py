"""Discord webhook poster for BossWatch releases.

Usage:  python scripts/_post_discord.py VERSION

Posts TWO embed messages to DISCORD_RELEASE_WEBHOOK (from .env):
  1. French body, extracted from CHANGELOG.md
  2. English body, extracted from CHANGELOG-EN.md

The *Watch family Discord is bilingual — convention is to publish both
languages for every release. If CHANGELOG-EN.md is missing or empty for
the requested version, the English post is skipped with a warning so
the FR post still goes out.

This file is dev-only (not packaged — excluded via .pkgmeta) and uses
the same content as the git tag annotation.
"""
import os, sys, json, subprocess, urllib.request

def load_env(path=".env"):
    if not os.path.exists(path): return
    for ln in open(path, encoding="utf-8"):
        ln = ln.strip()
        if ln and not ln.startswith("#") and "=" in ln:
            k, v = ln.split("=", 1)
            os.environ.setdefault(k, v)

def extract(path, key):
    """Extract a version block from path. Returns stripped body or empty string."""
    if not os.path.exists(path):
        return ""
    try:
        return subprocess.check_output(
            ["bash", "scripts/extract_changelog.sh", key],
            env={**os.environ, "CHANGELOG_PATH": path}
        ).decode("utf-8").strip()
    except subprocess.CalledProcessError:
        return ""

def post(webhook, title, body, color):
    data = json.dumps({
        "username": "BossWatch Releases",
        "embeds": [{
            "title": title,
            "url": f"https://github.com/Timikana/BossWatch/releases/tag/{title.split()[-1].split(' ')[0].lstrip('v') and 'v' + title.split('v',1)[1].split(' ')[0] or ''}",
            "description": body[:4000],
            "color": color,
        }],
    }).encode("utf-8")
    req = urllib.request.Request(
        webhook, data=data,
        headers={"Content-Type": "application/json", "User-Agent": "BWRelease/1.0"})
    with urllib.request.urlopen(req) as r:
        return r.status

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("usage: python scripts/_post_discord.py VERSION", file=sys.stderr); sys.exit(2)
    version = sys.argv[1]
    load_env()
    webhook = os.environ.get("DISCORD_RELEASE_WEBHOOK")
    if not webhook:
        print("DISCORD_RELEASE_WEBHOOK not set in .env", file=sys.stderr); sys.exit(1)

    # Beta/alpha tags read the [Unreleased] block; stable tags read the
    # versioned block.
    extract_key = "Unreleased" if "-beta" in version or "-alpha" in version else version

    # Distinguish prerelease channels by embed color so users immediately
    # see whether a notification is a stable, beta or alpha release.
    if "-beta" in version:
        color, label = 0xE67E22, " (beta)"
    elif "-alpha" in version:
        color, label = 0x95A5A6, " (alpha)"
    else:
        color, label = 0x3498DB, ""

    url = f"https://github.com/Timikana/BossWatch/releases/tag/v{version}"

    def post_one(title, body):
        data = json.dumps({
            "username": "BossWatch Releases",
            "embeds": [{
                "title": title, "url": url,
                "description": body[:4000], "color": color,
            }],
        }).encode("utf-8")
        req = urllib.request.Request(
            webhook, data=data,
            headers={"Content-Type": "application/json", "User-Agent": "BWRelease/1.0"})
        with urllib.request.urlopen(req) as r:
            return r.status

    # 1) FR — canonical CHANGELOG.md
    fr_body = subprocess.check_output(
        ["bash", "scripts/extract_changelog.sh", extract_key]
    ).decode("utf-8").strip()
    if fr_body:
        print("Discord FR:", post_one(f"BossWatch v{version}{label}", fr_body))
    else:
        print("warning: no FR body found for", extract_key, file=sys.stderr)

    # 2) EN — parallel mirror at CHANGELOG-EN.md (script accepts a path arg
    # via an environment override, but extract_changelog.sh currently
    # hardcodes CHANGELOG.md — so we read+filter inline here).
    en_body = ""
    if os.path.exists("CHANGELOG-EN.md"):
        capture, lines = False, []
        for ln in open("CHANGELOG-EN.md", encoding="utf-8"):
            if ln.startswith("## ["):
                # Header line — match by version key inside brackets.
                inside = ln.split("[", 1)[1].split("]", 1)[0]
                if inside == extract_key:
                    capture = True; continue
                if capture:
                    break
                continue
            if capture:
                lines.append(ln.rstrip("\n"))
        en_body = "\n".join(lines).strip()

    if en_body:
        print("Discord EN:", post_one(f"BossWatch v{version}{label} (English)", en_body))
    else:
        print("warning: no EN body for", extract_key, "— add a block to CHANGELOG-EN.md",
              file=sys.stderr)
