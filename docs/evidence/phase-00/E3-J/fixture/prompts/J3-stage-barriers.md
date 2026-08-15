This is Phase 00 runtime case J3. Execute exactly two stage calls.

First, call `task` in its current batch shape with one item. Use shared context
`Phase 00 J3 Verifier barrier`, agent `phase00-blocking-probe`, name `verifier`,
`isolated: true`, and this assignment:

<command>
python -c "import json,time;s=time.time_ns()//1000000;time.sleep(6);e=time.time_ns()//1000000;print(json.dumps({'probe':'phase00-timing-v1','index':0,'started_at_ms':s,'ended_at_ms':e},separators=(',',':')))"
</command>

Do not issue the Reviewer call until the Verifier task call has returned its inline
result.

Second, call `task` in its current batch shape with one item. Use shared context
`Phase 00 J3 Reviewer barrier`, agent `phase00-blocking-probe`, name `reviewer`,
`isolated: true`, and this assignment:

<command>
python -c "import json,time;s=time.time_ns()//1000000;time.sleep(6);e=time.time_ns()//1000000;print(json.dumps({'probe':'phase00-timing-v1','index':1,'started_at_ms':s,'ended_at_ms':e},separators=(',',':')))"
</command>

Do not produce the final response until the Reviewer task call has returned its
inline result. Do not call any other tool. Then answer `J3_FINAL_AFTER_REVIEWER`.
