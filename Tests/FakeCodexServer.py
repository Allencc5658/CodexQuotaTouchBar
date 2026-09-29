#!/usr/bin/env python3
import json
import os
import sys

assert sys.argv[1:] == ["app-server", "--listen", "stdio://"]

def receive():
    return json.loads(sys.stdin.readline())

def send(message):
    print(json.dumps(message), flush=True)

initialize = receive()
assert initialize["method"] == "initialize"
assert initialize["params"]["clientInfo"]["name"] == "codex_quota_touch_bar"
send({"id": initialize["id"], "result": {"userAgent": "test"}})
if os.environ.get("CODEX_QUOTA_TEST_EXIT_AFTER_INIT") == "1":
    os._exit(0)

assert receive()["method"] == "initialized"
limits_request = receive()
assert limits_request["method"] == "account/rateLimits/read"
plan = os.environ.get("CODEX_QUOTA_TEST_PLAN", "plus")
omit_plan = os.environ.get("CODEX_QUOTA_TEST_NO_PLAN") == "1"
limits = {
    "primary": {"usedPercent": 25, "windowDurationMins": 300, "resetsAt": 2000000000},
    "secondary": {"usedPercent": 40, "windowDurationMins": 10080, "resetsAt": 2000500000}
}
if not omit_plan:
    limits["planType"] = plan
send({"id": limits_request["id"], "result": {
    "rateLimits": {
        **limits
    }
}})
if omit_plan:
    account_request = receive()
    assert account_request["method"] == "account/read"
    assert account_request["params"] == {"refreshToken": False}
    send({"id": account_request["id"], "result": {
        "account": {"type": "chatgpt", "planType": plan, "email": "example@example.com"},
        "requiresOpenaiAuth": True
    }})
else:
    assert sys.stdin.readline() == "", "account/read was requested unnecessarily"
