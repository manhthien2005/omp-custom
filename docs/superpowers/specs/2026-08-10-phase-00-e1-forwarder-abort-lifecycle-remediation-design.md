# Phase 00 E1 Forwarder Abort-Lifecycle Remediation Design

Date: 2026-08-10  
Status: User-approved for offline implementation  
Scope: E1 evidence harness only  
Provider authorization: None

## 1. Context and decision

`ProviderStrictOffControl` attempt 2 is immutable `INVALID_RUN` with
`E1_FORWARDER_LIFECYCLE_INVALID`. The OMP process exited zero, three provider requests
completed without retry, sanitization passed, cleanup succeeded, and protected surfaces
were unchanged. The forwarder nevertheless recorded only request indexes 1 and 3,
wrote its `closed` record, and then remained alive until the harness timeout killed it.

An offline loopback probe reproduced the same state without credentials or provider
traffic: a downstream client consumed a response prefix and disconnected while the
upstream server deliberately kept the HTTP response open. The current forwarder wrote
`ready` and `closed`, omitted the request projection, emitted no stderr, and did not
exit. The root cause is an orphaned upstream response/request handle combined with
projection persistence that occurs only on upstream response `end`.

The approved decision is to make relay ownership explicit. The forwarder will persist
each projection once response headers establish the gateway status, before relaying
response-body bytes, and will dispose upstream handles when the downstream closes or
shutdown begins.

## 2. Requirements

The remediation must:

1. preserve request and response bytes on the normal relay path;
2. persist exactly one privacy-minimized projection per request after gateway response
   headers are received, even if the downstream later disconnects;
3. preserve monotonically assigned request indexes;
4. track active upstream request/response handles explicitly;
5. destroy an unfinished upstream response/request when its downstream response closes;
6. destroy any remaining active relays when the controller requests shutdown;
7. write exactly one `phase00_e1_forwarder_closed` record and close the evidence writer
   only after the listener is closed and active relays have been disposed;
8. exit zero without timeout, stderr, remaining child processes, or an open port;
9. retain all existing fail-closed lifecycle checks;
10. update every forwarder source hash pin after the behavior is GREEN; and
11. make zero provider calls during remediation and verification.

## 3. Non-goals

This change does not alter prompts, fixtures, assignment text, schemas, the configured
model, the pinned OMP runtime, the pinned upstream source, provider adjudication rules,
the manifest, product/template content, or any immutable raw attempt. It does not
reinterpret attempts 1 or 2, authorize attempt 3, or make strict-on eligible.

## 4. Relay lifecycle design

`runLive` owns a bounded set of active relay handles. `relayRequest` registers an
upstream request when it is created and unregisters it through an idempotent finalizer.
The handle may also own the upstream response after response headers arrive.

When the upstream response callback runs, the forwarder:

1. constructs and synchronously writes the request projection, including the known
   gateway HTTP status;
2. writes response headers to the downstream;
3. relays response bytes unchanged; and
4. finalizes normally when the upstream response ends.

If the downstream closes before the upstream response is complete, its close handler
destroys the upstream response and request, then finalizes the relay. Errors use the
same idempotent finalizer so multiple close/error events cannot write duplicate
projections or retain a handle.

On the `close` control message, shutdown first stops accepting new connections, then
destroys all active upstream handles. The server-close callback writes the single
`closed` record, closes the evidence writer, and resolves the forwarder lifecycle.
Late callbacks cannot write after the writer is closed because active upstreams are
disposed before lifecycle completion and projection persistence occurs at response
header receipt.

## 5. Error behavior

- A request rejected locally before forwarding retains the existing local error path
  and creates no forwarded projection.
- An upstream error before response headers creates no successful gateway-status
  projection and remains fail-closed.
- An upstream response whose headers arrived is projected once; a later downstream
  abort does not erase that fact.
- Shutdown is idempotent. Repeated close signals do not duplicate records.
- Any stderr, non-zero exit, timeout, missing ready/closed record, open port, or
  remaining process continues to invalidate the lifecycle.

## 6. Test-first proof

A new offline regression test will use a disposable loopback gateway that sends a
response prefix but intentionally leaves the upstream response open. The downstream
client will consume the prefix and disconnect, then the test will request forwarder
shutdown.

The RED state must show the current defect: bounded exit wait fails and the request
projection is missing. The GREEN state must prove:

- forwarder exit within the bounded wait;
- exit code zero and empty stderr;
- record order `ready, request_projection, closed`;
- exactly one projection with request index 1 and the gateway status;
- no duplicate projection;
- port closure; and
- disposal of all generated test artifacts.

Existing normal-relay byte-parity and zero-request lifecycle tests must remain GREEN.
After the focused regression passes, verification covers Node syntax, related forwarder
tests, the complete E1 suite in PowerShell 7 and Windows PowerShell, all Phase 00 tests
in both shells, both validators, artifact contract, protected surfaces, raw-evidence
immutability, and zero provider delta.

## 7. Evidence and next gate

The implementation and test chronology, hashes, exact counts, and rejected alternatives
will be appended to the English E1 changelog. Attempts 1 and 2 remain immutable. A new
offline checkpoint may make `ProviderStrictOffControl` attempt 3 eligible, but execution
requires a fresh complete preflight, a new no-overwrite destination, and separate
explicit user authorization.
