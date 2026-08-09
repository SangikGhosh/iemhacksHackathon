import { Mail } from 'lucide-react'
import { Link } from 'react-router-dom'

import { site } from '@/lib/site'
import { GithubIcon, InstagramIcon, LinkedinIcon, XIcon } from './ui/brand-icons'

const footerLinks = {
  Platform: [
    { label: 'How it works', href: '#how-it-works' },
    { label: 'The scanner', href: '#scanner' },
    { label: 'Features', href: '#features' },
    { label: 'Impact', href: '#impact' },
  ],
  Network: [
    { label: 'Maps & routing', href: '#network' },
    { label: 'Collection points', href: '#network' },
    { label: 'Municipalities', href: '#network' },
    { label: 'Architecture', href: '#tech' },
  ],
  Consoles: [
    { label: 'Super Admin', href: site.links.superAdmin, internal: true },
    { label: 'Municipal Admin', href: site.links.municipalAdmin, internal: true },
    { label: 'Roles & access', href: '#consoles' },
    { label: 'FAQ', href: '#faq' },
  ],
  Project: [
    { label: 'Limitations', href: '#tech' },
    { label: 'API docs', href: site.links.docs },
    { label: 'Source', href: site.links.github },
    { label: 'Contact', href: site.links.email },
  ],
}

const socials = [
  { label: 'GitHub', href: site.links.github, Icon: GithubIcon },
  { label: 'X', href: site.links.twitter, Icon: XIcon },
  { label: 'LinkedIn', href: site.links.linkedin, Icon: LinkedinIcon },
  { label: 'Instagram', href: site.links.instagram, Icon: InstagramIcon },
  { label: 'Email', href: site.links.email, Icon: Mail },
]

export function Footer() {
  return (
    <div className="relative">
      <div className="absolute -top-[20vw] left-0 right-0 z-0 h-[50vw] w-full overflow-hidden">
        <img
          src="/images/footer-bg.png"
          alt=""
          aria-hidden="true"
          className="absolute inset-0 h-full w-full object-cover"
        />
      </div>

      <div
        className="pointer-events-none absolute -top-[15vw] left-0 right-0 z-10 flex items-end justify-center overflow-visible"
        aria-hidden="true"
      >
        <h2 className="whitespace-nowrap text-center text-[17vw] font-bold leading-[0.85] tracking-tighter text-white sm:text-[15vw] md:text-[13.5vw] lg:text-[12.5vw]">
          GREENROUTE
        </h2>
      </div>

      <footer id="contact" className="relative z-20 border-t border-border bg-background px-5 py-16 sm:px-6">
        <div className="mx-auto max-w-7xl">
          <div className="mb-12 grid grid-cols-2 gap-8 md:grid-cols-6">
            <div className="col-span-2">
              <div className="mb-4 flex items-center gap-2">
                <img src="/AppLogoMark.png" alt="" width={28} height={28} className="h-7 w-7 object-contain bg-neutral-900 rounded-lg p-0.5" />
                <span className="font-semibold">{site.name}</span>
              </div>
              <p className="mb-2 max-w-xs text-sm leading-relaxed text-muted-foreground text-pretty">
                {site.tagline} A community waste-management and circular-economy platform for{' '}
                {site.region.label}.
              </p>
              <p className="mb-6 text-xs text-muted-foreground">
                155 collection points · 4 municipalities · 16 kinds of waste
              </p>

              <div className="flex flex-wrap gap-2.5">
                {socials.map(({ label, href, Icon }) => (
                  <a
                    key={label}
                    href={href}
                    aria-label={label}
                    className="flex h-9 w-9 items-center justify-center rounded-full border border-border text-muted-foreground transition-colors hover:border-foreground/30 hover:text-foreground"
                  >
                    <Icon className="h-4 w-4" />
                  </a>
                ))}
              </div>
            </div>

            {Object.entries(footerLinks).map(([heading, links]) => (
              <div key={heading}>
                <h4 className="mb-3 text-xs font-medium uppercase tracking-wider">{heading}</h4>
                {/* inline-block + padding gives each link a ~25px touch target
                    without changing the visual rhythm of the column. */}
                <ul className="space-y-1.5">
                  {links.map((link) => (
                    <li key={link.label}>
                      {link.internal ? (
                        <Link
                          to={link.href}
                          className="inline-block py-1 text-sm text-muted-foreground transition-colors hover:text-foreground"
                        >
                          {link.label}
                        </Link>
                      ) : (
                        <a
                          href={link.href}
                          className="inline-block py-1 text-sm text-muted-foreground transition-colors hover:text-foreground"
                        >
                          {link.label}
                        </a>
                      )}
                    </li>
                  ))}
                </ul>
              </div>
            ))}
          </div>

          <div className="flex flex-col items-center justify-between gap-3 border-t border-border pt-8 text-center md:flex-row md:text-left">
            <p className="text-xs text-muted-foreground">
              © 2026 {site.name}. Free to use, no ads.
            </p>
            <p className="text-xs text-muted-foreground text-pretty">
              Android 7.0+ · {site.region.label} · collection points are demo data for now
            </p>
          </div>
        </div>
      </footer>
    </div>
  )
}
