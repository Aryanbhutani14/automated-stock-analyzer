import React, { useEffect, useState } from 'react';
import {
  ResponsiveContainer, BarChart, Bar,
  XAxis, YAxis, Tooltip, CartesianGrid, Cell,
} from 'recharts';
import { backtestApi } from '../services/api';
import Spinner from '../components/Spinner';
import StatCard from '../components/StatCard';

const STRATEGIES = [
  '',                // All
  'MA220_CROSSOVER',
  'MA50_CROSSOVER',
  'RSI_OVERSOLD',
  'RSI_OVERBOUGHT',
  'WEEK_52_HIGH',
  'VOLUME_BREAKOUT',
  'MOMENTUM',
];

export default function Backtest() {
  const [form, setForm] = useState({
    symbol: '',
    strategy: '',
    startDate: '2023-01-01',
    endDate: new Date().toISOString().split('T')[0],
    initialCapital: 100000,
  });
  const [result,  setResult]  = useState(null);
  const [history, setHistory] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error,   setError]   = useState('');
  const [tab,     setTab]     = useState('run');

  useEffect(() => {
    backtestApi.getHistory().then((r) => setHistory(r.data)).catch(() => {});
  }, []);

  const runBacktest = async (e) => {
    e.preventDefault();
    setError('');
    setResult(null);
    setLoading(true);
    try {
      const res = await backtestApi.run({
        ...form,
        strategy: form.strategy || null,
        initialCapital: Number(form.initialCapital),
      });
      setResult(res.data);
      backtestApi.getHistory().then((r) => setHistory(r.data)).catch(() => {});
    } catch (err) {
      setError(err.response?.data?.message || 'Backtest failed');
    } finally { setLoading(false); }
  };

  return (
    <div className="max-w-5xl mx-auto px-4 py-6">
      <h1 className="text-2xl font-bold text-white mb-6">Historical Backtester</h1>

      {/* Tabs */}
      <div className="flex gap-1 mb-6 bg-gray-800 rounded-lg p-1 w-fit">
        {['run', 'history'].map((t) => (
          <button key={t} onClick={() => setTab(t)}
                  className={`px-5 py-2 text-sm rounded-md font-medium capitalize transition-colors
                    ${tab === t ? 'bg-blue-600 text-white' : 'text-gray-400 hover:text-white'}`}>
            {t === 'run' ? '▶ Run Backtest' : '📋 History'}
          </button>
        ))}
      </div>

      {tab === 'run' && (
        <>
          {/* Form */}
          <form onSubmit={runBacktest}
                className="bg-gray-900 border border-gray-800 rounded-xl p-6 mb-6 space-y-4">
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
              <div>
                <label className="block text-gray-400 text-xs mb-1.5 uppercase tracking-wide">Symbol *</label>
                <input
                  required type="text" placeholder="e.g. RELIANCE"
                  value={form.symbol}
                  onChange={(e) => setForm({ ...form, symbol: e.target.value.toUpperCase() })}
                  className="w-full bg-gray-800 border border-gray-700 text-white text-sm rounded-lg px-3 py-2.5
                             focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
              </div>

              <div>
                <label className="block text-gray-400 text-xs mb-1.5 uppercase tracking-wide">Strategy</label>
                <select value={form.strategy}
                        onChange={(e) => setForm({ ...form, strategy: e.target.value })}
                        className="w-full bg-gray-800 border border-gray-700 text-white text-sm rounded-lg px-3 py-2.5
                                   focus:outline-none focus:ring-2 focus:ring-blue-500">
                  {STRATEGIES.map((s) => (
                    <option key={s} value={s}>{s ? s.replace(/_/g, ' ') : 'All Strategies'}</option>
                  ))}
                </select>
              </div>

              <div>
                <label className="block text-gray-400 text-xs mb-1.5 uppercase tracking-wide">Initial Capital (₹)</label>
                <input
                  type="number" min="1000" step="1000"
                  value={form.initialCapital}
                  onChange={(e) => setForm({ ...form, initialCapital: e.target.value })}
                  className="w-full bg-gray-800 border border-gray-700 text-white text-sm rounded-lg px-3 py-2.5
                             focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
              </div>

              <div>
                <label className="block text-gray-400 text-xs mb-1.5 uppercase tracking-wide">Start Date *</label>
                <input
                  required type="date"
                  value={form.startDate}
                  onChange={(e) => setForm({ ...form, startDate: e.target.value })}
                  className="w-full bg-gray-800 border border-gray-700 text-white text-sm rounded-lg px-3 py-2.5
                             focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
              </div>

              <div>
                <label className="block text-gray-400 text-xs mb-1.5 uppercase tracking-wide">End Date *</label>
                <input
                  required type="date"
                  value={form.endDate}
                  onChange={(e) => setForm({ ...form, endDate: e.target.value })}
                  className="w-full bg-gray-800 border border-gray-700 text-white text-sm rounded-lg px-3 py-2.5
                             focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
              </div>
            </div>

            {error && (
              <div className="bg-red-900/30 border border-red-700 text-red-400 p-3 rounded-lg text-sm">
                {error}
              </div>
            )}

            <div className="flex justify-end">
              <button type="submit" disabled={loading}
                      className="px-8 py-2.5 bg-blue-600 hover:bg-blue-700 disabled:opacity-50
                                 text-white font-medium rounded-lg transition-colors">
                {loading ? 'Running…' : '▶ Run Backtest'}
              </button>
            </div>
          </form>

          {/* Results */}
          {loading && <Spinner />}

          {result && !loading && (
            <div className="space-y-5">
              <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                <StatCard
                  label="Total Return"
                  value={`${result.totalReturnPct >= 0 ? '+' : ''}${result.totalReturnPct}%`}
                  color={result.totalReturnPct >= 0 ? 'text-green-400' : 'text-red-400'}
                />
                <StatCard label="Win Rate"     value={`${result.winRatePct}%`}      color="text-blue-400" />
                <StatCard label="Total Trades" value={result.totalTrades}                                  />
                <StatCard
                  label="Max Drawdown"
                  value={`-${result.maxDrawdownPct}%`}
                  color="text-red-400"
                />
              </div>

              {result.message && (
                <p className="text-gray-400 text-sm">{result.message}</p>
              )}

              {/* Trade-level chart */}
              {result.trades?.length > 0 && (
                <div className="bg-gray-900 border border-gray-800 rounded-xl p-5">
                  <h3 className="text-white font-semibold mb-4">Trade Returns (%)</h3>
                  <ResponsiveContainer width="100%" height={220}>
                    <BarChart data={result.trades}>
                      <CartesianGrid strokeDasharray="3 3" stroke="#1f2937" />
                      <XAxis dataKey="exitDate" tick={{ fill: '#6b7280', fontSize: 10 }} />
                      <YAxis tick={{ fill: '#6b7280', fontSize: 10 }} />
                      <Tooltip
                        contentStyle={{ background: '#1f2937', border: '1px solid #374151', borderRadius: 8 }}
                        formatter={(v) => [`${v}%`, 'Return']}
                      />
                      <Bar dataKey="returnPct" radius={[4, 4, 0, 0]}>
                        {result.trades.map((t, i) => (
                          <Cell key={i} fill={t.returnPct >= 0 ? '#22c55e' : '#ef4444'} />
                        ))}
                      </Bar>
                    </BarChart>
                  </ResponsiveContainer>
                </div>
              )}

              {/* Trade table */}
              {result.trades?.length > 0 && (
                <div className="bg-gray-900 border border-gray-800 rounded-xl overflow-hidden">
                  <table className="w-full text-sm">
                    <thead className="bg-gray-800 text-gray-400 text-xs uppercase tracking-wide">
                      <tr>
                        {['Entry Date', 'Exit Date', 'Entry ₹', 'Exit ₹', 'Return %'].map((h) => (
                          <th key={h} className="px-4 py-3 text-left">{h}</th>
                        ))}
                      </tr>
                    </thead>
                    <tbody>
                      {result.trades.map((t, i) => (
                        <tr key={i} className="border-t border-gray-800 hover:bg-gray-800/50">
                          <td className="px-4 py-3 text-gray-400">{t.entryDate}</td>
                          <td className="px-4 py-3 text-gray-400">{t.exitDate}</td>
                          <td className="px-4 py-3 text-white">₹{Number(t.entryPrice).toLocaleString('en-IN')}</td>
                          <td className="px-4 py-3 text-white">₹{Number(t.exitPrice).toLocaleString('en-IN')}</td>
                          <td className={`px-4 py-3 font-semibold ${t.returnPct >= 0 ? 'text-green-400' : 'text-red-400'}`}>
                            {t.returnPct >= 0 ? '+' : ''}{t.returnPct}%
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}
            </div>
          )}
        </>
      )}

      {/* History tab */}
      {tab === 'history' && (
        <div className="bg-gray-900 border border-gray-800 rounded-xl overflow-hidden">
          {history.length === 0 ? (
            <div className="text-center py-16">
              <p className="text-4xl mb-3">📊</p>
              <p className="text-gray-400">No backtests run yet</p>
            </div>
          ) : (
            <table className="w-full text-sm">
              <thead className="bg-gray-800 text-gray-400 text-xs uppercase tracking-wide">
                <tr>
                  {['Symbol','Strategy','Period','Return','Win Rate','Trades','Drawdown'].map((h) => (
                    <th key={h} className="px-4 py-3 text-left">{h}</th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {history.map((r, i) => (
                  <tr key={i} className="border-t border-gray-800 hover:bg-gray-800/50">
                    <td className="px-4 py-3 font-semibold text-blue-400">{r.symbol}</td>
                    <td className="px-4 py-3 text-gray-300">{r.strategy}</td>
                    <td className="px-4 py-3 text-gray-500 text-xs">{r.startDate} → {r.endDate}</td>
                    <td className={`px-4 py-3 font-semibold ${r.totalReturnPct >= 0 ? 'text-green-400' : 'text-red-400'}`}>
                      {r.totalReturnPct >= 0 ? '+' : ''}{r.totalReturnPct}%
                    </td>
                    <td className="px-4 py-3 text-gray-300">{r.winRatePct}%</td>
                    <td className="px-4 py-3 text-gray-300">{r.totalTrades}</td>
                    <td className="px-4 py-3 text-red-400">-{r.maxDrawdownPct}%</td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>
      )}
    </div>
  );
}
