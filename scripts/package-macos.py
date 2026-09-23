#!/usr/bin/env python3
"""Yerel önizleme paketi üretir; yayınlama, notarization veya kullanıcı verisine erişim yapmaz."""

import hashlib
import json
import plistlib
import subprocess
import tempfile
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def run(*args, **kwargs):
    return subprocess.run([str(arg) for arg in args], check=True, **kwargs)


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def verify_app(app):
    with (app / "Contents/Info.plist").open("rb") as stream:
        info = plistlib.load(stream)
    require(info["CFBundleIdentifier"] == "Game.Game-library", "Beklenmeyen uygulama kimliği")
    require(info["LSMinimumSystemVersion"] == "26.0", "Beklenmeyen minimum macOS sürümü")
    executable = app / "Contents/MacOS" / info["CFBundleExecutable"]
    architectures = run("lipo", "-archs", executable, capture_output=True, text=True).stdout.split()
    require(set(architectures) == {"arm64", "x86_64"}, f"Eksik mimari: {architectures}")
    symbols = run("nm", executable, capture_output=True, text=True).stdout
    require("___llvm_profile_begin_counters" not in symbols, "Release ikili kod kapsamı aracı içeriyor")
    run("codesign", "--verify", "--deep", "--strict", app)
    entitlements = plistlib.loads(
        run("codesign", "-d", "--entitlements", "-", "--xml", app, capture_output=True).stdout
    )
    require(entitlements.get("com.apple.security.app-sandbox") is True, "Sandbox eksik")
    require(entitlements.get("com.apple.security.network.client") is True, "Ağ izni eksik")
    require(not entitlements.get("com.apple.security.get-task-allow", False), "Debugger yetkisi açık")
    return info, architectures


def main():
    stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    output = ROOT / "dist" / ("preview-" + stamp)
    output.mkdir(parents=True, exist_ok=False)  # Önceki paketleri asla ezme.
    print(f"Çıktı: {output}", flush=True)
    with tempfile.TemporaryDirectory(prefix="game-library-package-") as temporary:
        work = Path(temporary)
        with (output / "build.log").open("w") as log:
            run("xcodebuild", "-project", ROOT / "Game library/Game library.xcodeproj",
                "-scheme", "Game library", "-configuration", "Release",
                "-destination", "generic/platform=macOS", "-derivedDataPath", work / "build",
                "ARCHS=arm64 x86_64", "ONLY_ACTIVE_ARCH=NO", "CODE_SIGN_IDENTITY=-",
                "CODE_SIGN_STYLE=Manual", "DEVELOPMENT_TEAM=", "ENABLE_HARDENED_RUNTIME=YES",
                "CODE_SIGN_INJECT_BASE_ENTITLEMENTS=NO", "ENABLE_CODE_COVERAGE=NO",
                f"CODE_SIGN_ENTITLEMENTS={ROOT / 'scripts/preview.entitlements'}",
                "build", stdout=log, stderr=subprocess.STDOUT)
        stage = work / "stage"
        stage.mkdir()
        app = stage / "Game library.app"
        run("ditto", work / "build/Build/Products/Release/Game library.app", app)
        info, architectures = verify_app(app)
        for document in ["kurulum-macos.md", "surum-notlari-1.0-onizleme.md"]:
            run("ditto", ROOT / "docs" / document, stage / document)
        (stage / "Applications").symlink_to("/Applications")
        name = f"oyun-kutuphanesi-{info['CFBundleShortVersionString']}-{info['CFBundleVersion']}-preview"
        disk = output / (name + ".dmg")
        archive = output / (name + ".zip")
        run("hdiutil", "create", "-volname", "Oyun Kutuphanesi Preview", "-srcfolder", stage,
            "-format", "UDZO", disk)
        run("ditto", "-c", "-k", "--sequesterRsrc", "--keepParent", app, archive)
        run("hdiutil", "verify", disk)
        # Kullanıcı Applications dizinine dokunmadan DMG'den kurulum kopyasını doğrula.
        mount = work / "mounted"
        mount.mkdir()
        run("hdiutil", "attach", disk, "-readonly", "-nobrowse", "-mountpoint", mount)
        try:
            installed = work / "installed/Game library.app"
            run("ditto", mount / "Game library.app", installed)
            verify_app(installed)
        finally:
            run("hdiutil", "detach", mount)
        extracted = work / "unzipped"
        run("ditto", "-x", "-k", archive, extracted)
        verify_app(extracted / "Game library.app")
        hashes = {p.name: hashlib.sha256(p.read_bytes()).hexdigest() for p in [disk, archive]}
        (output / "SHA256SUMS").write_text("".join(f"{digest}  {name}\n" for name, digest in hashes.items()))
        metadata = {
            "created_at": stamp, "version": info["CFBundleShortVersionString"],
            "build": info["CFBundleVersion"], "minimum_macos": info["LSMinimumSystemVersion"],
            "architectures": architectures, "signing": "ad-hoc", "notarized": False,
            "release_accepted": False, "sha256": hashes,
            "commit": run("git", "-C", ROOT, "rev-parse", "HEAD", capture_output=True, text=True).stdout.strip(),
            "dirty": bool(run("git", "-C", ROOT, "status", "--porcelain", capture_output=True, text=True).stdout),
            "xcode": run("xcodebuild", "-version", capture_output=True, text=True).stdout.strip(),
            "macos": run("sw_vers", "-productVersion", capture_output=True, text=True).stdout.strip(),
        }
        (output / "manifest.json").write_text(json.dumps(metadata, ensure_ascii=False, indent=2) + "\n")
    print("PASS: DMG ve ZIP doğrulandı. Yerel önizleme; notarize edilmiş dağıtım değildir.")


if __name__ == "__main__":
    main()
