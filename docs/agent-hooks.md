# Agent Hook Setup

`tsm agents` lists every pane running an AI agent. Process detection alone can only tell you an
agent is *running*. To see whether it is working, blocked, or done, the agent has to report its
own state by calling `tsm agent-state <state>` from its hook mechanism.

See [Agent State Hooks](../README.md#agent-state-hooks) for the list of states and what each means.

## Any agent

Any agent that can run a shell command on an event can report state. Map its events onto the
states:

| When | Call |
|------|------|
| the agent starts | `tsm agent-state idle` |
| a turn begins | `tsm agent-state working` |
| it needs input or permission | `tsm agent-state blocked` |
| a turn finishes | `tsm agent-state done` |
| the agent exits | `tsm agent-state clear` |

You do not need all of them. Even `working` and `done` alone make the picker useful.

**NOTE:** Hooks usually run in a non-interactive shell, so `tsm` must be on the PATH that shell
starts with. The same requirement as the tmux keybindings. Use the absolute path
(`$HOME/.local/bin/tsm agent-state idle`) if that is inconvenient.

## Claude Code

Add to `~/.claude/settings.json`:

```json
{
  "hooks": {
    "SessionStart": [
      { "hooks": [{ "type": "command", "command": "tsm agent-state idle" }] }
    ],
    "UserPromptSubmit": [
      { "hooks": [{ "type": "command", "command": "tsm agent-state working" }] }
    ],
    "Notification": [
      { "hooks": [{ "type": "command", "command": "tsm agent-state notification" }] }
    ],
    "Stop": [
      { "hooks": [{ "type": "command", "command": "tsm agent-state done" }] }
    ],
    "SessionEnd": [
      { "hooks": [{ "type": "command", "command": "tsm agent-state clear" }] }
    ]
  }
}
```

`Notification` uses the `notification` pseudo-state rather than a fixed one: the event fires for
several unrelated situations (a permission prompt, sitting idle at the prompt, auth and quota
messages) so `tsm` reads the payload on stdin to work out which happened. Notifications that say
nothing about whether the agent wants you leave the pane's state untouched.
