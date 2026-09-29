# Cisco ASA firewall logs → Elastic Common Schema with Logstash

A Logstash pipeline that receives Cisco ASA syslog, parses the most common message IDs into
[ECS](https://www.elastic.co/guide/en/ecs/current/index.html) fields, adds GeoIP for public
addresses and writes to the `logs-cisco.asa-<namespace>` data stream.

Tested with Logstash 9.5.0: `scripts/test-pipeline.sh` runs the filter in Docker against
`sample-logs/asa.log` and checks the parsed fields (9/9 events pass).

## Message IDs covered

| ID | Meaning | Key ECS fields |
|---|---|---|
| 302013 / 302015 | TCP / UDP connection built | `source.*`, `destination.*`, `source.nat.*` / `destination.nat.*`, `network.direction`, `network.transport` |
| 302014 / 302016 | TCP / UDP teardown | `network.bytes`, `event.duration` (ns), `cisco.asa.connection_id`, `cisco.asa.termination_reason` |
| 106023 | Denied by access-group | `rule.name`, `event.outcome: failure`, `icmp.type` / `icmp.code` |
| 113004 / 113015 | AAA authentication success / reject | `user.name`, `server.ip`, `event.reason` |
| 111008 | CLI command executed | `user.name`, `process.command_line` |

Every event also gets `observer.*`, `event.code`, `event.severity`, `log.level`, `related.ip` and `related.user`.

### Direction handling

In a "Built" message the `for` side is the initiator on **inbound** connections but the responder on **outbound** ones.
The pipeline maps the two sides to `source` / `destination` according to `network.direction`, and records NAT addresses
only when they differ from the real address.

## Layout

```
pipeline/10-input.conf        UDP + TCP syslog (port 5514 by default)
pipeline/20-filter.conf       header parse, per-message grok, ECS enrichment
pipeline/30-output.conf       Elasticsearch data stream output (API key + CA)
elasticsearch/                ILM policy (hot 1d rollover → warm 7d → delete 90d) and index template
sample-logs/asa.log           sample messages
test/                         stdin input, file output and assertions used by the test script
scripts/test-pipeline.sh      run the filter in Docker and check the output
scripts/load-templates.sh     create the ILM policy and index template
```

## Running

```sh
# 1. Templates and ILM (once)
ES_URL=https://es.example:9200 ES_API_KEY=... ES_CA_CERT=./ca.crt ./scripts/load-templates.sh

# 2. Logstash
docker run -d --name logstash-asa \
  -p 5514:5514/udp -p 5514:5514/tcp \
  -v "$PWD/pipeline:/usr/share/logstash/pipeline:ro" \
  -v "$PWD/ca.crt:/usr/share/logstash/config/certs/ca.crt:ro" \
  -e ES_HOSTS=https://es.example:9200 -e ES_API_KEY=... -e ASA_TIMEZONE=Asia/Dubai \
  docker.elastic.co/logstash/logstash:9.5.0

# 3. On the ASA
#   logging enable
#   logging timestamp
#   logging trap informational
#   logging host inside <logstash-ip> udp/5514
```

The CA certificate must be mounted at the path in `ES_CA_CERT` (default `/usr/share/logstash/config/certs/ca.crt`);
Logstash refuses to start if the file does not exist.

`ASA_TIMEZONE` should match the firewall's clock, because ASA timestamps carry no time zone.
