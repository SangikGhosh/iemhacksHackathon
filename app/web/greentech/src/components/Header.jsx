import logo from '../assets/logo.png';

function Header() {
  return (
    <div style={{
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'space-between',
      padding: '20px 60px',
      backgroundColor: '#ffffff',
      borderBottom: '1px solid #e5e5e5'
    }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
        <img src={logo} alt="GreenTech Logo" style={{ height: '40px' }} />
        <span style={{ fontSize: '1.5rem', fontWeight: 'bold', color: '#22c55e' }}>GreenTech</span>
      </div>

      <nav style={{ display: 'flex', gap: '30px' }}>
        <a href="#" style={{ color: '#22c55e', textDecoration: 'none', fontWeight: '600' }}>Home</a>
        <a href="#" style={{ color: '#333', textDecoration: 'none' }}>Services</a>
        <a href="#" style={{ color: '#333', textDecoration: 'none' }}>Features</a>
        <a href="#" style={{ color: '#333', textDecoration: 'none' }}>Contact</a>
      </nav>

      <button style={{
        backgroundColor: '#22c55e',
        color: 'white',
        border: 'none',
        padding: '12px 24px',
        borderRadius: '30px',
        fontWeight: '600',
        cursor: 'pointer'
      }}>
        Get Started
      </button>
    </div>
  );
}

export default Header;


