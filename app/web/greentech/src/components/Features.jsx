function Features() {
  const cardStyle = {
    backgroundColor: '#1a1a1a',
    borderRadius: '16px',
    padding: '24px',
    minHeight: '140px'
  };

  const headingStyle = {
    fontSize: '1.5rem',
    fontWeight: 'bold',
    marginBottom: '12px'
  };

  const textStyle = {
    color: '#a3a3a3'
  };

  return (
    <div style={{ backgroundColor: '#0a0a0a', padding: '80px 40px', color: 'white' }}>
      
      <h2 style={{ fontSize: '4rem', fontWeight: '900', marginBottom: '20px' }}>
        Features
      </h2>

      <p style={{ 
        fontSize: '1.25rem', 
        color: '#a3a3a3', 
        maxWidth: '600px', 
        lineHeight: '1.6',
        marginBottom: '60px'
      }}>
        Smart waste monitoring designed to improve city cleanliness, 
        collection efficiency, and citizen engagement in near real time.
      </p>

      <div style={{ 
        display: 'grid', 
        gridTemplateColumns: 'repeat(auto-fit, minmax(500px, 1fr))', 
        gap: '30px',
        maxWidth: '1500px'
      }}>

        <div style={cardStyle}>
          <h3 style={headingStyle}>Real-Time Reporting</h3>
          <p style={textStyle}>Citizens can report waste issues instantly with photos and location tagging.</p>
        </div>

        <div style={cardStyle}>
          <h3 style={headingStyle}>Smart Route Optimization</h3>
          <p style={textStyle}>Collectors get optimized pickup routes based on live demand and traffic data.</p>
        </div>

        <div style={cardStyle}>
          <h3 style={headingStyle}>Live Dashboard</h3>
          <p style={textStyle}>Municipalities monitor city-wide waste data and collector performance in real time.</p>
        </div>

        <div style={cardStyle}>
          <h3 style={headingStyle}>Citizen Rewards</h3>
          <p style={textStyle}>Earn points for correct segregation and disposal, redeemable with local partner businesses.</p>
        </div>

        <div style={cardStyle}>
          <h3 style={headingStyle}>Recycler Marketplace</h3>
          <p style={textStyle}>Connects recyclers and scrap dealers directly with households and businesses selling recyclable waste.</p>
        </div>

        <div style={cardStyle}>
          <h3 style={headingStyle}>IoT Bin Monitoring</h3>
          <p style={textStyle}>Optional smart sensors track bin fill-levels in real time to feed into route optimization.</p>
        </div>

      </div>
    </div>
  );
}

export default Features;