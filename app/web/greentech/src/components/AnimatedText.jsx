import { motion } from 'motion/react'

/**
 * Per-character entrance: blur, lift and a slight X rotation.
 *
 * Words are wrapped in nowrap spans so the headline breaks between words and
 * never mid-word, and the whole string is exposed to assistive tech as one
 * label rather than as sixty individual letters.
 */
export function AnimatedText({
  text,
  delay = 0,
  className = 'font-bold text-center text-6xl leading-[0.85] tracking-tighter font-serif text-black lg:text-9xl',
}) {
  const words = text.split(' ')
  let charIndex = 0

  return (
    <motion.span
      className={className}
      initial="hidden"
      animate="visible"
      style={{ perspective: 400, display: 'inline-block' }}
      aria-label={text}
    >
      {words.map((word, wordIndex) => (
        <span key={wordIndex} style={{ display: 'inline-block', whiteSpace: 'nowrap' }} aria-hidden="true">
          {word.split('').map((char, index) => {
            const currentIndex = charIndex++
            return (
              <motion.span
                key={index}
                initial={{ opacity: 0, y: 30, filter: 'blur(12px)', rotateX: -45 }}
                animate={{ opacity: 1, y: 0, filter: 'blur(0px)', rotateX: 0 }}
                transition={{
                  duration: 0.6,
                  delay: delay + currentIndex * 0.035,
                  ease: [0.25, 0.46, 0.45, 0.94],
                }}
                style={{
                  display: 'inline-block',
                  transformStyle: 'preserve-3d',
                  transformOrigin: 'center bottom',
                }}
              >
                {char}
              </motion.span>
            )
          })}
          {wordIndex < words.length - 1 && ' '}
        </span>
      ))}
    </motion.span>
  )
}
