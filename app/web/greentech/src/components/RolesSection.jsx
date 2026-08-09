import { motion } from 'motion/react'
import { Link } from 'react-router-dom'
import { ArrowRight, ArrowUpRight, Building2, Recycle, ShieldCheck, Truck, User } from 'lucide-react'

import { adminRoles } from '@/lib/site'
import { GhostWord, Mono, SectionHeading } from './ui/section'
import { BorderBeam } from './ui/border-beam'

const roles = [
  {
    icon: User,
    name: 'CITIZEN',
    title: 'Citizen',
    body: 'Scans waste, earns points, requests a doorstep pickup or drops at a marked point.',
    selfAssign: true,
  },
  {
    icon: Truck,
    name: 'COLLECTOR',
    title: 'Collector',
    body: 'Sees the open feed, claims pickups, follows an optimised route and weighs on arrival.',
    selfAssign: true,
  },
  {
    icon: Recycle,
    name: 'RECYCLER',
    title: 'Recycler',
    body: 'Takes the sorted output at the end of the chain, where segregated material has value.',
    selfAssign: true,
  },
  {
    icon: Building2,
    name: 'MUNICIPAL_ADMIN',
    title: 'Municipal Admin',
    body: 'Runs one municipality: its depot, its collection points and its collector fleet.',
    selfAssign: false,
  },
  {
    icon: ShieldCheck,
    name: 'SUPER_ADMIN',
    title: 'Super Admin',
    body: 'Platform-wide oversight across every municipality, user and service.',
    selfAssign: false,
  },
]

export function RolesSection() {
  return (
    <section id="consoles" className="relative overflow-hidden bg-muted/40 px-5 py-24 sm:px-6 md:py-32">
      <GhostWord className="opacity-70">ROLES</GhostWord>

      <div className="relative z-10 mx-auto max-w-7xl">
        <SectionHeading
          eyebrow="Access"
          title="Five roles, one account"
          subtitle="Your role decides what you see once you are in. The first three you pick for yourself at signup — the two admin roles are assigned by the platform team."
        />

        <div className="mb-20 grid gap-4 sm:grid-cols-2 lg:grid-cols-5">
          {roles.map((role, i) => (
            <motion.div
              key={role.name}
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.45, delay: i * 0.08 }}
              viewport={{ once: true, margin: '-60px' }}
              className="flex flex-col rounded-2xl border border-border bg-card p-5 transition-colors duration-300 hover:border-foreground/20"
            >
              <span className="mb-4 flex h-10 w-10 items-center justify-center rounded-xl bg-gradient-to-br from-brand-50 to-white ring-1 ring-border">
                <role.icon className="h-[18px] w-[18px] text-brand-700" strokeWidth={1.6} />
              </span>
              <h3 className="mb-1.5 font-medium">{role.title}</h3>
              <p className="mb-4 flex-1 text-sm leading-relaxed text-muted-foreground text-pretty">
                {role.body}
              </p>
              <div className="flex items-center justify-between gap-2 border-t border-border pt-3">
                <Mono className="text-[0.68em]">{role.name}</Mono>
                <span
                  className={
                    role.selfAssign
                      ? 'text-[10px] uppercase tracking-wide text-brand-700'
                      : 'text-[10px] uppercase tracking-wide text-muted-foreground'
                  }
                >
                  {role.selfAssign ? 'Self-serve' : 'Assigned'}
                </span>
              </div>
            </motion.div>
          ))}
        </div>

        {/* Console entry points */}
        <div className="mb-10 text-center">
          <h3 className="mb-3 font-serif text-3xl font-normal text-balance md:text-4xl">
            Two admin consoles
          </h3>
          <p className="mx-auto max-w-2xl leading-relaxed text-muted-foreground text-pretty">
            Both are presentation-only in this build — the layouts, states and data shapes are real,
            but nothing is wired to a backend.
          </p>
        </div>

        <div className="grid gap-6 md:grid-cols-2">
          {adminRoles.map((console, i) => {
            const Icon = console.key === 'super' ? ShieldCheck : Building2
            return (
              <motion.div
                key={console.key}
                initial={{ opacity: 0, y: 24 }}
                whileInView={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.5, delay: i * 0.12 }}
                viewport={{ once: true, margin: '-60px' }}
              >
                <Link
                  to={console.href}
                  className="group relative flex h-full flex-col overflow-hidden rounded-3xl border border-border bg-card p-8 transition-all duration-300 hover:border-foreground/25 hover:shadow-[0_12px_40px_rgba(0,0,0,0.07)]"
                >
                  <BorderBeam size={140} duration={14} delay={i * 5} />

                  <div className="mb-6 flex items-start justify-between gap-4">
                    <span className="flex h-12 w-12 items-center justify-center rounded-2xl bg-gradient-to-br from-brand-100 to-brand-50 ring-1 ring-border">
                      <Icon className="h-5 w-5 text-brand-800" strokeWidth={1.6} />
                    </span>
                    <ArrowUpRight className="h-5 w-5 text-muted-foreground transition-all duration-300 group-hover:-translate-y-0.5 group-hover:translate-x-0.5 group-hover:text-foreground" />
                  </div>

                  <h4 className="mb-1.5 text-xl font-medium">{console.title}</h4>
                  <p className="mb-4 text-xs uppercase tracking-wider text-brand-700">
                    {console.scope}
                  </p>
                  <p className="text-sm leading-relaxed text-muted-foreground text-pretty">
                    {console.blurb}
                  </p>

                  <span className="mt-6 inline-flex items-center gap-1.5 text-sm font-medium">
                    Open console
                    <ArrowRight className="h-3.5 w-3.5 transition-transform duration-300 group-hover:translate-x-0.5" />
                  </span>
                </Link>
              </motion.div>
            )
          })}
        </div>
      </div>
    </section>
  )
}
