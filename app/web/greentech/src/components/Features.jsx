


function Features() {
  const cardStyle = {
    backgroundColor: '#f4f4f5',
    borderRadius: '16px',
    padding: '30px',
    border: '1px solid #e5e5e5',
    textAlign: 'center'
  };

  const headingStyle = {
    fontSize: '1.3rem',
    fontWeight: 'bold',
    marginBottom: '12px',
    color: '#0a0a0a'
  };

  const textStyle = {
    color: '#525252'
  };

  const arrowCircle = {
    width:'45px',
    height:'45px',
    borderRadius:'50%',
    border:'1px solid #ccc',
    display:'flex',
    alignItems:'center',
    justifyContent:'center',
    margin:'20px auto 0',
    color:'#333',
    fontSize:'1.3rem',
  };

  const iconStyle = {
    fontSize: '2.5rem',
    color: '#22c55e',
    marginBottom: '15px'
  };

  return (
    <div style={{ backgroundColor: '#ffffff', padding: '80px 40px', textAlign: 'center' }}>

      <p style={{ color: '#22c55e', fontWeight: '600', marginBottom: '10px' }}>Features Services</p>
      <h2 style={{ fontSize: '2.5rem', fontWeight: '900', marginBottom: '50px', color: '#0a0a0a' }}>
        A wide range of waste disposal features
      </h2>

      <div style={{
        display: 'grid',
        gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))',
        gap: '30px',
        maxWidth: '1100px',
        margin: '0 auto'
      }}>

        <div style={cardStyle}>
            <i className="ri-delete-bin-line" style={iconStyle}></i>
          <h3 style={headingStyle}>Real-Time Reporting</h3>
          <p style={textStyle}>Citizens can report waste issues instantly with photos and location tagging.</p>
          <div style={arrowCircle}><i className="ri-arrow-right-circle-line"></i></div>
        </div>

        <div style={cardStyle}>
            <i className="ri-route-line" style={iconStyle}></i>
          <h3 style={headingStyle}>Smart Route Optimization</h3>
          <p style={textStyle}>Collectors get optimized pickup routes based on live demand and traffic data.</p>
          <div style={arrowCircle}><i className="ri-arrow-right-circle-line"></i></div>
        </div>

        <div style={cardStyle}>
            <i className="ri-dashboard-line" style={iconStyle}></i>
          <h3 style={headingStyle}>Live Dashboard</h3>
          <p style={textStyle}>Municipalities monitor city-wide waste data and collector performance in real time.</p>
          <div style={arrowCircle}><i className="ri-arrow-right-circle-line"></i></div>
        </div>

        <div style={cardStyle}>
            <i className="ri-gift-line" style={iconStyle}></i>
          <h3 style={headingStyle}>Citizen Rewards</h3>
          <p style={textStyle}>Earn points for correct segregation and disposal, redeemable with local partner businesses.</p>
          <div style={arrowCircle}><i className="ri-arrow-right-circle-line"></i></div>
        </div>

        <div style={cardStyle}>
            <i className="ri-recycle-line" style={iconStyle}></i>
          <h3 style={headingStyle}>Recycler Marketplace</h3>
          <p style={textStyle}>Connects recyclers and scrap dealers directly with households and businesses.</p>
          <div style={arrowCircle}><i className="ri-arrow-right-circle-line"></i></div>
        </div>

        <div style={cardStyle}>
            <i className="ri-sensor-line" style={iconStyle}></i>
          <h3 style={headingStyle}>IoT Bin Monitoring</h3>
          <p style={textStyle}>Optional smart sensors track bin fill-levels in real time to feed into route optimization.</p>
          <div style={arrowCircle}><i className="ri-arrow-right-circle-line"></i></div>
        </div>

      </div>
    </div>
  );
}

export default Features;


