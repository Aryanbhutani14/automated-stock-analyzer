import axios from 'axios';

const api = axios.create({
  baseURL: '/api',
  headers: { 'Content-Type': 'application/json' },
});

// Attach JWT on every request
api.interceptors.request.use((config) => {
  const token = localStorage.getItem('token');
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});

// Redirect to login on 401
api.interceptors.response.use(
  (res) => res,
  (err) => {
    if (err.response?.status === 401) {
      localStorage.removeItem('token');
      localStorage.removeItem('user');
      window.location.href = '/login';
    }
    return Promise.reject(err);
  }
);

// ── Auth ──────────────────────────────────────────────────────────────────────
export const authApi = {
  login:    (data) => api.post('/auth/login', data),
  register: (data) => api.post('/auth/register', data),
};

// ── Stocks ────────────────────────────────────────────────────────────────────
export const stockApi = {
  getAll:       ()               => api.get('/stocks'),
  getOne:       (symbol)         => api.get(`/stocks/${symbol}`),
  getPriceHistory: (symbol, from, to) =>
                                    api.get(`/stocks/${symbol}/price-history`, { params: { from, to } }),
  getSectors:   ()               => api.get('/stocks/sectors'),
};

// ── Screener ──────────────────────────────────────────────────────────────────
export const screenerApi = {
  screen:     (params) => api.get('/screener',     { params }),
  screenAll:  (params) => api.get('/screener/all', { params }),
  getFilters: ()       => api.get('/screener/filters'),
};

// ── Signals ───────────────────────────────────────────────────────────────────
export const signalApi = {
  getByDate:   (date, type) => api.get('/signals',        { params: { date, type } }),
  getBySymbol: (symbol)     => api.get(`/signals/${symbol}`),
};

// ── Watchlists ────────────────────────────────────────────────────────────────
export const watchlistApi = {
  getAll:      ()                    => api.get('/watchlists'),
  create:      (data)                => api.post('/watchlists', data),
  delete:      (id)                  => api.delete(`/watchlists/${id}`),
  addStock:    (id, symbol)          => api.post(`/watchlists/${id}/stocks`, { symbol }),
  removeStock: (id, symbol)          => api.delete(`/watchlists/${id}/stocks/${symbol}`),
};

// ── Alerts ────────────────────────────────────────────────────────────────────
export const alertApi = {
  getAll:  ()     => api.get('/alerts'),
  create:  (data) => api.post('/alerts', data),
  delete:  (id)   => api.delete(`/alerts/${id}`),
};

// ── AI Summary ────────────────────────────────────────────────────────────────
export const aiApi = {
  getSummary: (symbol) => api.get(`/ai/summary/${symbol}`),
};

// ── Backtest ──────────────────────────────────────────────────────────────────
export const backtestApi = {
  run:        (data) => api.post('/backtest', data),
  getHistory: ()     => api.get('/backtest/history'),
};

export default api;
