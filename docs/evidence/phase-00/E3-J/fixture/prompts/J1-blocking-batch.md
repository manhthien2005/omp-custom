This is Phase 00 runtime case J1. Follow these instructions exactly.

Call `task` exactly once. Use one batch with a non-empty shared context and the
following three items in this exact array order. Every item must use agent
`phase00-blocking-probe`, the given stable name, and `isolated: true`.

Item 0, name `worker-0`, assignment:

<command>
python -c "import json,time;s=time.time_ns()//1000000;time.sleep(18);e=time.time_ns()//1000000;print(json.dumps({'probe':'phase00-timing-v1','index':0,'started_at_ms':s,'ended_at_ms':e},separators=(',',':')))"
</command>

Item 1, name `worker-1`, assignment:

<command>
python -c "import json,time;s=time.time_ns()//1000000;time.sleep(30);e=time.time_ns()//1000000;print(json.dumps({'probe':'phase00-timing-v1','index':1,'started_at_ms':s,'ended_at_ms':e},separators=(',',':')))"
</command>

Item 2, name `worker-2`, assignment:

<command>
python -c "import json,time;s=time.time_ns()//1000000;time.sleep(6);e=time.time_ns()//1000000;print(json.dumps({'probe':'phase00-timing-v1','index':2,'started_at_ms':s,'ended_at_ms':e},separators=(',',':')))"
</command>

Do not call `hub`, do not dispatch any additional task, and do not inspect source
files. When the single task call returns, immediately answer `J1_PARENT_DONE`.
