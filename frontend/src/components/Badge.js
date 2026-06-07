export default function Badge({ type }) {
  if (!type) return null;
  const styles = {
    BUY:  'bg-green-900 text-green-400 border border-green-700',
    SELL: 'bg-red-900  text-red-400  border border-red-700',
    HOLD: 'bg-gray-700 text-gray-300 border border-gray-600',
  };
  return (
    <span className={`px-2 py-0.5 rounded text-xs font-semibold ${styles[type] || styles.HOLD}`}>
      {type}
    </span>
  );
}
