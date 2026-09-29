"""Assertions on the parsed output of sample-logs/asa.log."""
import json
import sys

events = {}
for line in open(sys.argv[1]):
    e = json.loads(line)
    key = (e["event"]["code"], e.get("cisco", {}).get("asa", {}).get("connection_id") or e.get("source", {}).get("ip") or e.get("user", {}).get("name"))
    events[key] = e

def get(e, path):
    for p in path.split("."):
        e = e[p]
    return e

checks = [
    (("302013", "4523311"), {"network.direction": "inbound", "source.ip": "203.0.113.25", "destination.ip": "10.10.20.15",
                             "destination.port": 443, "destination.nat.ip": "198.51.100.10", "event.type": ["connection", "start"]}),
    (("302013", "4523312"), {"network.direction": "outbound", "source.ip": "10.10.20.31", "source.nat.ip": "198.51.100.10",
                             "destination.ip": "93.184.216.34", "destination.port": 443}),
    (("302015", "4523313"), {"network.transport": "udp", "destination.ip": "8.8.8.8", "destination.port": 53}),
    (("106023", "198.51.100.77"), {"event.outcome": "failure", "rule.name": "outside_access_in", "destination.port": 22, "log.level": "warning"}),
    (("106023", "198.51.100.78"), {"network.transport": "icmp", "icmp.type": 8, "icmp.code": 0}),
    (("302014", "4523311"), {"network.bytes": 10234, "event.duration": 65_000_000_000, "event.type": ["connection", "end"]}),
    (("113004", "jdoe"), {"event.outcome": "success", "server.ip": "10.10.1.5", "event.category": "authentication"}),
    (("113015", "198.51.100.90"), {"event.outcome": "failure", "user.name": "admin", "event.reason": "Invalid password"}),
    (("111008", "admin"), {"process.command_line": "write memory", "event.category": "configuration", "log.level": "notification"}),
]

failed = 0
for key, expected in checks:
    e = events.get(key)
    if e is None:
        print(f"MISSING {key}")
        failed += 1
        continue
    bad_tags = [t for t in e.get("tags", []) if "failure" in t and "geoip" not in t]
    if bad_tags:
        print(f"FAIL {key}: tags {bad_tags}")
        failed += 1
    for path, want in expected.items():
        try:
            got = get(e, path)
        except (KeyError, TypeError):
            got = "<missing>"
        if got != want:
            print(f"FAIL {key} {path}: got {got!r}, want {want!r}")
            failed += 1

print(f"{len(events)} events parsed, {len(checks)} checked, {failed} failures")
sys.exit(1 if failed else 0)
