import { useEffect, useState } from 'react'
import { Download } from 'lucide-react'

import appLogoMark from '@/assets/AppLogoMark.png'
import authScreenImage from '@/assets/AuthScreenImage.jpg'
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
                className="absolute z-20 overflow-hidden rounded-[34px] bg-black md:rounded-[41px] lg:rounded-[51px]"
                style={{ top: '1.2%', bottom: '1.2%', left: '3%', right: '3%' }}
              >
                <img
                  src={authScreenImage}
                  alt=""
                  className="absolute inset-0 h-full w-full object-cover"
                />

                <div
                  className="absolute inset-0"
                  style={{
                    background:
                      'linear-gradient(to bottom, rgba(0,0,0,0.52) 0%, rgba(0,0,0,0.38) 28%, rgba(0,0,0,0.5) 74%, rgba(0,0,0,0.85) 100%)',
                  }}
                />

                <div
                  className="absolute top-0 left-0 h-[691px] w-[330px] origin-top-left [--s:0.667] md:[--s:0.8] lg:[--s:1]"
                  style={{ transform: 'scale(var(--s))' }}
                >
                  <div className="relative h-full w-full">
                    <div className="relative flex h-full flex-col px-6 pt-6 pb-7 text-center">
                      <div className="flex-[3]" />

                      <img src={appLogoMark} alt="" className="mx-auto w-[34px]" />

                      <p className="mt-5 text-[36px] font-bold leading-none tracking-[-1.4px] text-white">
                        {site.name}
                      </p>

                      <p className="mt-[18px] text-[25px] font-extralight leading-[1.28] tracking-[-0.6px] text-white">
                        Manage your waste,
                        <br />
                        build our future.
                      </p>

                      <div className="flex-[2]" />

                      <a
                        href={site.links.apk}
                        download
                        className="group flex h-14 items-center justify-center gap-2.5 rounded-full bg-white text-[16.5px] font-semibold tracking-[-0.2px] text-zinc-900 transition-transform duration-300 hover:scale-[1.02] active:scale-[0.98]"
                      >
                        <Download className="h-[19px] w-[19px] transition-transform duration-300 group-hover:translate-y-0.5" />
                        Download the app
                      </a>

                      <p className="mt-3.5 text-[12.5px] leading-[1.4] text-white/75">
                        Android 7.0+ · 21 MB APK · Free, no ads.
                        <br />
                        Scan your waste, earn points, get it collected.
                      </p>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  )
}
