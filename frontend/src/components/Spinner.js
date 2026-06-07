export default function Spinner({ size = 'md' }) {
  const s = size === 'sm' ? 'h-5 w-5' : size === 'lg' ? 'h-12 w-12' : 'h-8 w-8';
  return (
    <div className="flex justify-center items-center py-8">
      <div className={`${s} animate-spin rounded-full border-2 border-gray-600 border-t-blue-400`} />
    </div>
  );
}
