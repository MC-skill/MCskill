#!/usr/bin/env bash
# MC 首启/每次会话初始化：建 ~/.mc，输出档案摘要给宿主注入上下文。任何失败静默退出。
set -uo pipefail
MC="${MC_HOME:-$HOME/.mc}"
mkdir -p "$MC/sessions" "$MC/decisions" "$MC/reports" 2>/dev/null || exit 0
if [ ! -f "$MC/config.json" ]; then
  cat > "$MC/config.json" <<'JSON'
{ "version": 1, "brain": "host", "external_api": { "provider": "", "base_url": "", "model": "", "api_key_env": "" }, "first_run_done": false }
JSON
fi
# 记录安装根目录（原子检索兜底用）；档案已存在则标记首启完成
ROOT="$(cd "$(dirname "$(python3 -c 'import os,sys;print(os.path.realpath(sys.argv[1]))' "$0")")/.." && pwd -P)"
python3 - "$MC/config.json" "$ROOT" "$MC/profile.md" <<'PY' 2>/dev/null || true
import json,sys,os
p,root,prof=sys.argv[1:4]
try: c=json.load(open(p,encoding="utf-8"))
except Exception: c={"version":1,"brain":"host","external_api":{"provider":"","base_url":"","model":"","api_key_env":""}}
c["root"]=root; c["first_run_done"]=os.path.isfile(prof)
json.dump(c,open(p,"w",encoding="utf-8"),ensure_ascii=False,indent=1)
PY
if [ -f "$MC/profile.md" ]; then
  echo "[MC 教练档案摘要]"; head -40 "$MC/profile.md"
else
  echo "[MC 教练] 尚无用户档案。用户第一次开口时，mc-coach 先做 ≤5 问的首次访谈并写入 ~/.mc/profile.md，再路由。"
fi
exit 0
