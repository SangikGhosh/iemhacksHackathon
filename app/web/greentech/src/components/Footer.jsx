import logo from '../assets/logo.png';
function Footer() {
  return (
    <div style={{ backgroundColor: '#0a2e1a', color: 'white', paddingTop: '50px' }}>
      
      <div style={{
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'center',
        flexWrap: 'wrap',
        gap: '20px',
        maxWidth: '1100px',
        margin: '0 auto',
        backgroundColor: '#123f26',
        padding: '30px 40px',
        borderRadius: '16px'
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
          <img src={logo} alt="GreenTech Logo" style={{ height: '35px' }} />
          <span style={{ fontWeight: 'bold', fontSize: '1.2rem' }}>GreenTech</span>
        </div>

        <p style={{ fontWeight: '600' }}>Subscribe now</p>

        <input 
          type="email" 
          placeholder="Your email" 
          style={{ padding: '12px 16px', borderRadius: '30px', border: 'none', width: '220px' }} 
        />

        <button style={{
          backgroundColor: '#22c55e',
          color: 'white',
          border: 'none',
          padding: '12px 24px',
          borderRadius: '30px',
          fontWeight: '600',
          cursor: 'pointer'
        }}>
          Subscribe
        </button>
      </div>

      <div style={{
        display: 'grid',
        gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))',
        gap: '40px',
        maxWidth: '1100px',
        margin: '60px auto',
        padding: '0 40px'
      }}>

        <div>
          <h4 style={{ marginBottom: '15px' }}>About</h4>
          <p style={{ color: '#a3a3a3', fontSize: '0.9rem' }}>
            Smart waste management platform improving city cleanliness and recycling participation.
          </p>
        </div>

        <div>
          <h4 style={{ marginBottom: '15px' }}>Links</h4>
          <p style={{ color: '#a3a3a3', fontSize: '0.9rem', marginBottom: '8px' }}>About Us</p>
          <p style={{ color: '#a3a3a3', fontSize: '0.9rem', marginBottom: '8px' }}>Services</p>
          <p style={{ color: '#a3a3a3', fontSize: '0.9rem', marginBottom: '8px' }}>Contact Us</p>
        </div>

        <div>
          <h4 style={{ marginBottom: '15px' }}>Working Hours</h4>
          <p style={{ color: '#a3a3a3', fontSize: '0.9rem', marginBottom: '8px' }}>Mon - Fri: 9:00AM - 6:00PM</p>
          <p style={{ color: '#a3a3a3', fontSize: '0.9rem' }}>Sat - Sun: 9:00AM - 4:00PM</p>
        </div>

        <div>
          <h4 style={{ marginBottom: '15px' }}>Get In Touch</h4>
          <p style={{ color: '#a3a3a3', fontSize: '0.9rem', marginBottom: '8px' }}>Email: info@greentech.com</p>
          <p style={{ color: '#a3a3a3', fontSize: '0.9rem' }}>Phone: 333 666 0000</p>
        </div>

      </div>

      <div style={{ textAlign: 'center', padding: '20px', borderTop: '1px solid #1e5a35', color: '#a3a3a3', fontSize: '0.85rem' }}>
        Copyright 2026 GreenTech. All Rights Reserved.
      </div>

    </div>
  );
}

export default Footer;