import { useEffect, useState, useCallback } from 'react';
import { motion } from 'framer-motion';
import toast from 'react-hot-toast';
import { Search, Save, Move, Maximize, RotateCcw } from 'lucide-react';

interface Keyword {
  word: string;
  template: string;
  x: number;
  y: number;
  w: number;
  h: number;
  scale: number;
  triggers: string[];
}

export default function StickerPage() {
  const [keywords, setKeywords] = useState<Keyword[]>([]);
  const [selected, setSelected] = useState<Keyword | null>(null);
  const [search, setSearch] = useState('');
  const [editX, setEditX] = useState(0);
  const [editY, setEditY] = useState(0);
  const [editW, setEditW] = useState(80);
  const [editH, setEditH] = useState(80);
  const [editScale, setEditScale] = useState(1.0);
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    fetch('/api/stickers')
      .then(r => r.json())
      .then(d => setKeywords(d.keywords || []))
      .catch(() => toast.error('加载表情列表失败'));
  }, []);

  const selectKeyword = useCallback((kw: Keyword) => {
    setSelected(kw);
    setEditX(kw.x);
    setEditY(kw.y);
    setEditW(kw.w);
    setEditH(kw.h);
    setEditScale(kw.scale);
  }, []);

  const handleSave = async () => {
    if (!selected) return;
    setSaving(true);
    try {
      const res = await fetch(`/api/stickers/${encodeURIComponent(selected.word)}/update`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ x: editX, y: editY, w: editW, h: editH, scale: editScale }),
      });
      const data = await res.json();
      if (data.success) {
        toast.success(`已保存: ${selected.word}`);
        setKeywords(prev => prev.map(k =>
          k.word === selected.word
            ? { ...k, x: editX, y: editY, w: editW, h: editH, scale: editScale }
            : k
        ));
      } else {
        toast.error(data.error || '保存失败');
      }
    } catch {
      toast.error('保存失败');
    }
    setSaving(false);
  };

  const filtered = keywords.filter(k =>
    k.word.includes(search) || k.template.includes(search)
  );

  return (
    <div className="space-y-6">
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        className="glass-card p-6"
      >
        <h2 className="text-2xl font-bold text-gradient mb-4">表情包模板调整</h2>
        <p className="text-gray-600 text-sm mb-6">
          选择关键词，调整头像在模板中的位置和大小
        </p>

        <div className="flex gap-6 flex-col lg:flex-row">
          {/* 左侧列表 */}
          <div className="lg:w-80 flex-shrink-0">
            <div className="relative mb-3">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
              <input
                type="text"
                placeholder="搜索关键词..."
                value={search}
                onChange={e => setSearch(e.target.value)}
                className="input-field pl-9 w-full"
              />
            </div>
            <div className="h-[500px] overflow-y-auto space-y-1 pr-1">
              {filtered.map((kw, i) => (
                <motion.button
                  key={kw.word}
                  initial={{ opacity: 0, x: -10 }}
                  animate={{ opacity: 1, x: 0 }}
                  transition={{ delay: i * 0.02 }}
                  onClick={() => selectKeyword(kw)}
                  className={`w-full text-left px-3 py-2 rounded-lg transition-all text-sm ${
                    selected?.word === kw.word
                      ? 'bg-gradient-to-r from-[#f0a8d0] to-[#d9b0ff] text-white'
                      : 'hover:bg-white/40 text-gray-700'
                  }`}
                >
                  <span className="font-medium">{kw.word}</span>
                  <span className="text-xs ml-2 opacity-60">{kw.template}</span>
                  <span className="text-xs ml-2 opacity-50">
                    ({kw.x},{kw.y} {kw.w}x{kw.h})
                  </span>
                </motion.button>
              ))}
              {filtered.length === 0 && (
                <p className="text-gray-400 text-sm text-center py-8">无匹配</p>
              )}
            </div>
          </div>

          {/* 右侧编辑区 */}
          <div className="flex-1">
            {selected ? (
              <div className="space-y-4">
                {/* 模板预览 */}
                <div className="glass-card p-4">
                  <h3 className="font-semibold text-gray-800 mb-3 flex items-center gap-2">
                    <Maximize className="w-4 h-4 text-[#d9b0ff]" />
                    {selected.word} — 模板预览
                  </h3>
                  <div className="relative inline-block border border-gray-200 rounded-lg overflow-hidden bg-gray-50">
                    <img
                      src={`/templates/${selected.template}`}
                      alt={selected.template}
                      className="max-w-full"
                      style={{ maxHeight: 400 }}
                      onError={e => { (e.target as HTMLImageElement).style.display = 'none'; }}
                    />
                    <div
                      className="absolute border-2 border-red-500 bg-red-500/20 pointer-events-none"
                      style={{
                        left: editX,
                        top: editY,
                        width: editW,
                        height: editH,
                      }}
                    >
                      <span className="absolute -top-5 left-0 text-xs text-red-500 font-bold whitespace-nowrap">
                        {editW}x{editH}
                      </span>
                    </div>
                  </div>
                </div>

                {/* 控制参数 */}
                <div className="glass-card p-4">
                  <h3 className="font-semibold text-gray-800 mb-4 flex items-center gap-2">
                    <Move className="w-4 h-4 text-[#d9b0ff]" />
                    调整参数
                  </h3>
                  <div className="grid grid-cols-2 sm:grid-cols-3 gap-4">
                    <div>
                      <label className="block text-xs text-gray-500 mb-1">X (水平位置)</label>
                      <input
                        type="number"
                        value={editX}
                        onChange={e => setEditX(Number(e.target.value))}
                        className="input-field w-full"
                      />
                    </div>
                    <div>
                      <label className="block text-xs text-gray-500 mb-1">Y (垂直位置)</label>
                      <input
                        type="number"
                        value={editY}
                        onChange={e => setEditY(Number(e.target.value))}
                        className="input-field w-full"
                      />
                    </div>
                    <div>
                      <label className="block text-xs text-gray-500 mb-1">W (宽度)</label>
                      <input
                        type="number"
                        value={editW}
                        min={1}
                        onChange={e => setEditW(Number(e.target.value))}
                        className="input-field w-full"
                      />
                    </div>
                    <div>
                      <label className="block text-xs text-gray-500 mb-1">H (高度)</label>
                      <input
                        type="number"
                        value={editH}
                        min={1}
                        onChange={e => setEditH(Number(e.target.value))}
                        className="input-field w-full"
                      />
                    </div>
                    <div>
                      <label className="block text-xs text-gray-500 mb-1">Scale (缩放 0.1~2.0)</label>
                      <input
                        type="number"
                        value={editScale}
                        min={0.1}
                        max={2.0}
                        step={0.1}
                        onChange={e => setEditScale(Number(e.target.value))}
                        className="input-field w-full"
                      />
                    </div>
                  </div>

                  <div className="flex gap-3 mt-6">
                    <motion.button
                      whileTap={{ scale: 0.95 }}
                      onClick={handleSave}
                      disabled={saving}
                      className="btn-primary flex items-center gap-2"
                    >
                      <Save className="w-4 h-4" />
                      {saving ? '保存中...' : '保存'}
                    </motion.button>
                    <motion.button
                      whileTap={{ scale: 0.95 }}
                      onClick={() => selectKeyword(selected)}
                      className="btn-secondary flex items-center gap-2"
                    >
                      <RotateCcw className="w-4 h-4" />
                      重置
                    </motion.button>
                  </div>
                </div>
              </div>
            ) : (
              <div className="glass-card p-12 text-center text-gray-400">
                <p className="text-lg">← 从左侧选择一个关键词开始调整</p>
              </div>
            )}
          </div>
        </div>
      </motion.div>
    </div>
  );
}
