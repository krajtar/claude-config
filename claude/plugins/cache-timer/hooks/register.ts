import type { EngineInterface, Register } from 'claude-code'

// The prompt cache lives for 1 hour after the last request; warn 5 minutes before it lapses.
export const ALERT_AFTER_MS = 55 * 60 * 1000
const TICK_MS = 30 * 1000
const MESSAGE = 'Prompt cache expires in ~5 min'

const MAC_SOUND = '/System/Library/Sounds/Submarine.aiff'
const LINUX_SOUND = '/usr/share/sounds/freedesktop/stereo/complete.oga'

type $ = EngineInterface

// The status line reads this file (keyed by its stdin `session_id`) to show the expiry time.
async function stampPath($: $, sessionId?: string): Promise<string> {
  const home = await $.env.get('HOME')
  return `${home}/.claude/cache-timer/${sessionId ?? (await $.session.id())}.ts`
}

async function tryRun($: $, argv: readonly string[]): Promise<boolean> {
  try {
    return (await $.process.run(argv)).exitCode === 0
  } catch {
    return false
  }
}

async function alert($: $): Promise<void> {
  $.ui.toast(MESSAGE, { timeoutMs: 30_000 })

  const isMac = await $.process.run(['uname']).then(r => r.stdout.trim() === 'Darwin', () => false)
  if (isMac) {
    await tryRun($, ['osascript', '-e',
      `display notification "${MESSAGE}" with title "Claude Code" subtitle "Cache freshness"`])
  }

  const sound = (await $.env.get('CLAUDE_CACHE_SOUND')) ?? (isMac ? MAC_SOUND : LINUX_SOUND)
  if (sound === '/dev/null') return
  if (isMac) {
    await tryRun($, ['afplay', sound])
    return
  }
  ;(await tryRun($, ['paplay', sound])) || (await tryRun($, ['aplay', sound])) || (await tryRun($, ['beep']))
}

export const register: Register = on => {
  let lastTurnEndMs: number | undefined
  let hasAlerted = false

  on('session.start', async ($, e, next) => {
    // A reload or resume picks up where the previous copy left off.
    try {
      const seconds = Number((await $.fs.read(await stampPath($))).trim())
      if (Number.isFinite(seconds) && seconds > 0) lastTurnEndMs = seconds * 1000
      hasAlerted = lastTurnEndMs !== undefined && (await $.clock.now()) - lastTurnEndMs >= ALERT_AFTER_MS
    } catch {
      lastTurnEndMs = undefined
    }

    $.clock.every(TICK_MS, async () => {
      if (lastTurnEndMs === undefined || hasAlerted) return
      if ((await $.clock.now()) - lastTurnEndMs < ALERT_AFTER_MS) return
      hasAlerted = true
      await alert($)
    })

    return next(e)
  })

  on('turn.complete', async ($, e, next) => {
    // Subagents have their own cache prefixes; only the main loop keeps this session's cache warm.
    if (e.agentId === undefined) {
      lastTurnEndMs = await $.clock.now()
      hasAlerted = false
      await $.fs.write(await stampPath($), `${Math.floor(lastTurnEndMs / 1000)}\n`)
    }
    return next(e)
  })

  on('session.end', async ($, e, next) => {
    await tryRun($, ['rm', '-f', await stampPath($, e.sessionId)])
    lastTurnEndMs = undefined
    hasAlerted = false
    return next(e)
  })
}
