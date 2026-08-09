import { useEffect, useState } from 'react'
import { Download } from 'lucide-react'

import { site } from '@/lib/site'
import { AnimatedText } from './AnimatedText'

export function Hero() {
  const [isVisible, setIsVisible] = useState(false)
  const [scrollProgress, setScrollProgress] = useState(0)

  useEffect(() => {
    const timer = setTimeout(() => setIsVisible(true), 100)
    return () => clearTimeout(timer)
  }, [])

  /**
   * The backdrop shrinks and rounds as you scroll away from it. Eased toward a
   * target on rAF rather than set directly, so a trackpad flick does not
   * produce a stepped animation.
   */
  useEffect(() => {
    let rafId
    let current = 0

    const handleScroll = () => {
      const target = Math.min(window.scrollY / 400, 1)

      const step = () => {
        current += (target - current) * 0.1
        if (Math.abs(target - current) > 0.001) {
          setScrollProgress(current)
          rafId = requestAnimationFrame(step)
        } else {
          setScrollProgress(target)
        }
      }

      cancelAnimationFrame(rafId)
      step()
    }

    window.addEventListener('scroll', handleScroll, { passive: true })
    return () => {
      window.removeEventListener('scroll', handleScroll)
      cancelAnimationFrame(rafId)
    }
  }, [])

  const easeOutQuad = (t) => t * (2 - t)
  const easeOutCubic = (t) => 1 - Math.pow(1 - t, 3)

  const scale = 1 - easeOutQuad(scrollProgress) * 0.15
  const borderRadius = easeOutCubic(scrollProgress) * 48
  const heightVh = 100 - easeOutQuad(scrollProgress) * 37.5

  return (
    <section
      id="top"
      className="relative flex min-h-screen items-center overflow-hidden px-6 pt-32 pb-12"
    >
      <div className="absolute inset-0 top-0">
        <div
          className="w-full overflow-hidden will-change-transform"
          style={{
            transform: `scale(${scale})`,
            borderRadius: `${borderRadius}px`,
            height: `${heightVh}vh`,
          }}
        >
          <video
            autoPlay
            loop
            muted
            playsInline
            poster="/images/hero-bg.png"
            className="h-full w-full object-cover"
            src="/videos/hero.mp4"
          />
        </div>
      </div>

      <div
        className="pointer-events-none absolute bottom-0 left-0 right-0 z-[5] flex w-full items-end justify-center overflow-hidden"
        style={{
          transform: `translateY(${scrollProgress * 150}px)`,
          opacity: 1 - scrollProgress * 0.8,
          height: '100%',
        }}
      >
        <span className="block select-none text-center text-[17vw] font-bold leading-none tracking-tighter text-white sm:text-[15vw] md:text-[13.5vw] lg:text-[12.5vw]">
          GREENROUTE
        </span>
      </div>

      <div className="relative z-10 mx-auto w-full max-w-7xl">
        <div className="mb-20 text-center">
          <div
            className={`transition-all delay-[800ms] duration-1000 ${
              isVisible ? 'translate-y-0 opacity-100' : '-translate-y-4 opacity-0'
            }`}
          >
            <h1 className="mx-auto mb-6 w-full max-w-4xl text-balance px-4 font-serif leading-normal">
  <AnimatedText
    text="Scan it, Sort it."
    className="block w-full font-bold text-center leading-normal tracking-tighter font-serif text-black text-[4.2rem] sm:text-[6.8rem]"
    delay={0.3}
  />
  <AnimatedText
    text="Get paid for it."
    className="block w-full font-medium text-center leading-normal tracking-tighter font-serif text-black text-[2.2rem] sm:text-[2.7rem] -mt-6"
    delay={0.5}
  />
</h1>
 </div>
        </div>

        <div className="flex flex-col items-center justify-center gap-8">
          <div className="relative">
            <div
              className={`relative w-[234px] will-change-transform transition-all delay-500 duration-[1500ms] ease-out md:w-[281px] lg:w-[351px] ${
                isVisible ? 'translate-y-0 opacity-100' : 'translate-y-[400px] opacity-0'
              }`}
            >
              <img
                src="/images/iphone-frame.png"
                alt="GREENROUTE on Android"
                className="relative z-10 h-auto w-full"
              />

              {/* The frame's screen is already opaque black, so this sits on top
                  of it with no surface of its own. Authored on the same fixed
                  330x691 canvas the frame is cut for, then scaled per
                  breakpoint, so it stays pixel-identical at every phone width. */}
              <div
                className="absolute z-20 overflow-hidden rounded-[21px] md:rounded-[25px] lg:rounded-[32px]"
                style={{ top: '1.2%', bottom: '1.2%', left: '3%', right: '3%' }}
              >
                <div
                  className="flex h-[691px] w-[330px] origin-top-left flex-col items-center justify-center px-8 text-center [--s:0.667] md:[--s:0.8] lg:[--s:1]"
                  style={{ transform: 'scale(var(--s))' }}
                >
                  <span className="flex h-16 w-16 items-center justify-center rounded-2xl bg-white p-1.5 shadow-lg">
                    <img src="/logo-mark.png" alt="" className="h-full w-full object-contain" />
                  </span>

                  <p className="mt-5 text-[19px] font-medium tracking-tight text-white">
                    {site.name}
                  </p>
                  <p className="mt-1.5 text-[12px] leading-relaxed text-white/45">
                    Scan your waste. Earn points.
                    <br />
                    Get it collected.
                  </p>

                  <a
                    href={site.links.playStore}
                    /* Sized on the canvas so it still lands ~32px tall once the
                       0.667 phone scale is applied on small screens. */
                    className="group mt-7 inline-flex items-center gap-2 rounded-full bg-white px-6 py-3.5 text-[13px] font-medium text-zinc-900 transition-transform duration-300 hover:scale-[1.03] active:scale-[0.98]"
                  >
                    <Download className="h-4 w-4 transition-transform duration-300 group-hover:translate-y-0.5" />
                    Download our app
                  </a>

                  <p className="mt-4 text-[10px] tracking-wide text-white/30">
                    Android 7.0+ · Free, no ads
                  </p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  )
}
