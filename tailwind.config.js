/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './index.html',
    './privacy-policy.html'
  ],
  theme: {
    extend: {
      spacing: {
        '0.2': '0.05rem',
        '13': '3.25rem'
      },
      scale: {
        '98': '0.98'
      }
    }
  },
  safelist: [
    'text-slate-100',
    'text-yellow-400',
    'text-amber-500',
    'text-emerald-400',
    'text-blue-400',
    'text-amber-700',
    'text-purple-400',
    'text-amber-300',
    'border-2',
    'border-amber-500',
    'shadow-amber-500/15',
    'ring-1',
    'ring-amber-500/40',
    'opacity-100',
    'translate-y-0',
    'opacity-0',
    '-translate-y-3',
    'col-span-2',
    'bg-cyan-950/60',
    'text-cyan-300',
    'border-cyan-500/40',
    'bg-rose-950/60',
    'text-rose-300',
    'border-rose-500/40'
  ],
  plugins: []
};
