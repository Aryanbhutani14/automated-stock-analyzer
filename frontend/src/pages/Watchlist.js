import React, { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { watchlistApi } from '../services/api';
import Spinner from '../components/Spinner';

export default function Watchlist() {
  const [lists,       setLists]       = useState([]);
  const [loading,     setLoading]     = useState(true);
  const [newName,     setNewName]     = useState('');
  const [newDesc,     setNewDesc]     = useState('');
  const [adding,      setAdding]      = useState(false);
  const [symbolInput, setSymbolInput] = useState({});  // { [listId]: symbol }
  const [error,       setError]       = useState('');

  const load = async () => {
    try {
      const res = await watchlistApi.getAll();
      setLists(res.data);
    } catch { setError('Failed to load watchlists'); }
    finally { setLoading(false); }
  };

  useEffect(() => { load(); }, []);

  const createList = async (e) => {
    e.preventDefault();
    if (!newName.trim()) return;
    setAdding(true);
    try {
      await watchlistApi.create({ name: newName.trim(), description: newDesc.trim() });
      setNewName('');
      setNewDesc('');
      await load();
    } catch (err) {
      setError(err.response?.data?.message || 'Failed to create watchlist');
    } finally { setAdding(false); }
  };

  const deleteList = async (id) => {
    if (!window.confirm('Delete this watchlist?')) return;
    try {
      await watchlistApi.delete(id);
      await load();
    } catch { setError('Failed to delete watchlist'); }
  };

  const addStock = async (id) => {
    const symbol = (symbolInput[id] || '').trim().toUpperCase();
    if (!symbol) return;
    try {
      await watchlistApi.addStock(id, symbol);
      setSymbolInput({ ...symbolInput, [id]: '' });
      await load();
    } catch (err) {
      setError(err.response?.data?.message || `Could not add ${symbol}`);
    }
  };

  const removeStock = async (id, symbol) => {
    try {
      await watchlistApi.removeStock(id, symbol);
      await load();
    } catch { setError(`Failed to remove ${symbol}`); }
  };

  if (loading) return <Spinner size="lg" />;

  return (
    <div className="max-w-4xl mx-auto px-4 py-6">
      <h1 className="text-2xl font-bold text-white mb-6">Watchlists</h1>

      {error && (
        <div className="bg-red-900/30 border border-red-700 text-red-400 p-3 rounded-lg mb-4 text-sm flex justify-between">
          <span>{error}</span>
          <button onClick={() => setError('')} className="ml-3 hover:text-white">✕</button>
        </div>
      )}

      {/* Create new */}
      <form onSubmit={createList}
            className="bg-gray-900 border border-gray-800 rounded-xl p-5 mb-6">
        <h2 className="text-gray-300 font-semibold mb-3">Create New Watchlist</h2>
        <div className="flex flex-col sm:flex-row gap-3">
          <input
            type="text"
            placeholder="List name"
            value={newName}
            onChange={(e) => setNewName(e.target.value)}
            required
            className="flex-1 bg-gray-800 border border-gray-700 text-white text-sm rounded-lg px-4 py-2.5
                       focus:outline-none focus:ring-2 focus:ring-blue-500"
          />
          <input
            type="text"
            placeholder="Description (optional)"
            value={newDesc}
            onChange={(e) => setNewDesc(e.target.value)}
            className="flex-1 bg-gray-800 border border-gray-700 text-white text-sm rounded-lg px-4 py-2.5
                       focus:outline-none focus:ring-2 focus:ring-blue-500"
          />
          <button
            type="submit"
            disabled={adding}
            className="px-5 py-2.5 bg-blue-600 hover:bg-blue-700 disabled:opacity-50
                       text-white text-sm font-medium rounded-lg transition-colors whitespace-nowrap"
          >
            {adding ? 'Creating…' : '+ Create'}
          </button>
        </div>
      </form>

      {/* List of watchlists */}
      {lists.length === 0 ? (
        <div className="text-center py-16">
          <p className="text-4xl mb-3">📋</p>
          <p className="text-gray-400">No watchlists yet — create one above</p>
        </div>
      ) : (
        <div className="space-y-4">
          {lists.map((wl) => (
            <div key={wl.id} className="bg-gray-900 border border-gray-800 rounded-xl p-5">
              {/* Header */}
              <div className="flex items-start justify-between mb-3">
                <div>
                  <h3 className="text-white font-semibold text-lg">{wl.name}</h3>
                  {wl.description && <p className="text-gray-500 text-sm">{wl.description}</p>}
                </div>
                <button
                  onClick={() => deleteList(wl.id)}
                  className="text-gray-600 hover:text-red-400 transition-colors text-sm"
                >
                  🗑 Delete
                </button>
              </div>

              {/* Stocks */}
              <div className="flex flex-wrap gap-2 mb-3 min-h-[2rem]">
                {wl.symbols?.length === 0 ? (
                  <span className="text-gray-600 text-sm">No stocks added yet</span>
                ) : (
                  wl.symbols.map((sym) => (
                    <span key={sym}
                          className="flex items-center gap-1 bg-gray-800 border border-gray-700
                                     text-gray-300 text-sm rounded-lg px-3 py-1">
                      <Link to={`/stocks/${sym}`}
                            className="text-blue-400 hover:underline font-medium">{sym}</Link>
                      <button
                        onClick={() => removeStock(wl.id, sym)}
                        className="text-gray-600 hover:text-red-400 ml-1 leading-none"
                        aria-label={`Remove ${sym}`}
                      >✕</button>
                    </span>
                  ))
                )}
              </div>

              {/* Add stock */}
              <div className="flex gap-2">
                <input
                  type="text"
                  placeholder="Add symbol (e.g. TCS)"
                  value={symbolInput[wl.id] || ''}
                  onChange={(e) => setSymbolInput({ ...symbolInput, [wl.id]: e.target.value })}
                  onKeyDown={(e) => e.key === 'Enter' && addStock(wl.id)}
                  className="flex-1 bg-gray-800 border border-gray-700 text-white text-sm rounded-lg px-3 py-2
                             focus:outline-none focus:ring-2 focus:ring-blue-500 max-w-xs"
                />
                <button
                  onClick={() => addStock(wl.id)}
                  className="px-4 py-2 bg-green-700 hover:bg-green-600 text-white text-sm rounded-lg transition-colors"
                >
                  + Add
                </button>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
