function RoleCards() {
  const cardStyle = {
    backgroundColor: '#ffffff',
    borderRadius: '16px',
    padding: '30px',
    boxShadow: '0 4px 20px rgba(0,0,0,0.08)',
    textAlign: 'center',
    border:'2px solid #22c55e'
  };

  const headingStyle = {
    fontSize: '1.3rem',
    fontWeight: 'bold',
    marginBottom: '10px',
    color: '#0a0a0a'
  };

  const textStyle = {
    color: '#666',
    fontSize: '0.95rem'
  };

  return (
    <div style={{ backgroundColor: '#f9f9f9', padding: '80px 40px' }}>
      <div style={{
        display: 'grid',
        gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))',
        gap: '30px',
        maxWidth: '1000px',
        margin: '0 auto'
      }}>

        <div style={cardStyle}>
          <h3 style={headingStyle}>For Citizens</h3>
          <p style={textStyle}>Report waste issues, book pickups, earn rewards.</p>
        </div>

        <div style={cardStyle}>
          <h3 style={headingStyle}>For Drivers / Collectors</h3>
          <p style={textStyle}>View assigned routes, mark pickups complete, and get real-time navigation.</p>
        </div>

        <div style={cardStyle}>
          <h3 style={headingStyle}>For Admin / Municipality</h3>
          <p style={textStyle}>Monitor city-wide waste data and manage collector assignments.</p>
        </div>

      </div>
    </div>
  );
}

export default RoleCards;




