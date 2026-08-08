import hero from '../assets/Hero.png';
function Hero() {
  return (
    <div style={{
      backgroundImage: `linear-gradient(rgba(55, 222, 130, 0.4), rgba(28, 49, 38, 0.4)), url(${hero})`,
      backgroundSize: 'cover',
      backgroundPosition: 'center',
      padding: '100px 40px',
      textAlign: 'center',
      color: 'white'
    }}>
      <h1 style={{ fontSize: '4rem', fontWeight: '900', marginBottom: '10px' }}>
        Our Services
      </h1>
      <p style={{ color: '#a3a3a3', fontSize: '1.1rem' }}>
        Home &gt; Our Services
      </p>
    </div>
  );
}

export default Hero;

