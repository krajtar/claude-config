import type { On } from 'claude-code'
import { describe, expect, mock, test } from 'claude-code/testing'
import { ALERT_AFTER_MS } from './register'

const HOME = '/home/tester'
const SESSION = 'sess-1'
const STAMP = `${HOME}/.claude/cache-timer/${SESSION}.ts`

function world(on: On, stamp?: string) {
  const clock = mock.clock(on, { now: 1_000_000 })
  mock.env(on, { HOME })
  const writes: Array<{ path: string; text: string }> = []
  const runs: string[][] = []
  const toasts: string[] = []
  on('session.id', async () => ({ value: SESSION }))
  on('fs.read', async () => {
    if (stamp === undefined) throw new Error('missing')
    return { value: stamp }
  })
  on('fs.write', async ($, e) => {
    writes.push({ path: e.path, text: e.text })
    return { value: undefined }
  })
  on('process.run', async ($, e) => {
    runs.push([...e.argv])
    return { value: { exitCode: 0, stdout: e.argv[0] === 'uname' ? 'Darwin\n' : '', stderr: '', isStdoutTruncated: false, isStderrTruncated: false } }
  })
  on('ui.toast', async ($, e) => {
    toasts.push(e.text)
    return { value: undefined }
  })
  on('session.start', async ($, e) => ({ cwd: e.cwd }))
  on('turn.complete', async () => ({ text: '' }))
  on('session.end', async ($, e) => ({ sessionId: e.sessionId }))
  return { clock, writes, runs, toasts }
}

const START = { cwd: '/repo', surface: 'terminal', isInteractive: true } as never
const TURN = { answer: 'ok', durationMs: 10, isAborted: false, turnId: 't1', reason: 'answer' } as never

describe('cache-timer', () => {
  test('stamps the main-loop turn end and alerts once after 55 minutes', async ($, on) => {
    const w = world(on)
    await $.session.start(START)
    await $.turn.complete(TURN)

    expect(w.writes).toEqual([{ path: STAMP, text: '1000\n' }])

    await w.clock.advance(ALERT_AFTER_MS - 60_000)
    expect(w.toasts).toEqual([])

    await w.clock.advance(60_000)
    expect(w.toasts).toEqual(['Prompt cache expires in ~5 min'])
    expect(w.runs.some(argv => argv[0] === 'afplay')).toBe(true)

    await w.clock.advance(ALERT_AFTER_MS)
    expect(w.toasts.length).toBe(1)
  })

  test('a new turn restarts the countdown', async ($, on) => {
    const w = world(on)
    await $.session.start(START)
    await $.turn.complete(TURN)
    await w.clock.advance(ALERT_AFTER_MS - 60_000)
    await $.turn.complete(TURN)
    await w.clock.advance(120_000)
    expect(w.toasts).toEqual([])
  })

  test('subagent turns do not touch the timer', async ($, on) => {
    const w = world(on)
    await $.session.start(START)
    await $.turn.complete({ ...(TURN as object), agentId: 'sub-1' } as never)
    expect(w.writes).toEqual([])
    await w.clock.advance(ALERT_AFTER_MS + 60_000)
    expect(w.toasts).toEqual([])
  })

  test('resumes the countdown from the stamp file after a reload', async ($, on) => {
    const w = world(on, '1000\n')
    await $.session.start(START)
    await w.clock.advance(ALERT_AFTER_MS)
    expect(w.toasts.length).toBe(1)
  })

  test('session end removes the stamp file', async ($, on) => {
    const w = world(on)
    await $.session.start(START)
    await $.session.end({ reason: 'clear', sessionId: SESSION } as never)
    expect(w.runs).toContainEqual(['rm', '-f', STAMP])
  })
})
