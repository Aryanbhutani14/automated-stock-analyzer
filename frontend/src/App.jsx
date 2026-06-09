import React, { useState, useEffect } from 'react'
import axios from 'axios'
import './App.css'

function App() {
  // Connection monitoring state
  const [connectionStatus, setConnectionStatus] = useState('pending') // pending, connected, disconnected
  const [backendMessage, setBackendMessage] = useState('Connecting to backend server...')
  const [isRetrying, setIsRetrying] = useState(false)

  // Screener mock stocks data
  const [stocks] = useState([
    { symbol: 'RELIANCE', name: 'Reliance Industries Ltd.', sector: 'Energy', exchange: 'NSE', price: 2450.50, change: 1.25, rsi: 58.4, signal: 'BUY' },
    { symbol: 'TCS', name: 'Tata Consultancy Services', sector: 'IT Services', exchange: 'NSE', price: 3820.00, change: -0.80, rsi: 45.2, signal: 'HOLD' },
    { symbol: 'HDFCBANK', name: 'HDFC Bank Ltd.', sector: 'Banking', exchange: 'NSE', price: 1610.15, change: -2.35, rsi: 28.5, signal: 'BUY' },
    { symbol: 'INFY', name: 'Infosys Ltd.', sector: 'IT Services', exchange: 'NSE', price: 1420.30, change: 3.42, rsi: 71.2, signal: 'SELL' },
    { symbol: 'ICICIBANK', name: 'ICICI Bank Ltd.', sector: 'Banking', exchange: 'NSE', price: 985.40, change: 0.55, rsi: 54.1, signal: 'HOLD' },
    { symbol: 'TATASTEEL', name: 'Tata Steel Ltd.', sector: 'Metals & Mining', exchange: 'BSE', price: 128.60, change: 4.21, rsi: 64.8, signal: 'BUY' },
    { symbol: 'WIPRO', name: 'Wipro Ltd.', sector: 'IT Services', exchange: 'BSE', price: 412.30, change: -1.54, rsi: 35.6, signal: 'HOLD' },
    { symbol: 'ITC', name: 'ITC Ltd.', sector: 'FMCG', exchange: 'NSE', price: 435.00, change: 0.18, rsi: 49.3, signal: 'HOLD' },
    { symbol: 'MARUTI', name: 'Maruti Suzuki India Ltd.', sector: 'Automotive', exchange: 'NSE', price: 9480.00, change: -1.12, rsi: 38.7, signal: 'HOLD' },
    { symbol: 'SBIN', name: 'State Bank of India', sector: 'Banking', exchange: 'NSE', price: 582.45, change: 2.10, rsi: 61.3, signal: 'BUY' },
    { symbol: 'BHARTIARTL', name: 'Bharti Airtel Ltd.', sector: 'Telecom', exchange: 'BSE', price: 875.90, change: -0.45, rsi: 48.9, signal: 'HOLD' },
    { symbol: 'L&T', name: 'Larsen & Toubro Ltd.', sector: 'Construction', exchange: 'NSE', price: 2390.15, change: 1.85, rsi: 67.2, signal: 'BUY' }
  ])

  // Filter States
  const [search, setSearch] = useState('')
  const [exchange, setExchange] = useState('ALL')
  const [selectedSignals, setSelectedSignals] = useState({
    BUY: true,
    SELL: true,
    HOLD: true
  })

  // Check backend connection
  const checkConnection = async () => {
    setIsRetrying(true)
    setConnectionStatus('pending')
    setBackendMessage('Checking API connection...')
    try {
      const response = await axios.get('http://localhost:8080/api/health')
      if (response.data && response.data.status === 'UP') {
        setConnectionStatus('connected')
        setBackendMessage(response.data.message || 'Connection established successfully!')
      } else {
        setConnectionStatus('disconnected')
        setBackendMessage('Backend responded with unexpected status.')
      }
    } catch (error) {
      setConnectionStatus('disconnected')
      setBackendMessage('Unable to reach Spring Boot server. Please start the backend.')
    } finally {
      setIsRetrying(false)
    }
  }

  useEffect(() => {
    checkConnection()
  }, [])

  // Filter Logic
  const handleSignalChange = (type) => {
    setSelectedSignals(prev => ({
      ...prev,
      [type]: !prev[type]
    }))
  }

  const filteredStocks = stocks.filter(stock => {
    const matchesSearch = stock.symbol.toLowerCase().includes(search.toLowerCase()) || 
                          stock.name.toLowerCase().includes(search.toLowerCase()) ||
                          stock.sector.toLowerCase().includes(search.toLowerCase())
    
    const matchesExchange = exchange === 'ALL' || stock.exchange === exchange
    
    const matchesSignal = selectedSignals[stock.signal]
    
    return matchesSearch && matchesExchange && matchesSignal
  })

  return (
    <div className="dashboard-container">
      {/* Header */}
      <header className="header glass">
        <div className="logo-section">
          <h1 className="text-gradient">STOCK ANALYZER</h1>
          <span>Automated Screener</span>
        </div>
        
        <div className="api-monitor">
          <div className={`status-dot ${connectionStatus}`}></div>
          <span>
            {connectionStatus === 'connected' ? 'API Connected' : 
             connectionStatus === 'pending' ? 'Connecting...' : 'API Offline'}
          </span>
          <button 
            onClick={checkConnection} 
            disabled={isRetrying} 
            className="retry-btn"
          >
            {isRetrying ? 'Retrying...' : 'Test Status'}
          </button>
        </div>
      </header>

      {/* Backend Message Banner */}
      {connectionStatus !== 'connected' && (
        <div className={`glass`} style={{ 
          padding: '12px 20px', 
          borderRadius: 'var(--border-radius-md)', 
          borderLeft: `4px solid ${connectionStatus === 'pending' ? 'var(--accent-warning)' : 'var(--accent-error)'}`,
          fontSize: '14px',
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center'
        }}>
          <span><strong>System Status:</strong> {backendMessage}</span>
          {connectionStatus === 'disconnected' && (
            <span style={{ fontSize: '12px', color: 'var(--text-secondary)' }}>
              Make sure Spring Boot is running on port 8080.
            </span>
          )}
        </div>
      )}

      {/* Stats Cards */}
      <section className="stats-grid">
        <div className="stat-card glass">
          <div className="stat-label">NIFTY 50</div>
          <div className="stat-val text-gradient-indigo">22,350.20</div>
          <div className="stat-change up">
            <svg width="12" height="12" viewBox="0 0 24 24" fill="currentColor">
              <path d="M4 12l1.41 1.41L11 7.83V20h2V7.83l5.58 5.59L20 12l-8-8-8 8z"/>
            </svg>
            +142.15 (+0.64%)
          </div>
        </div>

        <div className="stat-card glass">
          <div className="stat-label">SENSEX</div>
          <div className="stat-val text-gradient-indigo">73,610.45</div>
          <div className="stat-change up">
            <svg width="12" height="12" viewBox="0 0 24 24" fill="currentColor">
              <path d="M4 12l1.41 1.41L11 7.83V20h2V7.83l5.58 5.59L20 12l-8-8-8 8z"/>
            </svg>
            +452.90 (+0.62%)
          </div>
        </div>

        <div className="stat-card glass">
          <div className="stat-label">DOW JONES</div>
          <div className="stat-val text-gradient-indigo">39,120.10</div>
          <div className="stat-change down">
            <svg width="12" height="12" viewBox="0 0 24 24" fill="currentColor">
              <path d="M20 12l-1.41-1.41L13 16.17V4h-2v12.17l-5.58-5.59L4 12l8 8 8-8z"/>
            </svg>
            -84.50 (-0.22%)
          </div>
        </div>
      </section>

      {/* Main Panel layout */}
      <div className="main-layout">
        
        {/* Left Side: Filter Sidebar */}
        <aside className="filter-panel glass">
          <h2 className="panel-title">Screener Filters</h2>
          
          <div className="filter-group">
            <label className="filter-label">Search Ticker / Sector</label>
            <input 
              type="text" 
              placeholder="e.g. RELIANCE, Banking" 
              value={search} 
              onChange={(e) => setSearch(e.target.value)} 
              className="search-input" 
            />
          </div>

          <div className="filter-group">
            <label className="filter-label">Stock Exchange</label>
            <select 
              value={exchange} 
              onChange={(e) => setExchange(e.target.value)}
              className="select-input"
            >
              <option value="ALL">All Exchanges</option>
              <option value="NSE">NSE (National Stock Exchange)</option>
              <option value="BSE">BSE (Bombay Stock Exchange)</option>
            </select>
          </div>

          <div className="filter-group">
            <label className="filter-label">Signal Strategy</label>
            <div className="checkbox-list">
              <label className="checkbox-item">
                <input 
                  type="checkbox" 
                  checked={selectedSignals.BUY} 
                  onChange={() => handleSignalChange('BUY')} 
                />
                <span>BUY Signals</span>
              </label>
              <label className="checkbox-item">
                <input 
                  type="checkbox" 
                  checked={selectedSignals.HOLD} 
                  onChange={() => handleSignalChange('HOLD')} 
                />
                <span>HOLD Signals</span>
              </label>
              <label className="checkbox-item">
                <input 
                  type="checkbox" 
                  checked={selectedSignals.SELL} 
                  onChange={() => handleSignalChange('SELL')} 
                />
                <span>SELL Signals</span>
              </label>
            </div>
          </div>
        </aside>

        {/* Right Side: Data Screener Table */}
        <main className="content-panel glass">
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <h2 className="panel-title" style={{ border: 'none', padding: 0, margin: 0 }}>
              Screener Results ({filteredStocks.length})
            </h2>
            {connectionStatus === 'connected' && (
              <span style={{ fontSize: '11px', color: 'var(--accent-success)', fontWeight: 'bold' }}>
                ● Real-time Sync Active
              </span>
            )}
          </div>

          <div className="table-wrapper">
            {filteredStocks.length > 0 ? (
              <table className="stock-table">
                <thead>
                  <tr>
                    <th>Ticker</th>
                    <th>Exchange</th>
                    <th>Sector</th>
                    <th>Price</th>
                    <th>Change %</th>
                    <th>RSI (14)</th>
                    <th>Signal</th>
                  </tr>
                </thead>
                <tbody>
                  {filteredStocks.map((stock) => (
                    <tr key={stock.symbol}>
                      <td>
                        <div className="ticker-cell">
                          <span className="ticker-sym">{stock.symbol}</span>
                          <span className="ticker-name">{stock.name}</span>
                        </div>
                      </td>
                      <td>{stock.exchange}</td>
                      <td>{stock.sector}</td>
                      <td style={{ fontFamily: 'monospace', fontWeight: 'bold' }}>
                        ₹{stock.price.toLocaleString('en-IN', { minimumFractionDigits: 2 })}
                      </td>
                      <td className={stock.change >= 0 ? 'price-up' : 'price-down'}>
                        {stock.change >= 0 ? '+' : ''}{stock.change.toFixed(2)}%
                      </td>
                      <td>{stock.rsi.toFixed(1)}</td>
                      <td>
                        <span className={`badge ${stock.signal.toLowerCase()}`}>
                          {stock.signal}
                        </span>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            ) : (
              <div className="empty-state">
                <p>No stocks found matching the active filter criteria.</p>
              </div>
            )}
          </div>
        </main>
      </div>

      <footer style={{ textAlign: 'center', padding: '20px', fontSize: '12px', color: 'var(--text-muted)' }}>
        Stock Analyzer Screener Dashboard. Powered by React ↔ Spring Boot.
      </footer>
    </div>
  )
}

export default App
