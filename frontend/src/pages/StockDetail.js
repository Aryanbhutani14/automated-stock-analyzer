import React, { useEffect, useState } from 'react';
import { useParams } from 'react-router-dom';
import {
  ResponsiveContainer, AreaChart, Area,
  XAxis, YAxis, Tooltip, CartesianGrid,
} from 'recharts';
import { stockApi, aiApi, signalApi } from '../services/api';
import Spinner from '../components/Spinner';
import Badge from '../components/Badge';
import StatCard from '../components/StatCard';

const RANGES = [
  { label: '1M',  days: 30  },
  { label: '3M',  days: 90  },
  { label: '6M',  days: 180 },
  { label: '1Y',  days: 365 },
];

function daysAgo(n) {
  const d = new Date();
  d.setDate(d.getDate() - n);
  return d.toISOString().split('T')[0];
}

export default function StockDetail() {
  const { symbol } = useParams();

  const [stock,   setStock]   = useState(null);
  const [history, setHistory] = useState([]);
  const [signals, setSignals] = useState([]);
  const [summary, setSummary] = useState(null);
  const [range,   setRange]   = useState(90);
  const [loading, setLoading] = useState(true);
  const [aiLoading, setAiLoading] = useState(false);

  useEffect(() => {
    const load = async () => {
      setLoading(true);
      try {
        const [sRes, hRes, sigRes] = await Promise.all([
          stockApi.getOne(symbol),
          stockApi.getPriceHistory(symbol, daysAgo(range), new Date().toISOString().split('T')[0]),
          signalApi.getBySymbol(symbol),
        ]);
        setStock(sRes.data);
        setHistory(hRes.data);
        setSignals(sigRes.data.slice(0, 10));
      } catch { /* handled by global interceptor */ }
      finally { setLoading(false); }
    };
    load();
  }, [symbol, range]);

  const loadSummary = async () => {
    setAiLoading(true);
    try {
      const res = await aiApi.getSummary(symbol);
      setSummary(res.data);
    } catch { setSummary({ summary: 'AI summary unavailable — check your OpenAI API key.' }); }
    finally { setAiLoading(false); }
  };

  if (loading) return <Spinner size="lg" />;
  if (!stock)  return <p className="text-center text-gray-400 py-16">Stock not found</p>;

  const aboveMa220 = stock.closePrice && stock.ma220
    ? Number(stock.closePrice) > Number(stock.ma220)
    : null;

  return (
    <div className="max-w-6xl mx-auto px-4 py-6 space-y-6">

      {/* Header */}
      <div className="flex flex-wrap items-start justify-between gap-3">
        <div>
          <h1 className="text-3xl font-bold text-white">{stock.symbol}</h1>
          <p className="text-gray-400">{stock.name} · {stock.exchange} · {stock.sector}</p>
        </div>
        <div className="text-right">
          <p className="text-4xl font-bold text-white">
            ₹{Number(stock.closePrice || 0).toLocaleString('en-IN')}
          </p>
          {aboveMa220 !== null && (
            <span className={`text-sm ${aboveMa220 ? 'text-green-400' : 'text-red-400'}`}>
              {aboveMa220 ? '▲ Above 220-DMA' : '▼ Below 220-DMA'}
            </span>
          )}
        </div>
      </div>

      {/* Indicator cards */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <StatCard label="MA-50"        value={stock.ma50   ? `₹${Number(stock.ma50).toFixed(2)}`   : '—'} />
        <StatCard label="MA-220"       value={stock.ma220  ? `₹${Number(stock.ma220).toFixed(2)}`  : '—'} />
        <StatCard label="RSI (14)"     value={stock.rsi14  ? Number(stock.rsi14).toFixed(1)        : '—'}
                  color={stock.rsi14 < 35 ? 'text-green-400' : stock.rsi14 > 70 ? 'text-red-400' : 'text-white'} />
        <StatCard label="12M Momentum" value={stock.momentumScore != null ? `${Number(stock.momentumScore).toFixed(1)}%` : '—'}
                  color={stock.momentumScore >= 0 ? 'text-green-400' : 'text-red-400'} />
      </div>

      {/* Price chart */}
      <div className="bg-gray-900 border border-gray-800 rounded-xl p-5">
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-lg font-semibold text-white">Price History</h2>
          <div className="flex gap-2">
            {RANGES.map(({ label, days }) => (
              <button
                key={label}
                onClick={() => setRange(days)}
                className={`px-3 py-1 text-xs rounded-md transition-colors
                  ${range === days ? 'bg-blue-600 text-white' : 'bg-gray-800 text-gray-400 hover:bg-gray-700'}`}
              >
                {label}
              </button>
            ))}
          </div>
        </div>

        {history.length > 0 ? (
          <ResponsiveContainer width="100%" height={280}>
            <AreaChart data={history}>
              <defs>
                <linearGradient id="priceGrad" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%"  stopColor="#3b82f6" stopOpacity={0.3} />
                  <stop offset="95%" stopColor="#3b82f6" stopOpacity={0}   />
                </linearGradient>
              </defs>
              <CartesianGrid strokeDasharray="3 3" stroke="#1f2937" />
              <XAxis dataKey="tradeDate" tick={{ fill: '#6b7280', fontSize: 11 }}
                     tickFormatter={(v) => v?.slice(5)} />
              <YAxis tick={{ fill: '#6b7280', fontSize: 11 }}
                     tickFormatter={(v) => `₹${v}`} width={70} domain={['auto', 'auto']} />
              <Tooltip
                contentStyle={{ background: '#1f2937', border: '1px solid #374151', borderRadius: 8 }}
                labelStyle={{ color: '#9ca3af' }}
                formatter={(v) => [`₹${Number(v).toLocaleString('en-IN')}`, 'Close']}
              />
              <Area type="monotone" dataKey="closePrice"
                    stroke="#3b82f6" strokeWidth={2}
                    fill="url(#priceGrad)" dot={false} />
            </AreaChart>
          </ResponsiveContainer>
        ) : (
          <p className="text-center text-gray-500 py-12">No price history available</p>
        )}
      </div>

      {/* AI Summary */}
      <div className="bg-gray-900 border border-gray-800 rounded-xl p-5">
        <div className="flex items-center justify-between mb-3">
          <h2 className="text-lg font-semibold text-white">🤖 AI Analysis</h2>
          {!summary && (
            <button
              onClick={loadSummary}
              disabled={aiLoading}
              className="px-4 py-1.5 text-sm bg-purple-700 hover:bg-purple-600 disabled:opacity-50
                         text-white rounded-lg transition-colors"
            >
              {aiLoading ? 'Generating…' : 'Generate Summary'}
            </button>
          )}
        </div>
        {summary ? (
          <p className="text-gray-300 leading-relaxed">{summary.summary}</p>
        ) : (
          <p className="text-gray-500 text-sm">Click the button to generate an AI-powered analysis for {symbol}.</p>
        )}
      </div>

      {/* Recent signals */}
      <div className="bg-gray-900 border border-gray-800 rounded-xl p-5">
        <h2 className="text-lg font-semibold text-white mb-4">Recent Signals</h2>
        {signals.length === 0 ? (
          <p className="text-gray-500 text-sm">No signals recorded yet</p>
        ) : (
          <div className="space-y-2">
            {signals.map((sig, i) => (
              <div key={i} className="flex items-center justify-between bg-gray-800 rounded-lg px-4 py-3">
                <div>
                  <span className="text-gray-300 text-sm">{sig.strategy}</span>
                  <p className="text-gray-500 text-xs">{sig.notes}</p>
                </div>
                <div className="text-right">
                  <Badge type={sig.signalType} />
                  <p className="text-gray-500 text-xs mt-1">{sig.signalDate}</p>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

    </div>
  );
}
