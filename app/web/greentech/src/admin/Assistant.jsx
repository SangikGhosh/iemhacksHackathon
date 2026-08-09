import { useCallback, useEffect, useRef, useState } from 'react'
import { AnimatePresence, motion } from 'motion/react'
import { Bot, Loader2, MessageSquarePlus, Send, Sparkles, User, X } from 'lucide-react'

import { api } from '@/lib/api'
import { cn } from '@/lib/utils'

function renderInline(text) {
  return text.split(/(\*\*[^*]+\*\*)/g).map((part, i) =>
    part.startsWith('**') && part.endsWith('**') ? (
      <strong key={i} className="font-semibold">
        {part.slice(2, -2)}
      </strong>
    ) : (
      part
    ),
  )
}

function Markdownish({ text }) {
  const lines = text.split('\n')

  return (
    <div className="space-y-1.5">
      {lines.map((line, i) => {
        const trimmed = line.trim()
        if (!trimmed) return null

        const bullet = trimmed.match(/^[-*]\s+(.*)$/)
        if (bullet) {
          return (
            <div key={i} className="flex gap-2 pl-1">
              <span className="mt-[7px] h-1 w-1 shrink-0 rounded-full bg-current opacity-50" />
              <span>{renderInline(bullet[1])}</span>
            </div>
          )
        }

        const numbered = trimmed.match(/^(\d+)\.\s+(.*)$/)
        if (numbered) {
          return (
            <div key={i} className="flex gap-2 pl-1">
              <span className="shrink-0 tabular-nums opacity-60">{numbered[1]}.</span>
              <span>{renderInline(numbered[2])}</span>
            </div>
          )
        }

        return <p key={i}>{renderInline(trimmed)}</p>
      })}
    </div>
  )
}

export function Assistant({ roleLabel }) {
  const [open, setOpen] = useState(false)
  const [messages, setMessages] = useState([])
  const [input, setInput] = useState('')
  const [busy, setBusy] = useState(false)
  const [conversationId, setConversationId] = useState(null)
  const [capabilities, setCapabilities] = useState(null)
  const [error, setError] = useState(null)

  const scroller = useRef(null)
  const field = useRef(null)

  useEffect(() => {
    if (!open || capabilities) return
    let cancelled = false
    api
      .chatCapabilities()
      .then((data) => {
        if (!cancelled) setCapabilities(data)
      })
      .catch(() => {
        if (!cancelled) setCapabilities({ enabled: false, suggestions: [] })
      })
    return () => {
      cancelled = true
    }
  }, [open, capabilities])

  useEffect(() => {
    if (!open) return
    const node = scroller.current
    if (node) node.scrollTop = node.scrollHeight
  }, [messages, busy, open])

  useEffect(() => {
    if (open) field.current?.focus()
  }, [open])

  useEffect(() => {
    const onKey = (e) => {
      if (e.key === 'Escape') setOpen(false)
    }
    document.addEventListener('keydown', onKey)
    return () => document.removeEventListener('keydown', onKey)
  }, [])

  const send = useCallback(
    async (text) => {
      const question = text.trim()
      if (!question || busy) return

      setError(null)
      setInput('')
      setMessages((prev) => [...prev, { author: 'USER', content: question }])
      setBusy(true)

      try {
        const data = await api.chat(question, conversationId)
        setConversationId(data.conversationId)
        setMessages((prev) => [
          ...prev,
          { author: 'ASSISTANT', content: data.reply, toolsUsed: data.toolsUsed },
        ])
      } catch (e) {
        setError(e.message || 'The assistant could not answer that.')
      } finally {
        setBusy(false)
      }
    },
    [busy, conversationId],
  )

  const reset = () => {
    setMessages([])
    setConversationId(null)
    setError(null)
    field.current?.focus()
  }

  const suggestions = capabilities?.suggestions ?? []
  const disabled = capabilities && capabilities.enabled === false

  return (
    <>
      <button
        onClick={() => setOpen((v) => !v)}
        aria-label={open ? 'Close assistant' : 'Open assistant'}
        className={cn(
          'fixed bottom-5 right-5 z-50 flex h-13 items-center gap-2 rounded-full bg-gradient-to-br from-brand-500 to-depot-700 px-4 py-3.5 text-sm font-medium text-white shadow-lg transition-transform hover:scale-105 active:scale-95',
          open && 'scale-0 opacity-0',
        )}
      >
        <Sparkles className="h-4 w-4" />
        Ask GreenTech
      </button>

      <AnimatePresence>
        {open && (
          <motion.div
            initial={{ opacity: 0, y: 16, scale: 0.97 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, y: 16, scale: 0.97 }}
            transition={{ duration: 0.16, ease: 'easeOut' }}
            className="fixed inset-x-3 bottom-3 z-50 flex max-h-[min(640px,calc(100vh-1.5rem))] flex-col overflow-hidden rounded-2xl border border-border bg-white shadow-2xl sm:inset-x-auto sm:right-5 sm:w-[420px]"
          >
            <div className="flex items-center gap-2.5 border-b border-border bg-gradient-to-br from-brand-500 to-depot-700 px-4 py-3 text-white">
              <span className="flex h-8 w-8 items-center justify-center rounded-lg bg-white/15">
                <Bot className="h-4 w-4" />
              </span>
              <div className="min-w-0 flex-1">
                <p className="truncate text-sm font-semibold">GreenTech Assistant</p>
                <p className="truncate text-[11px] text-white/70">{roleLabel}</p>
              </div>
              <button
                onClick={reset}
                title="New conversation"
                aria-label="New conversation"
                className="rounded-lg p-1.5 transition-colors hover:bg-white/15"
              >
                <MessageSquarePlus className="h-4 w-4" />
              </button>
              <button
                onClick={() => setOpen(false)}
                aria-label="Close assistant"
                className="rounded-lg p-1.5 transition-colors hover:bg-white/15"
              >
                <X className="h-4 w-4" />
              </button>
            </div>

            <div ref={scroller} className="flex-1 space-y-3 overflow-y-auto px-4 py-4">
              {messages.length === 0 && (
                <div className="pt-2">
                  <p className="text-sm font-medium">Ask about your data</p>
                  <p className="mt-1 text-xs text-muted-foreground">
                    Every figure comes from a live query, never a guess.
                  </p>
                  <div className="mt-4 space-y-1.5">
                    {suggestions.map((s) => (
                      <button
                        key={s}
                        onClick={() => send(s)}
                        className="block w-full rounded-lg border border-border px-3 py-2 text-left text-[13px] transition-colors hover:border-foreground/25 hover:bg-muted"
                      >
                        {s}
                      </button>
                    ))}
                  </div>
                </div>
              )}

              {messages.map((m, i) => (
                <div
                  key={i}
                  className={cn('flex gap-2.5', m.author === 'USER' && 'flex-row-reverse')}
                >
                  <span
                    className={cn(
                      'mt-0.5 flex h-7 w-7 shrink-0 items-center justify-center rounded-lg',
                      m.author === 'USER'
                        ? 'bg-muted text-muted-foreground'
                        : 'bg-brand-500/10 text-brand-700',
                    )}
                  >
                    {m.author === 'USER' ? <User className="h-3.5 w-3.5" /> : <Bot className="h-3.5 w-3.5" />}
                  </span>
                  <div
                    className={cn(
                      'max-w-[85%] rounded-xl px-3 py-2 text-[13px] leading-relaxed',
                      m.author === 'USER' ? 'bg-muted' : 'border border-border bg-white',
                    )}
                  >
                    <Markdownish text={m.content} />
                    {m.toolsUsed?.length > 0 && (
                      <p className="mt-2 border-t border-border pt-1.5 font-mono text-[10px] text-muted-foreground">
                        {m.toolsUsed.join(' · ')}
                      </p>
                    )}
                  </div>
                </div>
              ))}

              {busy && (
                <div className="flex items-center gap-2 pl-9 text-xs text-muted-foreground">
                  <Loader2 className="h-3.5 w-3.5 animate-spin" />
                  Querying your data…
                </div>
              )}

              {error && (
                <p className="rounded-lg border border-red-200 bg-red-50 px-3 py-2 text-xs text-red-700">
                  {error}
                </p>
              )}

              {disabled && (
                <p className="rounded-lg border border-amber-200 bg-amber-50 px-3 py-2 text-xs text-amber-800">
                  The assistant is not configured on the server. Set LLM_API_KEY in the API
                  environment and restart it.
                </p>
              )}
            </div>

            <form
              onSubmit={(e) => {
                e.preventDefault()
                send(input)
              }}
              className="flex items-center gap-2 border-t border-border px-3 py-2.5"
            >
              <input
                ref={field}
                value={input}
                onChange={(e) => setInput(e.target.value)}
                placeholder="Ask a question…"
                disabled={busy}
                className="flex-1 rounded-full border border-border bg-muted/60 px-3.5 py-2 text-sm outline-none transition-colors placeholder:text-muted-foreground focus:border-foreground/25 focus:bg-white disabled:opacity-60"
              />
              <button
                type="submit"
                disabled={busy || !input.trim()}
                aria-label="Send"
                className="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-gradient-to-br from-brand-500 to-depot-700 text-white transition-opacity disabled:opacity-40"
              >
                <Send className="h-4 w-4" />
              </button>
            </form>
          </motion.div>
        )}
      </AnimatePresence>
    </>
  )
}
