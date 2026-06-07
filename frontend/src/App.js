import React from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';

// Pages (to be implemented)
// import Dashboard from './pages/Dashboard';
// import Screener from './pages/Screener';
// import Watchlist from './pages/Watchlist';
// import Backtest from './pages/Backtest';
// import Login from './pages/Login';

function App() {
  return (
    <Router>
      <div className="min-h-screen bg-gray-950 text-white">
        <Routes>
          {/* Routes will be added as pages are built */}
          <Route
            path="/"
            element={
              <div className="flex items-center justify-center h-screen">
                <div className="text-center">
                  <h1 className="text-4xl font-bold text-blue-400 mb-4">
                    Automated Stock Analyzer
                  </h1>
                  <p className="text-gray-400 text-lg">
                    AI-powered stock screening and portfolio monitoring platform
                  </p>
                  <p className="text-gray-600 mt-4 text-sm">🚀 Project scaffolding complete — development in progress</p>
                </div>
              </div>
            }
          />
        </Routes>
      </div>
    </Router>
  );
}

export default App;
