import { CardSpotlight } from'./components/CardSpotlight';
import FeatureCard from './components/Features';
import logo from './assets/logo.png';

function App() {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap:'10px', marginBottom:'50px' }}>
      <img src={logo} alt="GreenTech Logo" 
        style={{height:'320px', border:'none',outline:'none', display:'block'}} />

      <h1 style={{ 
        textAlign: 'center', 
        color: '#22c55e', 
        fontSize: '8rem', 
        fontWeight: 'bold', 
        marginBottom: '50px' 
      }}>
        GreenTech
      </h1>

      <div style={{ display: 'flex', gap: '30px', flexWrap: 'wrap', justifyContent: 'center' }}>

        <CardSpotlight className="h-96 w-96">
          <p className="text-5xl font-bold relative z-20 mt-2 text-white">
            For Citizens
          </p>
          <div className="text-neutral-200 mt-4 relative z-20">
            Report waste issues, book pickups, earn rewards.
          </div>
        </CardSpotlight>

        <CardSpotlight className="h-96 w-96">
          <p className="text-5xl font-bold relative z-20 mt-2 text-white">
            For Drivers / Collectors
          </p>
          <div className="text-neutral-200 mt-4 relative z-20">
            View assigned routes, mark pickups complete, and get real-time navigation.
          </div>
        </CardSpotlight>

        <CardSpotlight className="h-96 w-96">
          <p className="text-5xl font-bold relative z-20 mt-2 text-white">
            For Admin / Municipality
          </p>
          <div className="text-neutral-200 mt-4 relative z-20">
            Monitor city-wide waste data and manage collector assignments.
          </div>
        </CardSpotlight>

      </div>
      <div style={{ paddingTop:'50px' }}>
        <FeatureCard />
      </div>
    </div>
  );
}

export default App;