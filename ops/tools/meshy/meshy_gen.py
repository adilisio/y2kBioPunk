#!/usr/bin/env python3
"""Generate textured GLB assets from Meshy Text-to-3D using ops/tools/meshy/manifest.json.

Usage (from the repo root):
  py -3 ops/tools/meshy/meshy_gen.py --balance
  py -3 ops/tools/meshy/meshy_gen.py --dry-run
  py -3 ops/tools/meshy/meshy_gen.py --only neon_cicada
  py -3 ops/tools/meshy/meshy_gen.py            # every asset in the manifest

The API key is read from the MESHY_API_KEY environment variable, or from
ops/secrets/meshy.key (gitignored). It is never written to the repo or logs.

Task ids are cached in ops/runs/meshy/<name>.json so a rerun resumes or reuses
finished tasks instead of spending credits again. Pass --regen <name> to force
a new preview+refine for one asset. Outputs land in assets/models/<name>.glb.
"""
import argparse
import json
import os
import sys
import time
import urllib.error
import urllib.request

API = "https://api.meshy.ai"
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
MANIFEST = os.path.join(ROOT, "ops", "tools", "meshy", "manifest.json")
STATE_DIR = os.path.join(ROOT, "ops", "runs", "meshy")
OUT_DIR = os.path.join(ROOT, "assets", "models")
POLL_SECONDS = 10


def load_key():
    key = os.environ.get("MESHY_API_KEY", "").strip()
    if not key:
        p = os.path.join(ROOT, "ops", "secrets", "meshy.key")
        if os.path.exists(p):
            with open(p, encoding="utf-8") as f:
                key = f.read().strip()
    if not key:
        sys.exit("No API key: set MESHY_API_KEY or create ops/secrets/meshy.key")
    return key


def request(key, method, path, body=None):
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(API + path, data=data, method=method)
    req.add_header("Authorization", "Bearer " + key)
    if data is not None:
        req.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(req, timeout=60) as r:
            return json.loads(r.read().decode() or "null")
    except urllib.error.HTTPError as e:
        msg = e.read().decode(errors="replace")
        raise SystemExit("HTTP %d on %s %s: %s" % (e.code, method, path, msg))


def state_path(name):
    return os.path.join(STATE_DIR, name + ".json")


def load_state(name):
    p = state_path(name)
    if os.path.exists(p):
        with open(p, encoding="utf-8") as f:
            return json.load(f)
    return {}


def save_state(name, entry):
    os.makedirs(STATE_DIR, exist_ok=True)
    with open(state_path(name), "w", encoding="utf-8") as f:
        json.dump(entry, f, indent=2)


def wait_task(key, task_id, label):
    last = -1
    while True:
        t = request(key, "GET", "/openapi/v2/text-to-3d/" + task_id)
        status, progress = t.get("status"), t.get("progress", 0)
        if progress != last:
            print("  [%s] %s %s%%" % (label, status, progress), flush=True)
            last = progress
        if status == "SUCCEEDED":
            return t
        if status in ("FAILED", "CANCELED"):
            raise SystemExit("  [%s] task %s %s: %s" % (label, task_id, status, t.get("task_error")))
        time.sleep(POLL_SECONDS)


def download(url, dest):
    tmp = dest + ".part"
    with urllib.request.urlopen(url, timeout=300) as r, open(tmp, "wb") as f:
        while True:
            chunk = r.read(1 << 20)
            if not chunk:
                break
            f.write(chunk)
    os.replace(tmp, dest)


def generate(key, asset, defaults, style, regen):
    name = asset["name"]
    entry = {} if regen else load_state(name)
    out = os.path.join(OUT_DIR, name + ".glb")
    if entry.get("done") and os.path.exists(out) and not regen:
        print("[%s] already generated -> %s" % (name, os.path.relpath(out, ROOT)))
        return

    cfg = dict(defaults)
    cfg.update({k: v for k, v in asset.items() if k in defaults})
    prompt = ("%s. %s" % (asset["prompt"], style))[:800]

    if not entry.get("preview_id"):
        body = {
            "mode": "preview",
            "prompt": prompt,
            "ai_model": cfg["ai_model"],
            "topology": cfg["topology"],
            "should_remesh": cfg["should_remesh"],
            "target_polycount": cfg["target_polycount"],
        }
        entry["preview_id"] = request(key, "POST", "/openapi/v2/text-to-3d", body)["result"]
        save_state(name, entry)
        print("[%s] preview task %s" % (name, entry["preview_id"]))
    wait_task(key, entry["preview_id"], name + " preview")

    if not entry.get("refine_id"):
        body = {
            "mode": "refine",
            "preview_task_id": entry["preview_id"],
            "enable_pbr": cfg["enable_pbr"],
            "texture_resolution": cfg["texture_resolution"],
        }
        if asset.get("texture_prompt"):
            body["texture_prompt"] = asset["texture_prompt"][:800]
        entry["refine_id"] = request(key, "POST", "/openapi/v2/text-to-3d", body)["result"]
        save_state(name, entry)
        print("[%s] refine task %s" % (name, entry["refine_id"]))
    task = wait_task(key, entry["refine_id"], name + " refine")

    glb = (task.get("model_urls") or {}).get("glb")
    if not glb:
        raise SystemExit("[%s] refine succeeded but returned no glb url" % name)
    os.makedirs(OUT_DIR, exist_ok=True)
    download(glb, out)
    entry["done"] = True
    entry["consumed_credits"] = task.get("consumed_credits")
    entry["thumbnail_url"] = task.get("thumbnail_url")
    save_state(name, entry)
    print("[%s] saved %s (%d KB)" % (name, os.path.relpath(out, ROOT), os.path.getsize(out) // 1024))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--only", action="append", help="asset name(s) to generate")
    ap.add_argument("--regen", action="append", default=[], help="force a fresh preview+refine for these names")
    ap.add_argument("--dry-run", action="store_true", help="print prompts and cost estimate, no API calls")
    ap.add_argument("--balance", action="store_true", help="print remaining credits and exit")
    args = ap.parse_args()

    with open(MANIFEST, encoding="utf-8") as f:
        manifest = json.load(f)
    assets = manifest["assets"]
    if args.only:
        assets = [a for a in assets if a["name"] in args.only]
        missing = set(args.only) - set(a["name"] for a in assets)
        if missing:
            sys.exit("unknown asset(s): %s" % sorted(missing))

    if args.dry_run:
        for a in assets:
            print("== %s (%s)\n   %s\n   texture: %s" % (a["name"], a["kind"], a["prompt"], a.get("texture_prompt", "-")))
        print("\n%d assets x ~30 credits (meshy-7.1 preview 20 + refine 10) = ~%d credits" % (len(assets), 30 * len(assets)))
        return

    key = load_key()
    if args.balance:
        print(json.dumps(request(key, "GET", "/openapi/v1/balance"), indent=2))
        return

    for a in assets:
        generate(key, a, manifest["defaults"], manifest["style"], a["name"] in args.regen)


if __name__ == "__main__":
    main()
