/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ['./src/**/*.{js,jsx,ts,tsx}'],
  theme: {
    extend: {
      colors: {
        // Custom palette for the stock dashboard
        bullish: '#22c55e',  // green
        bearish: '#ef4444',  // red
      },
    },
  },
  plugins: [],
};
