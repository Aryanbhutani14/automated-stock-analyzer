-- =============================================================
-- Automated Stock Analyzer — Sample / Seed Data
-- =============================================================

-- Sample users (password = 'Test@1234' bcrypt-hashed)
INSERT INTO users (username, email, password, role) VALUES
  ('admin',   'admin@example.com',   '$2a$10$placeholder_admin_hash',   'ADMIN'),
  ('aryan',   'aryan@example.com',   '$2a$10$placeholder_user_hash',    'USER');

-- Sample stocks (NSE India)
INSERT INTO stocks (symbol, name, exchange, sector, industry) VALUES
  ('RELIANCE', 'Reliance Industries Ltd',     'NSE', 'Energy',      'Oil & Gas'),
  ('TCS',      'Tata Consultancy Services',   'NSE', 'Technology',  'IT Services'),
  ('INFY',     'Infosys Ltd',                 'NSE', 'Technology',  'IT Services'),
  ('HDFCBANK', 'HDFC Bank Ltd',               'NSE', 'Financials',  'Banking'),
  ('ICICIBANK','ICICI Bank Ltd',              'NSE', 'Financials',  'Banking'),
  ('HINDUNILVR','Hindustan Unilever Ltd',     'NSE', 'Consumer',    'FMCG'),
  ('BAJFINANCE','Bajaj Finance Ltd',          'NSE', 'Financials',  'NBFC'),
  ('WIPRO',    'Wipro Ltd',                   'NSE', 'Technology',  'IT Services'),
  ('SBIN',     'State Bank of India',         'NSE', 'Financials',  'Banking'),
  ('ADANIENT', 'Adani Enterprises Ltd',       'NSE', 'Conglomerate','Diversified');
