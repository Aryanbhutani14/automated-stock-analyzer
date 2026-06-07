import React, { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { stockApi, signalApi } from '../services/api';
import Spinner from '../components/Spinner';
import StatCard from '../components/StatCard';
import Badge from '../components/Badge';
import { useAuth } from '../context/AuthContext';

export default function Dashboard() {
  const { user } = useAuth();
  const [stocks,  setStocks]  = useState([]);
  const [signals, setSignals] = useState([]);
  const [search,  setSearch]  = useState('');
  const [loading, setLoading] = useState(true);
  const [error,   setError]   = useState('');

  useEffect(() => {
    const load = async () => {
      try {
        const [sRes, sigRes] = await Promise.all([
          stockApi.getAll(),
          signalApi.getByDate(new Date().toISOString().split('T')[0]),
        ]);
        setStocks(sRes.data);
        setSignals(sigRes.data);
      } catch {
        setError('Failed to load market data');
      } finally {
        setLoading(false);
      }
    };
    load();
  }, []);

  const filtered = stocks.filter(
    (s) =>
      s.symbol.toLowerCase().includes(search.toLowerCase()) ||
      s.name.toLowerCase().includes(search.toLowerCase())
  );

  const buyCount  = signals.filter((s) => s.signalType === 'BUY').length;
  const sellCount = signals.filter((s) => s.signalType === 'SELL').length;

  if (loading) return <Spinner size="lg" />;

  return (
    <div className="max-w-7xl mx-auto px-4 py-6">

      {/* Greeting */}
      <div className="mb-6">
        <h1 className="text-2xl font-bold text-white">
          Good {getGreeting()}, {user?.username} 👋
        </h1>
        <p className="text-gray-400 mt-1 text-sm">
          {new Date().toLocaleDateString('en-IN', { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' })}
        </p>
      </div>

      {/* Stat cards */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-8">
        <StatCard label="Stocks Tracked"  value={stocks.length}     sub="active"         />
        <StatCard label="Today's Signals" value={signals.length}    sub="total today"    />
        <StatCard label="BUY Signals"     value={buyCount}          color="text-green-400" />
        <StatCard label="SELL Signals"    value={sellCount}         color="text-red-400"   />
      </div>

      {error && (
        <div className="bg-red-900/30 border border-red-700 text-red-400 p-4 rounded-lg mb-6 text-sm">
          {error}
        </div>
      )}

      {/* Today's signals */}
      {signals.length > 0 && (
        <div className="mb-8">
          <h2 className="text-lg font-semibold text-white mb-3">Today's Signals</h2>
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3">
            {signals.slice(0, 6).map((sig, i) => (
              <div key={i} className="bg-gray-800 border border-gray-700 rounded-xl p-4">
                <div className="flex items-center justify-between mb-2">
                  <Link to={`/stocks/${sig.stock?.symbol}`}
                        className="font-bold text-blue-400 hover:underline">
                    {sig.stock?.symbol}
                  </Link>
                  <Badge type={sig.signalType} />
                </div>
                <p className="text-gray-400 text-xs">{sig.strategy}</p>
                <p className="text-white text-sm mt-1">
                  ₹{sig.triggerPrice?.toLocaleString('en-IN')}
                </p>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* All stocks table */}
      <div>
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 mb-4">
          <h2 className="text-lg font-semibold text-white">All Stocks</h2>
          <input
            type="text"
            placeholder="Search symbol or name…"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="bg-gray-800 border border-gray-700 text-white text-sm rounded-lg px-4 py-2
                       focus:outline-none focus:ring-2 focus:ring-blue-500 w-full sm:w-64"
          />
        </div>

        <div className="bg-gray-900 border border-gray-800 rounded-xl overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead className="bg-gray-800 text-gray-400 text-xs uppercase tracking-wide">
                <tr>
                  {['Symbol', 'Name', 'Sector', 'Price', 'MA-50', 'MA-220', 'RSI', 'Momentum'].map((h) => (
                    <th key={h} className="px-4 py-3 text-left whitespace-nowrap">{h}</th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {filtered.map((s) => (
                  <tr key={s.symbol}
                      className="border-t border-gray-800 hover:bg-gray-800/60 transition-colors">
                    <td className="px-4 py-3 font-semibold">
                      <Link to={`/stocks/${s.symbol}`} className="text-blue-400 hover:underline">
                        {s.symbol}
                      </Link>
                    </td>
                    <td className="px-4 py-3 text-gray-300 max-w-[180px] truncate">{s.name}</td>
                    <td className="px-4 py-3 text-gray-400">{s.sector || '—'}</td>
                    <td className="px-4 py-3 text-white font-medium">
                      {s.closePrice ? `₹${Number(s.closePrice).toLocaleString('en-IN')}` : '—'}
                    </td>
                    <td className="px-4 py-3 text-gray-300">
                      {s.ma50 ? `₹${Number(s.ma50).toFixed(2)}` : '—'}
                    </td>
                    <td className="px-4 py-3 text-gray-300">
                      {s.ma220 ? `₹${Number(s.ma220).toFixed(2)}` : '—'}
                    </td>
                    <td className="px-4 py-3">
                      {s.rsi14 != null ? (
                        <span className={getRsiColor(s.rsi14)}>
                          {Number(s.rsi14).toFixed(1)}
                        </span>
                      ) : '—'}
                    </td>
                    <td className="px-4 py-3">
                      {s.momentumScore != null ? (
                        <span className={s.momentumScore >= 0 ? 'text-green-400' : 'text-red-400'}>
                          {Number(s.momentumScore).toFixed(1)}%
                        </span>
                      ) : '—'}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
          {filtered.length === 0 && (
            <p className="text-center text-gray-500 py-8">No stocks found</p>
          )}
        </div>
      </div>
    </div>
  );
}

function getRsiColor(rsi) {
  if (rsi < 35)  return 'text-green-400 font-semibold';
  if (rsi > 70)  return 'text-red-400 font-semibold';
  return 'text-gray-300';
}

function getGreeting() {
  const h = new Date().getHours();
  if (h < 12) return 'morning';
  if (h < 17) return 'afternoon';
  return 'evening';
}
