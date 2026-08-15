This is Phase 00 runtime case J2, the missing-blocking control. Follow these
instructions exactly.

Call `task` exactly once. Use one batch with a non-empty shared context and the
following three items in this exact array order. Every item must set
`isolated: true`.

Item 0 uses agent `phase00-blocking-probe`, name `control-0`, and assignment:

<command>
python -c "import json,time;s=time.time_ns()//1000000;time.sleep(6);e=time.time_ns()//1000000;print(json.dumps({'probe':'phase00-timing-v1','index':0,'started_at_ms':s,'ended_at_ms':e},separators=(',',':')))"
</command>

Item 1 uses agent `phase00-blocking-probe`, name `control-1`, and assignment:

<command>
python -c "import json,time;s=time.time_ns()//1000000;time.sleep(6);e=time.time_ns()//1000000;print(json.dumps({'probe':'phase00-timing-v1','index':1,'started_at_ms':s,'ended_at_ms':e},separators=(',',':')))"
</command>

Item 2 uses agent `phase00-background-probe`, name `control-2`, and assignment:

<command>
python -c "import json,time;s=time.time_ns()//1000000;time.sleep(60);e=time.time_ns()//1000000;print(json.dumps({'probe':'phase00-timing-v1','index':2,'started_at_ms':s,'ended_at_ms':e},separators=(',',':')))"
</command>

The control is specifically testing what the task call returns. Do not call `hub`,
do not wait for a background result, and do not dispatch any additional task. As
soon as the task call returns, immediately answer `J2_PARENT_RETURNED`.
