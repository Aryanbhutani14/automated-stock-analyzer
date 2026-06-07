import React, { useState } from 'react';
import { Link, useLocation, useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';

const NAV_LINKS = [
  { to: '/',           label: 'Dashboard'  },
  { to: '/screener',   label: 'Screener'   },
  { to: '/watchlist',  label: 'Watchlist'  },
  { to: '/alerts',     label: 'Alerts'     },
  { to: '/backtest',   label: 'Backtest'   },
];

export default function Navbar() {
  const { user, logout } = useAuth();
  const location = useLocation();
  const navigate = useNavigate();
  const [menuOpen, setMenuOpen] = useState(false);

  const handleLogout = () => {
    logout();
    navigate('/login');
  };

  return (
    <nav className="bg-gray-900 border-b border-gray-800 sticky top-0 z-50">
      <div className="max-w-7xl mx-auto px-4 flex items-center justify-between h-16">

        {/* Logo */}
        <Link to="/" className="flex items-center gap-2">
          <span className="text-blue-400 text-xl font-bold">📈</span>
          <span className="text-white font-bold text-lg hidden sm:block">StockAnalyzer</span>
        </Link>

        {/* Desktop links */}
        <div className="hidden md:flex items-center gap-1">
          {NAV_LINKS.map(({ to, label }) => (
            <Link
              key={to}
              to={to}
              className={`px-3 py-2 rounded-md text-sm font-medium transition-colors
                ${location.pathname === to
                  ? 'bg-blue-600 text-white'
                  : 'text-gray-300 hover:bg-gray-800 hover:text-white'}`}
            >
              {label}
            </Link>
          ))}
        </div>

        {/* User + logout */}
        <div className="hidden md:flex items-center gap-3">
          {user && (
            <span className="text-gray-400 text-sm">
              👤 {user.username}
            </span>
          )}
          <button
            onClick={handleLogout}
            className="px-3 py-1.5 text-sm bg-red-600 hover:bg-red-700 text-white rounded-md transition-colors"
          >
            Logout
          </button>
        </div>

        {/* Mobile hamburger */}
        <button
          className="md:hidden text-gray-300 p-2"
          onClick={() => setMenuOpen(!menuOpen)}
          aria-label="Toggle menu"
        >
          {menuOpen ? '✕' : '☰'}
        </button>
      </div>

      {/* Mobile menu */}
      {menuOpen && (
        <div className="md:hidden border-t border-gray-800 bg-gray-900 px-4 pb-4">
          {NAV_LINKS.map(({ to, label }) => (
            <Link
              key={to}
              to={to}
              onClick={() => setMenuOpen(false)}
              className={`block px-3 py-2 mt-1 rounded-md text-sm
                ${location.pathname === to
                  ? 'bg-blue-600 text-white'
                  : 'text-gray-300 hover:bg-gray-800'}`}
            >
              {label}
            </Link>
          ))}
          <button
            onClick={handleLogout}
            className="w-full mt-2 px-3 py-2 text-sm bg-red-600 hover:bg-red-700 text-white rounded-md"
          >
            Logout
          </button>
        </div>
      )}
    </nav>
  );
}
