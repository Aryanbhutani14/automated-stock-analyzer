import React, { useEffect, useState } from 'react';
import { alertApi } from '../services/api';
import Spinner from '../components/Spinner';

const ALERT_TYPES = [
  'PRICE_ABOVE', 'PRICE_BELOW',
  'MA220_CROSSOVER_UP', 'MA220_CROSSOVER_DOWN',
  'MA50_CROSSOVER_UP',  'MA50_CROSSOVER_DOWN',
  'RSI_OVERBOUGHT',     'RSI_OVERSOLD',
  'VOLUME_BREAKOUT',    'WEEK_52_HIGH',
];

const NEEDS_THRESHOLD = ['PRICE_ABOVE', 'PRICE_BELOW'];

export default function Alerts() {
  const [alerts,  setAlerts]  = useState([]);
  const [loading, setLoading] = useState(true);
  const [form,    setForm]    = useState({ symbol: '', alertType: 'PRICE_ABOVE', threshold: '' });
  const [error,   setError]   = useState('');
  const [saving,  setSaving]  = useState(false);

  const load = async () => {
    try {
      const res = await alertApi.getAll();
      setAlerts(res.data);
    } catch { setError('Failed to load alerts'); }
    finally { setLoading(false); }
  };

  useEffect(() => { load(); }, []);

  const createAlert = async (e) => {
    e.preventDefault();
    setError('');
    setSaving(true);
    try {
      await alertApi.create({
        symbol:    form.symbol.toUpperCase(),
        alertType: form.alertType,
        threshold: NEEDS_THRESHOLD.includes(form.alertType) ? parseFloat(form.threshold) : null,
      });
      setForm({ symbol: '', alertType: 'PRICE_ABOVE', threshold: '' });
      await load();
    } catch (err) {
      setError(err.response?.data?.message || 'Failed to create alert');
    } finally { setSaving(false); }
  };

  const deleteAlert = async (id) => {
    try {
      await alertApi.delete(id);
      await load();
    } catch { setError('Failed to delete alert'); }
  };

  const needsThreshold = NEEDS_THRESHOLD.includes(form.alertType);

  if (loading) return <Spinner size="lg" />;

  return (
    <div className="max-w-4xl mx-auto px-4 py-6">
      <h1 className="text-2xl font-bold text-white mb-6">Price Alerts</h1>

      {error && (
        <div className="bg-red-900/30 border border-red-700 text-red-400 p-3 rounded-lg mb-4 text-sm flex justify-between">
          <span>{error}</span>
          <button onClick={() => setError('')} className="ml-3">✕</button>
        </div>
      )}

      {/* Create alert form */}
      <form onSubmit={createAlert}
            className="bg-gray-900 border border-gray-800 rounded-xl p-5 mb-6">
        <h2 className="text-gray-300 font-semibold mb-4">Create Alert</h2>
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
          <div>
            <label className="block text-gray-400 text-xs mb-1.5 uppercase tracking-wide">Symbol</label>
            <input
              type="text"
              required
              placeholder="e.g. TCS"
              value={form.symbol}
              onChange={(e) => setForm({ ...form, symbol: e.target.value })}
              className="w-full bg-gray-800 border border-gray-700 text-white text-sm rounded-lg px-3 py-2.5
                         focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>

          <div>
            <label className="block text-gray-400 text-xs mb-1.5 uppercase tracking-wide">Alert Type</label>
            <select
              value={form.alertType}
              onChange={(e) => setForm({ ...form, alertType: e.target.value })}
              className="w-full bg-gray-800 border border-gray-700 text-white text-sm rounded-lg px-3 py-2.5
                         focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              {ALERT_TYPES.map((t) => (
                <option key={t} value={t}>{t.replace(/_/g, ' ')}</option>
              ))}
            </select>
          </div>

          {needsThreshold && (
            <div>
              <label className="block text-gray-400 text-xs mb-1.5 uppercase tracking-wide">
                Threshold (₹)
              </label>
              <input
                type="number"
                required
                step="0.01"
                min="0"
                placeholder="e.g. 4000"
                value={form.threshold}
                onChange={(e) => setForm({ ...form, threshold: e.target.value })}
                className="w-full bg-gray-800 border border-gray-700 text-white text-sm rounded-lg px-3 py-2.5
                           focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>
          )}
        </div>

        <div className="flex justify-end mt-4">
          <button
            type="submit"
            disabled={saving}
            className="px-6 py-2.5 bg-blue-600 hover:bg-blue-700 disabled:opacity-50
                       text-white text-sm font-medium rounded-lg transition-colors"
          >
            {saving ? 'Creating…' : '+ Create Alert'}
          </button>
        </div>
      </form>

      {/* Alerts list */}
      {alerts.length === 0 ? (
        <div className="text-center py-16">
          <p className="text-4xl mb-3">🔔</p>
          <p className="text-gray-400">No alerts set — create one above</p>
        </div>
      ) : (
        <div className="bg-gray-900 border border-gray-800 rounded-xl overflow-hidden">
          <table className="w-full text-sm">
            <thead className="bg-gray-800 text-gray-400 text-xs uppercase tracking-wide">
              <tr>
                {['Symbol', 'Alert Type', 'Threshold', 'Last Triggered', 'Status', ''].map((h) => (
                  <th key={h} className="px-4 py-3 text-left">{h}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {alerts.map((a) => (
                <tr key={a.id} className="border-t border-gray-800 hover:bg-gray-800/50">
                  <td className="px-4 py-3 font-semibold text-blue-400">{a.symbol}</td>
                  <td className="px-4 py-3 text-gray-300">{a.alertType.replace(/_/g, ' ')}</td>
                  <td className="px-4 py-3 text-gray-300">
                    {a.threshold ? `₹${Number(a.threshold).toLocaleString('en-IN')}` : '—'}
                  </td>
                  <td className="px-4 py-3 text-gray-500 text-xs">
                    {a.lastTriggered ? new Date(a.lastTriggered).toLocaleDateString('en-IN') : 'Never'}
                  </td>
                  <td className="px-4 py-3">
                    <span className="bg-green-900 text-green-400 border border-green-700 text-xs px-2 py-0.5 rounded">
                      Active
                    </span>
                  </td>
                  <td className="px-4 py-3">
                    <button
                      onClick={() => deleteAlert(a.id)}
                      className="text-gray-600 hover:text-red-400 transition-colors text-xs"
                    >
                      Remove
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
