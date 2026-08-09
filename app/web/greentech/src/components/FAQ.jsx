import { faqs } from '@/lib/site'
import { SectionHeading } from './ui/section'
import { Accordion, AccordionContent, AccordionItem, AccordionTrigger } from './ui/accordion'

export function FAQ() {
  return (
    <section id="faq" className="px-5 pb-56 pt-24 sm:px-6 md:pb-72 md:pt-32">
      <div className="mx-auto max-w-3xl">
        <SectionHeading
          eyebrow="Questions"
          title="Your Questions' Answered"
          subtitle="Including the uncomfortable ones. Where the honest answer is a limitation, that is the answer given."
        />

        <Accordion type="single" collapsible className="border-t border-border">
          {faqs.map((faq, index) => (
            <AccordionItem key={index} value={`item-${index}`}>
              <AccordionTrigger className="text-base">{faq.question}</AccordionTrigger>
              <AccordionContent>
                <p className="text-sm leading-relaxed text-muted-foreground text-pretty">
                  {faq.answer}
                </p>
              </AccordionContent>
            </AccordionItem>
          ))}
        </Accordion>
      </div>
    </section>
  )
}
