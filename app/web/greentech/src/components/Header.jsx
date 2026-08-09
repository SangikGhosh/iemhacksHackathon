import { useCallback, useEffect, useRef, useState } from 'react'
import { Link } from 'react-router-dom'
import { AnimatePresence, motion } from 'motion/react'
import { ChevronDown, Menu, ShieldCheck, Building2, X } from 'lucide-react'

import { site, adminRoles } from '@/lib/site'
import { cn } from '@/lib/utils'
import { PillButton } from './ui/pill-button'

const navLinks = [
  { label: 'How it works', target: 'how-it-works' },
  { label: 'Scanner', target: 'scanner' },     
  { label: 'Features', target: 'features' },
  { label: 'Network', target: 'network' },
  { label: 'Stack', target: 'tech' },
  { label: 'FAQ', target: 'faq' },
]

const adminIcons = { super: ShieldCheck, municipal: Building2 }

export function Header() {
  const [isOpen, setIsOpen] = useState(false)
  const [isScrolled, setIsScrolled] = useState(false)
  const [activeSection, setActiveSection] = useState('')
  const [adminOpen, setAdminOpen] = useState(false)
  const adminRef = useRef(null)

  useEffect(() => {
    const onScroll = () => setIsScrolled(window.scrollY > 12)
    onScroll()
    window.addEventListener('scroll', onScroll, { passive: true })
    return () => window.removeEventListener('scroll', onScroll)
  }, [])

  /* Scroll spy — highlight the section currently under the header. */
  useEffect(() => {
    const sections = navLinks
      .map((l) => document.getElementById(l.target))
      .filter(Boolean)
    if (!sections.length) return

    const observer = new IntersectionObserver(
      (entries) => {
        const visible = entries
          .filter((e) => e.isIntersecting)
          .sort((a, b) => b.intersectionRatio - a.intersectionRatio)[0]
        if (visible) setActiveSection(visible.target.id)
      },
      { rootMargin: '-20% 0px -70% 0px', threshold: [0, 0.25, 0.5] },
    )

    sections.forEach((s) => observer.observe(s))
    return () => observer.disconnect()
  }, [])

  /* An open mobile sheet must not leave the page scrolling underneath it. */
  useEffect(() => {
    document.body.style.overflow = isOpen ? 'hidden' : ''
    return () => {
      document.body.style.overflow = ''
    }
  }, [isOpen])

  /* Dismiss the admin dropdown on outside click or Escape. */
  useEffect(() => {
    if (!adminOpen) return
    const onClick = (e) => {
      if (adminRef.current && !adminRef.current.contains(e.target)) setAdminOpen(false)
    }
    const onKey = (e) => e.key === 'Escape' && setAdminOpen(false)
    document.addEventListener('mousedown', onClick)
    document.addEventListener('keydown', onKey)
    return () => {
      document.removeEventListener('mousedown', onClick)
      document.removeEventListener('keydown', onKey)
    }
  }, [adminOpen])

  const scrollToSection = useCallback((e, targetId) => {
    e.preventDefault()
    const element = document.getElementById(targetId)
    if (!element) return
    const offsetPosition = element.getBoundingClientRect().top + window.scrollY - 96
    window.scrollTo({ top: offsetPosition, behavior: 'smooth' })
    setIsOpen(false)
  }, [])

  return (
    <header className="fixed inset-x-0 top-0 z-50 px-3 pt-3 sm:px-4 sm:pt-4">
      <div
        className={cn(
          'mx-auto max-w-7xl rounded-2xl border border-border px-4 py-2.5 backdrop-blur-xl transition-all duration-300 sm:px-6',
          /* The hero is a light-skied video, so there is no dark ground to
             invert against — the panel is always present, as in the reference.
             It simply firms up once you leave the top of the page. */
          isOpen
            ? 'bg-white/95 shadow-[0_8px_40px_rgba(0,0,0,0.12)]'
            : isScrolled
              ? 'bg-white/75 shadow-[0_1px_20px_rgba(0,0,0,0.04)]'
              : 'bg-white/60',
        )}
      >
        <div className="flex items-center justify-between gap-4">
          <a
            href="#top"
            onClick={(e) => {
              e.preventDefault()
              window.scrollTo({ top: 0, behavior: 'smooth' })
            }}
            className="flex shrink-0 items-center gap-2"
          >
            {/* The mark is drawn for a light ground, so it rides on a white
                tile — invisible against the scrolled header, a crisp app icon
                against the hero. */}
            <span className="flex h-8 w-8 shrink-0 items-center justify-center rounded-lg bg-neutral-900 p-0.6 shadow-sm">
              <img src="/AppLogoMark.png" alt="" width={28} height={28} className="h-full w-full object-contain bg-neutral-900 rounded-lg p-0.5" />
            </span>
            <span className="text-lg font-semibold tracking-tight">{site.name}</span>
          </a>

          <nav className="hidden items-center gap-7 lg:flex">
            {navLinks.map((link) => (
              <a
                key={link.target}
                href={`#${link.target}`}
                onClick={(e) => scrollToSection(e, link.target)}
                className={cn(
                  'relative text-sm transition-colors',
                  activeSection === link.target
                    ? 'text-foreground'
                    : 'text-muted-foreground hover:text-foreground',
                )}
              >
                {link.label}
                {activeSection === link.target && (
                  <motion.span
                    layoutId="nav-active"
                    className="absolute -bottom-1.5 left-0 right-0 h-px bg-brand-600"
                    transition={{ type: 'spring', stiffness: 380, damping: 30 }}
                  />
                )}
              </a>
            ))}
          </nav>

          <div className="hidden items-center gap-2 lg:flex">
            <div className="relative" ref={adminRef}>
              <button
                onClick={() => setAdminOpen((v) => !v)}
                aria-expanded={adminOpen}
                aria-haspopup="menu"
                className="flex items-center gap-1.5 rounded-full px-3 py-2 text-sm text-muted-foreground transition-colors hover:text-foreground"
              >
                Consoles
                <ChevronDown
                  className={cn('h-3.5 w-3.5 transition-transform duration-200', adminOpen && 'rotate-180')}
                />
              </button>

              <AnimatePresence>
                {adminOpen && (
                  <motion.div
                    initial={{ opacity: 0, y: 8, scale: 0.97 }}
                    animate={{ opacity: 1, y: 0, scale: 1 }}
                    exit={{ opacity: 0, y: 8, scale: 0.97 }}
                    transition={{ duration: 0.16, ease: 'easeOut' }}
                    role="menu"
                    className="absolute right-0 top-full mt-2 w-72 overflow-hidden rounded-2xl border border-border bg-white p-1.5 shadow-[0_12px_40px_rgba(0,0,0,0.1)]"
                  >
                    {adminRoles.map((role) => {
                      const Icon = adminIcons[role.key]
                      return (
                        <Link
                          key={role.key}
                          to={role.href}
                          role="menuitem"
                          onClick={() => setAdminOpen(false)}
                          className="flex items-start gap-3 rounded-xl p-3 transition-colors hover:bg-muted"
                        >
                          <span className="mt-0.5 flex h-8 w-8 shrink-0 items-center justify-center rounded-lg bg-brand-50 text-brand-700">
                            <Icon className="h-4 w-4" strokeWidth={1.75} />
                          </span>
                          <span className="min-w-0">
                            <span className="block text-sm font-medium">{role.title}</span>
                            <span className="mt-0.5 block text-xs leading-snug text-muted-foreground">
                              {role.scope}
                            </span>
                          </span>
                        </Link>
                      )
                    })}
                  </motion.div>
                )}
              </AnimatePresence>
            </div>

            <PillButton href="#how-it-works" className="py-1 pl-5">
              See the flow
            </PillButton>
          </div>

          <button
            aria-label={isOpen ? 'Close menu' : 'Open menu'}
            aria-expanded={isOpen}
            className="-mr-1 p-1 lg:hidden"
            onClick={() => setIsOpen((v) => !v)}
          >
            {isOpen ? <X size={22} /> : <Menu size={22} />}
          </button>
        </div>

        <AnimatePresence>
          {isOpen && (
            <motion.nav
              initial={{ opacity: 0, height: 0 }}
              animate={{ opacity: 1, height: 'auto' }}
              exit={{ opacity: 0, height: 0 }}
              transition={{ duration: 0.22, ease: 'easeOut' }}
              className="overflow-hidden lg:hidden"
            >
              <div className="mt-4 flex max-h-[calc(100vh-8rem)] flex-col gap-1 overflow-y-auto border-t border-border pt-4 pb-2">
                {navLinks.map((link) => (
                  <a
                    key={link.target}
                    href={`#${link.target}`}
                    onClick={(e) => scrollToSection(e, link.target)}
                    className="rounded-lg px-2 py-2.5 text-[15px] text-muted-foreground transition-colors hover:bg-muted hover:text-foreground"
                  >
                    {link.label}
                  </a>
                ))}

                <p className="mt-3 px-2 pb-1 text-xs font-medium uppercase tracking-[0.15em] text-muted-foreground">
                  Consoles
                </p>
                {adminRoles.map((role) => {
                  const Icon = adminIcons[role.key]
                  return (
                    <Link
                      key={role.key}
                      to={role.href}
                      onClick={() => setIsOpen(false)}
                      className="flex items-center gap-3 rounded-lg px-2 py-2.5 text-[15px] transition-colors hover:bg-muted"
                    >
                      <Icon className="h-4 w-4 text-brand-700" strokeWidth={1.75} />
                      {role.title}
                    </Link>
                  )
                })}
              </div>
            </motion.nav>
          )}
        </AnimatePresence>
      </div>
    </header>
  )
}
