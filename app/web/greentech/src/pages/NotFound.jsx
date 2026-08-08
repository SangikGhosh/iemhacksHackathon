import { PillButton } from '@/components/ui/pill-button'
import { site } from '@/lib/site'

export default function NotFound() {
  return (
    <main className="flex min-h-svh flex-col items-center justify-center px-6 text-center">
      <img src="/logo-mark.png" alt="" width={56} height={56} className="mb-8 h-14 w-14 object-contain" />

      <p className="mb-3 font-mono text-xs uppercase tracking-[0.2em] text-muted-foreground">
        404 · Not found
      </p>
      <h1 className="mb-4 max-w-lg text-balance font-serif text-4xl font-normal leading-tight md:text-5xl">
        Nothing sorted into this bin
      </h1>
      <p className="mb-9 max-w-md text-pretty leading-relaxed text-muted-foreground">
        The page you asked for does not exist. The scanner, the network map and both admin consoles
        are all reachable from the home page.
      </p>

      <div className="flex flex-col gap-3 sm:flex-row">
        <PillButton href="/" variant="solid">
          Back to {site.name}
        </PillButton>
        <PillButton href={site.links.superAdmin}>Admin consoles</PillButton>
      </div>
    </main>
  )
}
