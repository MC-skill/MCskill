#!/usr/bin/env bash
# MC 一键安装：桥接全部 skill 到已存在的宿主目录 + 装教练 agent（能装的宿主）+ 初始化 ~/.mc + 打印首启指引。幂等，可重复跑。
set -uo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
SKILLS="$ROOT/skills"
echo "== MC 安装：源 $ROOT"
# 1. skills 桥接（复用 mc-link 脚本；不存在则用最简软链）
if [ -x "$SKILLS/mc-link/scripts/bridge-skill.sh" ]; then
  bash "$SKILLS/mc-link/scripts/bridge-skill.sh" link "$SKILLS" || true
else
  mkdir -p "$HOME/.agents/skills"
  for d in "$SKILLS"/*/; do n=$(basename "$d"); [ -f "$d/SKILL.md" ] || continue
    ln -sfn "$d" "$HOME/.agents/skills/$n"
    for h in .claude .codex .workbuddy .cursor .kimi-code .kimi; do [ -d "$HOME/$h/skills" ] && ln -sfn "$d" "$HOME/$h/skills/$n"; done
  done
fi
# 2. 教练 agent（只装到已存在的宿主）
# 教练默认走 Skill 版（对话内直跑，不卡等待）；子智能体版会让每轮对话黑屏数分钟，故不再默认安装，且清理旧装
if [ -L "$HOME/.claude/agents/mc-coach.md" ] || [ -f "$HOME/.claude/agents/mc-coach.md" ]; then rm -f "$HOME/.claude/agents/mc-coach.md"; echo "· Claude Code：已移除旧版教练子智能体（改用 Skill 版，更快）"; fi
if [ -L "$HOME/.cursor/agents/mc-coach.md" ] || [ -f "$HOME/.cursor/agents/mc-coach.md" ]; then rm -f "$HOME/.cursor/agents/mc-coach.md"; echo "· Cursor：已移除旧版教练子智能体（改用 Skill 版）"; fi
if [ -d "$HOME/.kimi-code" ]; then mkdir -p "$HOME/.kimi-code/agents"; ln -sfn "$ROOT/agents/mc-coach.md" "$HOME/.kimi-code/agents/mc-coach.md"; echo "· Kimi Code CLI：agent 已装到 ~/.kimi-code/agents/（kimi --agent mc-coach；或不装直接 kimi --agent-file $ROOT/agents/mc-coach.md）"; fi
if [ -d "$HOME/.codex" ]; then mkdir -p "$HOME/.codex/agents"; [ -f "$ROOT/compat/codex/mc-coach.toml" ] && cp -n "$ROOT/compat/codex/mc-coach.toml" "$HOME/.codex/agents/mc-coach.toml"; echo "· Codex：agent toml 已放置到 ~/.codex/agents/（features.multi_agent 官方默认开；spawn 不了就把 compat/codex/AGENTS.md.snippet 贴进 AGENTS.md 并用 \$mc-coach skill）"; fi
# 3. 记忆目录与配置
bash "$ROOT/scripts/mc-init.sh" >/dev/null 2>&1 || true
# 4. 首启指引
cat <<'TXT'
== 安装完成。
- Claude Code / Cursor：新开会话，直接说你的处境，或 /mc-coach（Skill 版，对话内直跑）；不知道用哪个：/mc 新手入门
- Codex：$mc-coach 或 /mc
- Kimi Code CLI：kimi --agent mc-coach（或 kimi --agent-file agents/mc-coach.md）；会话里 /skill:mc-coach
- 悟空（钉钉）：无本地 skills 目录约定，去客户端「技能中心 → 上传技能」上传 skills/mc-coach 的 ZIP，或在设置里指定 ~/.agents/skills（若该版本支持）
- WorkBuddy / 豆包 / Trae / 其它：调用 mc-coach 这个 skill，它会先做首次访谈
- 想接外挂脑（DeepSeek/通义/Kimi/Claude API）：编辑 ~/.mc/config.json 的 external_api，并设置对应环境变量密钥
TXT
