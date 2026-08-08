import { Header } from './components/Header'
import { Hero } from './components/Hero'
import { StatsSection } from './components/StatsSection'
import { MissionSection } from './components/MissionSection'
import { ScannerDemo } from './components/ScannerDemo'
import FeaturesSection from './components/Features'
import { ImpactSection } from './components/Impact'
import { NetworkSection } from './components/NetworkSection'
import { RolesSection } from './components/RolesSection'
import { TechStack } from './components/TechStack'
import { FAQ } from './components/FAQ'
import { Footer } from './components/Footer'

export default function Landing() {
  return (
    <main className="min-h-screen bg-background">
      <Header />
      <Hero />
      <StatsSection />
      <MissionSection />
      <ScannerDemo />
      <FeaturesSection />
      <ImpactSection />
      <NetworkSection />
      <RolesSection />
      <TechStack />
      <FAQ />
      <Footer />
    </main>
  )
}
