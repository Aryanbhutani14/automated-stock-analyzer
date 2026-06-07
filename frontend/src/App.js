import React from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider } from './context/AuthContext';
import PrivateRoute from './components/PrivateRoute';
import Navbar from './components/Navbar';

// Pages
import Login      from './pages/Login';
import Register   from './pages/Register';
import Dashboard  from './pages/Dashboard';
import Screener   from './pages/Screener';
import StockDetail from './pages/StockDetail';
import Watchlist  from './pages/Watchlist';
import Alerts     from './pages/Alerts';
import Backtest   from './pages/Backtest';

function AppLayout({ children }) {
  return (
    <div className="min-h-screen bg-gray-950 text-white">
      <Navbar />
      <main className="py-4">{children}</main>
    </div>
  );
}

export default function App() {
  return (
    <AuthProvider>
      <Router>
        <Routes>
          {/* Public */}
          <Route path="/login"    element={<Login />}    />
          <Route path="/register" element={<Register />} />

          {/* Protected */}
          <Route path="/" element={
            <PrivateRoute>
              <AppLayout><Dashboard /></AppLayout>
            </PrivateRoute>
          } />
          <Route path="/screener" element={
            <PrivateRoute>
              <AppLayout><Screener /></AppLayout>
            </PrivateRoute>
          } />
          <Route path="/stocks/:symbol" element={
            <PrivateRoute>
              <AppLayout><StockDetail /></AppLayout>
            </PrivateRoute>
          } />
          <Route path="/watchlist" element={
            <PrivateRoute>
              <AppLayout><Watchlist /></AppLayout>
            </PrivateRoute>
          } />
          <Route path="/alerts" element={
            <PrivateRoute>
              <AppLayout><Alerts /></AppLayout>
            </PrivateRoute>
          } />
          <Route path="/backtest" element={
            <PrivateRoute>
              <AppLayout><Backtest /></AppLayout>
            </PrivateRoute>
          } />

          {/* Fallback */}
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </Router>
    </AuthProvider>
  );
}
