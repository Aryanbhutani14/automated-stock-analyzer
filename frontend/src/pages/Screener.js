import React, { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { screenerApi, stockApi } from '../services/api';
import Spinner from '../components/Spinner';
import Badge from '../components/Badge';

const FILTERS = [
  { value: 'ALL',            label: 'All Stocks'        },
  { value: 'MA220_CROSSOVER',label: '220-DMA Crossover' },
  { value: 'MA50_CROSSOVER', label: '50-DMA Crossover'  },
  { value: 'WEEK_52_HIGH',   label: '52-Week High'       },
  { value: 'VOLUME_BREAKOUT',label: 'Volume Breakout'    },
  { value: 'RSI_OVERSOLD',   label: 'RSI Oversold'       },
  { value: 'RSI_OVERBOUGHT', label: 'RSI Overbought'     },
  { value: 'MOMENTUM',       label: 'Strong Momentum'    },
];

export default function Screener() {
  const [results,  setResults]  = useState([]);
  const [sectors,  setSectors]  = useState([]);
  const [filter,   setFilter]   = useState('ALL');
  const [exchange, setExchange] = useState('');
  const [sector,   setSector]   = useState('');
  const [loading,  setLoading]  = useState(false);
  const [searched, setSearched] = useState(false);

  useEffect(() => {
    stockApi.getSectors().then((r) => setSectors(r.data)).catch(() => {});
    runScreen('ALL', '', '');
  }, []);

  const runScreen = async (f = filter, ex = exchange, sec = sector) => {
    setLoading(true);
    setSearched(true);
    try {
      const params = {
        filter: f,
        ...(ex  && { exchange: ex }),
        ...(sec && { sector:   sec }),
      };
      const res = await screenerApi.screen(params);
      setResults(res.data);
    } catch {
      setResults([]);
    } finally {
      setLoading(false);
    }
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    runScreen(filter, exchange, sector);
  };

  return (
    <div className="max-w-7xl mx-auto px-4 py-6">
      <h1 className="text-2xl font-bold text-white mb-6">Stock Screener</h1>

      {/* Filter bar */}
      <form onSubmit={handleSubmit}
            className="bg-gray-900 border border-gray-800 rounded-xl p-5 mb-6">
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">

          <div>
            <label className="block text-gray-400 text-xs mb-1.5 uppercase tracking-wide">Filter</label>
            <select
              value={filter}
              onChange={(e) => setFilter(e.target.value)}
              className="w-full bg-gray-800 border border-gray-700 text-white rounded-lg px-3 py-2.5 text-sm
                         focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              {FILTERS.map(({ value, label }) => (
                <option key={value} value={value}>{label}</option>
              ))}
            </select>
          </div>

          <div>
            <label className="block text-gray-400 text-xs mb-1.5 uppercase tracking-wide">Exchange</label>
            <select
              value={exchange}
              onChange={(e) => setExchange(e.target.value)}
              className="w-full bg-gray-800 border border-gray-700 text-white rounded-lg px-3 py-2.5 text-sm
                         focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="">All Exchanges</option>
              <option value="NSE">NSE</option>
              <option value="BSE">BSE</option>
            </select>
          </div>

          <div>
            <label className="block text-gray-400 text-xs mb-1.5 uppercase tracking-wide">Sector</label>
            <select
              value={sector}
              onChange={(e) => setSector(e.target.value)}
              className="w-full bg-gray-800 border border-gray-700 text-white rounded-lg px-3 py-2.5 text-sm
                         focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="">All Sectors</option>
              {sectors.map((s) => <option key={s} value={s}>{s}</option>)}
            </select>
          </div>
        </div>

        <div className="flex items-center justify-between mt-4">
          <p className="text-gray-500 text-sm">
            {searched && !loading && `${results.length} stocks matched`}
          </p>
          <button
            type="submit"
            className="px-6 py-2 bg-blue-600 hover:bg-blue-700 text-white text-sm font-medium rounded-lg transition-colors"
          >
            Run Screener
          </button>
        </div>
      </form>

      {/* Results */}
      {loading ? <Spinner /> : (
        <div className="bg-gray-900 border border-gray-800 rounded-xl overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead className="bg-gray-800 text-gray-400 text-xs uppercase tracking-wide">
                <tr>
                  {['Symbol','Name','Sector','Price','MA-50','MA-220','RSI','Momentum','Matched Filters'].map((h) => (
                    <th key={h} className="px-4 py-3 text-left whitespace-nowrap">{h}</th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {results.map((r) => (
                  <tr key={r.symbol} className="border-t border-gray-800 hover:bg-gray-800/60 transition-colors">
                    <td className="px-4 py-3 font-semibold">
                      <Link to={`/stocks/${r.symbol}`} className="text-blue-400 hover:underline">
                        {r.symbol}
                      </Link>
                    </td>
                    <td className="px-4 py-3 text-gray-300 max-w-[160px] truncate">{r.name}</td>
                    <td className="px-4 py-3 text-gray-400">{r.sector || '—'}</td>
                    <td className="px-4 py-3 text-white font-medium">
                      ₹{Number(r.closePrice || 0).toLocaleString('en-IN')}
                    </td>
                    <td className="px-4 py-3 text-gray-300">
                      {r.ma50 ? `₹${Number(r.ma50).toFixed(2)}` : '—'}
                    </td>
                    <td className="px-4 py-3 text-gray-300">
                      {r.ma220 ? `₹${Number(r.ma220).toFixed(2)}` : '—'}
                    </td>
                    <td className="px-4 py-3">
                      {r.rsi14 != null ? (
                        <span className={r.rsi14 < 35 ? 'text-green-400' : r.rsi14 > 70 ? 'text-red-400' : 'text-gray-300'}>
                          {Number(r.rsi14).toFixed(1)}
                        </span>
                      ) : '—'}
                    </td>
                    <td className="px-4 py-3">
                      {r.momentumScore != null ? (
                        <span className={r.momentumScore >= 0 ? 'text-green-400' : 'text-red-400'}>
                          {Number(r.momentumScore).toFixed(1)}%
                        </span>
                      ) : '—'}
                    </td>
                    <td className="px-4 py-3">
                      <div className="flex flex-wrap gap-1">
                        {(r.matchedFilters || '').split(', ').map((f) => (
                          <span key={f} className="bg-blue-900 text-blue-300 border border-blue-700
                                                   text-xs px-2 py-0.5 rounded whitespace-nowrap">
                            {f}
                          </span>
                        ))}
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
          {results.length === 0 && searched && !loading && (
            <p className="text-center text-gray-500 py-10">No stocks matched the selected filter</p>
          )}
        </div>
      )}
    </div>
  );
}
