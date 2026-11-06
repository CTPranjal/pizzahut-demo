#!/usr/bin/env python3
"""Sends the UC1 QR entry events for demo user PH001 through CleverTap's Upload Events API.
Reads the account ID from Info.plist and the passcode from Secrets.plist (never printed).
Usage: python3 scripts/send_uc1_events.py            (dry run first, then sends)
       python3 scripts/send_uc1_events.py --identity PH002
"""
import json, plistlib, sys, time, urllib.request, urllib.error
from pathlib import Path

root = Path(__file__).resolve().parent.parent / "pizzahutmy"
sec = plistlib.load(open(root / "Secrets.plist", "rb"))
info = plistlib.load(open(root / "Info.plist", "rb"))
acct, passcode = info["CleverTapAccountID"], sec["CLEVERTAP_PASSCODE"]
identity = sys.argv[sys.argv.index("--identity") + 1] if "--identity" in sys.argv else "PH001"
store = "PH-2395730871"
ts = int(time.time())
common = {"Entry Source": "store_qr", "Store ID": store, "Platform": "iOS", "Currency": "MYR"}
body = {"d": [
    {"identity": identity, "type": "event", "evtName": "PizzaHut QR Scanned", "ts": ts, "evtData": common},
    {"identity": identity, "type": "event", "evtName": "PizzaHut Registration Completed", "ts": ts + 1, "evtData": common},
    {"identity": identity, "type": "profile", "ts": ts + 2,
     "profileData": {"PizzaHut Entry Source": "store_qr", "PizzaHut Entry Store ID": store}},
]}

def post(region, dry):
    url = f"https://{region}.api.clevertap.com/1/upload" + ("?dryRun=1" if dry else "")
    req = urllib.request.Request(url, data=json.dumps(body).encode(), method="POST", headers={
        "X-CleverTap-Account-Id": acct, "X-CleverTap-Passcode": passcode, "Content-Type": "application/json"})
    try:
        r = urllib.request.urlopen(req, timeout=20); return r.status, r.read().decode()
    except urllib.error.HTTPError as e: return e.code, e.read().decode()
    except Exception as e: return None, str(e)

for region in ["us1", "eu1", "in1", "sg1", "aps3", "mec1"]:
    code, txt = post(region, True)
    print(f"{region}: dry run -> {code} {txt[:120]}")
    if code == 200 and '"success"' in txt:
        print("sending for real ->", post(region, False))
        break
else:
    print("No region accepted the request. Check the passcode in Secrets.plist.")
