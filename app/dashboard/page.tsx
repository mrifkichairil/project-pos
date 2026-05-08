"use client";

import { useState, useEffect } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { cn } from "@/lib/utils";
import {
  TrendingUp,
  TrendingDown,
  DollarSign,
  ShoppingCart,
  BarChart3,
  Wallet,
  ArrowUpRight,
  Banknote,
  QrCode,
  Smartphone,
  CalendarDays,
} from "lucide-react";

type Period = "daily" | "weekly" | "monthly" | "yearly";

const periods: { label: string; value: Period }[] = [
  { label: "Hari Ini", value: "daily" },
  { label: "Minggu Ini", value: "weekly" },
  { label: "Bulan Ini", value: "monthly" },
  { label: "Tahun Ini", value: "yearly" },
];

function formatRp(n: number) {
  return "Rp. " + n.toLocaleString("id-ID");
}

interface ChartBar { label: string; val: number }
interface RankItem { name: string; qty: number | string; pct: number }
interface PayItem { label: string; value: number; pct: number; icon: React.ElementType; color: string }
interface StatItem { label: string; value: string; change: string; trend: "up" | "down"; icon: React.ElementType }

interface PData {
  stats: StatItem[];
  revenue: PayItem[];
  leftChart: ChartBar[];
  leftTitle: string;
  leftColor: string;
  leftInsight: string;
  rightChart: ChartBar[];
  rightTitle: string;
  rightInsight: string;
  best: RankItem[];
  least: RankItem[];
}

const allData: Record<Period, PData> = {
  daily: {
    stats: [
      { label: "Total Revenue Hari Ini", value: "Rp. 2.847.000", change: "+12% vs kemarin", trend: "up", icon: DollarSign },
      { label: "Total Transaksi", value: "48", change: "+5 vs kemarin", trend: "up", icon: ShoppingCart },
      { label: "Average Order Value", value: "Rp. 59.300", change: "+3% vs kemarin", trend: "up", icon: BarChart3 },
      { label: "Profit (estimasi)", value: "Rp. 1.423.000", change: "+8% vs kemarin", trend: "up", icon: Wallet },
      { label: "Growth vs Kemarin", value: "+12%", change: "Revenue naik signifikan", trend: "up", icon: TrendingUp },
    ],
    revenue: [
      { label: "Cash", value: 1423500, pct: 50, icon: Banknote, color: "bg-emerald-500" },
      { label: "QRIS", value: 854100, pct: 30, icon: QrCode, color: "bg-blue-500" },
      { label: "E-Wallet", value: 569400, pct: 20, icon: Smartphone, color: "bg-violet-500" },
    ],
    leftChart: [
      { label: "08", val: 120 }, { label: "09", val: 280 }, { label: "10", val: 450 },
      { label: "11", val: 620 }, { label: "12", val: 890 }, { label: "13", val: 750 },
      { label: "14", val: 540 }, { label: "15", val: 380 }, { label: "16", val: 420 },
      { label: "17", val: 560 }, { label: "18", val: 720 }, { label: "19", val: 640 },
      { label: "20", val: 480 },
    ],
    leftTitle: "Sales per Jam (Hari Ini)",
    leftColor: "bg-amber-500",
    leftInsight: "Peak jam 12 siang (890 trx). Siapkan 2 kasir di jam 11–13 & 17–19 untuk antrian.",
    rightChart: [
      { label: "Sen", val: 1800000 }, { label: "Sel", val: 2100000 }, { label: "Rab", val: 1950000 },
      { label: "Kam", val: 2847000 }, { label: "Jum", val: 3200000 }, { label: "Sab", val: 4500000 },
      { label: "Min", val: 3900000 },
    ],
    rightTitle: "Sales 7 Hari Terakhir",
    rightInsight: "Sabtu paling rame. Hari ini (Kam) sepi 37% vs Sabtu — pertimbangkan promo sore.",
    best: [
      { name: "Nasi Goreng", qty: 42, pct: 100 }, { name: "Es Buah", qty: 36, pct: 86 },
      { name: "Rendang", qty: 28, pct: 67 }, { name: "Sate Ayam", qty: 24, pct: 57 },
      { name: "Gado-Gado", qty: 19, pct: 45 },
    ],
    least: [
      { name: "Es Teler", qty: 3, pct: 7 }, { name: "Puding Coklat", qty: 5, pct: 12 },
      { name: "Klepon", qty: 6, pct: 14 }, { name: "Es Doger", qty: 8, pct: 19 },
      { name: "Bubur Sumsum", qty: 9, pct: 21 },
    ],
  },
  weekly: {
    stats: [
      { label: "Total Revenue Minggu Ini", value: "Rp. 19.850.000", change: "+8% vs minggu lalu", trend: "up", icon: DollarSign },
      { label: "Total Transaksi", value: "312", change: "+24 vs minggu lalu", trend: "up", icon: ShoppingCart },
      { label: "Average Order Value", value: "Rp. 63.600", change: "+5% vs minggu lalu", trend: "up", icon: BarChart3 },
      { label: "Profit (estimasi)", value: "Rp. 9.925.000", change: "+8% vs minggu lalu", trend: "up", icon: Wallet },
      { label: "Growth vs Minggu Lalu", value: "+8%", change: "Tren positif konsisten", trend: "up", icon: TrendingUp },
    ],
    revenue: [
      { label: "Cash", value: 8932500, pct: 45, icon: Banknote, color: "bg-emerald-500" },
      { label: "QRIS", value: 6947500, pct: 35, icon: QrCode, color: "bg-blue-500" },
      { label: "E-Wallet", value: 3970000, pct: 20, icon: Smartphone, color: "bg-violet-500" },
    ],
    leftChart: [
      { label: "Sen", val: 2400000 }, { label: "Sel", val: 2800000 }, { label: "Rab", val: 2600000 },
      { label: "Kam", val: 2847000 }, { label: "Jum", val: 3500000 }, { label: "Sab", val: 4200000 },
      { label: "Min", val: 1503000 },
    ],
    leftTitle: "Sales per Hari (Minggu Ini)",
    leftColor: "bg-primary",
    leftInsight: "Sabtu masih jadi puncak. Rabu relatif sepi — tambahkan promo mid-week untuk dorong traffic.",
    rightChart: [
      { label: "W-4", val: 16500000 }, { label: "W-3", val: 17800000 },
      { label: "W-2", val: 18400000 }, { label: "W-1", val: 19850000 },
    ],
    rightTitle: "Sales 4 Minggu Terakhir",
    rightInsight: "Tren naik 4 minggu berturut-turut. Pertahankan momentum dengan konsistensi layanan.",
    best: [
      { name: "Nasi Goreng", qty: 285, pct: 100 }, { name: "Es Buah", qty: 241, pct: 85 },
      { name: "Ayam Goreng", qty: 198, pct: 70 }, { name: "Rendang", qty: 172, pct: 60 },
      { name: "Kopi Susu", qty: 143, pct: 50 },
    ],
    least: [
      { name: "Es Teler", qty: 18, pct: 6 }, { name: "Klepon", qty: 24, pct: 8 },
      { name: "Puding Coklat", qty: 30, pct: 11 }, { name: "Bolu", qty: 35, pct: 12 },
      { name: "Es Doger", qty: 42, pct: 15 },
    ],
  },
  monthly: {
    stats: [
      { label: "Total Revenue Bulan Ini", value: "Rp. 78.500.000", change: "+15% vs bulan lalu", trend: "up", icon: DollarSign },
      { label: "Total Transaksi", value: "1.240", change: "+142 vs bulan lalu", trend: "up", icon: ShoppingCart },
      { label: "Average Order Value", value: "Rp. 63.300", change: "+2% vs bulan lalu", trend: "up", icon: BarChart3 },
      { label: "Profit (estimasi)", value: "Rp. 39.250.000", change: "+15% vs bulan lalu", trend: "up", icon: Wallet },
      { label: "Growth vs Bulan Lalu", value: "+15%", change: "Bulan terbaik tahun ini", trend: "up", icon: TrendingUp },
    ],
    revenue: [
      { label: "Cash", value: 37680000, pct: 48, icon: Banknote, color: "bg-emerald-500" },
      { label: "QRIS", value: 25120000, pct: 32, icon: QrCode, color: "bg-blue-500" },
      { label: "E-Wallet", value: 15700000, pct: 20, icon: Smartphone, color: "bg-violet-500" },
    ],
    leftChart: [
      { label: "W1", val: 18500000 }, { label: "W2", val: 19800000 },
      { label: "W3", val: 21200000 }, { label: "W4", val: 19000000 },
    ],
    leftTitle: "Sales per Minggu (Bulan Ini)",
    leftColor: "bg-blue-500",
    leftInsight: "Minggu ke-3 terkuat. Pastikan stok dan SDM cukup terutama di pertengahan bulan.",
    rightChart: [
      { label: "Nov", val: 61000000 }, { label: "Des", val: 72000000 },
      { label: "Jan", val: 65000000 }, { label: "Feb", val: 68000000 },
      { label: "Mar", val: 74500000 }, { label: "Apr", val: 78500000 },
    ],
    rightTitle: "Sales 6 Bulan Terakhir",
    rightInsight: "Tren naik konsisten 6 bulan terakhir. Target bulan depan: Rp. 85.000.000.",
    best: [
      { name: "Nasi Goreng", qty: "1.150", pct: 100 }, { name: "Es Buah", qty: 980, pct: 85 },
      { name: "Ayam Goreng", qty: 820, pct: 71 }, { name: "Rendang", qty: 710, pct: 62 },
      { name: "Kopi Susu", qty: 630, pct: 55 },
    ],
    least: [
      { name: "Es Teler", qty: 72, pct: 6 }, { name: "Klepon", qty: 98, pct: 9 },
      { name: "Puding Coklat", qty: 115, pct: 10 }, { name: "Bolu", qty: 134, pct: 12 },
      { name: "Es Doger", qty: 162, pct: 14 },
    ],
  },
  yearly: {
    stats: [
      { label: "Total Revenue Tahun Ini", value: "Rp. 850.000.000", change: "+22% vs tahun lalu", trend: "up", icon: DollarSign },
      { label: "Total Transaksi", value: "13.200", change: "+1.840 vs tahun lalu", trend: "up", icon: ShoppingCart },
      { label: "Average Order Value", value: "Rp. 64.400", change: "+4% vs tahun lalu", trend: "up", icon: BarChart3 },
      { label: "Profit (estimasi)", value: "Rp. 425.000.000", change: "+22% vs tahun lalu", trend: "up", icon: Wallet },
      { label: "Growth vs Tahun Lalu", value: "+22%", change: "Pertumbuhan terbaik", trend: "up", icon: TrendingUp },
    ],
    revenue: [
      { label: "Cash", value: 357000000, pct: 42, icon: Banknote, color: "bg-emerald-500" },
      { label: "QRIS", value: 323000000, pct: 38, icon: QrCode, color: "bg-blue-500" },
      { label: "E-Wallet", value: 170000000, pct: 20, icon: Smartphone, color: "bg-violet-500" },
    ],
    leftChart: [
      { label: "Jan", val: 58000000 }, { label: "Feb", val: 62000000 }, { label: "Mar", val: 68000000 },
      { label: "Apr", val: 71000000 }, { label: "Mei", val: 78500000 }, { label: "Jun", val: 0 },
      { label: "Jul", val: 0 }, { label: "Agu", val: 0 }, { label: "Sep", val: 0 },
      { label: "Okt", val: 0 }, { label: "Nov", val: 0 }, { label: "Des", val: 0 },
    ],
    leftTitle: "Sales per Bulan (Tahun Ini)",
    leftColor: "bg-violet-500",
    leftInsight: "Tren naik Jan–Mei. Proyeksi tutup tahun Rp. 1 Miliar jika momentum terjaga.",
    rightChart: [
      { label: "2022", val: 520000000 }, { label: "2023", val: 620000000 },
      { label: "2024", val: 695000000 }, { label: "2025", val: 720000000 },
      { label: "2026*", val: 850000000 },
    ],
    rightTitle: "Sales per Tahun (5 Tahun Terakhir)",
    rightInsight: "Tumbuh rata-rata 15%/tahun. 2026 proyeksi tertinggi sepanjang sejarah bisnis.",
    best: [
      { name: "Nasi Goreng", qty: "13.800", pct: 100 }, { name: "Es Buah", qty: "11.750", pct: 85 },
      { name: "Ayam Goreng", qty: "9.800", pct: 71 }, { name: "Rendang", qty: "8.500", pct: 62 },
      { name: "Kopi Susu", qty: "7.600", pct: 55 },
    ],
    least: [
      { name: "Es Teler", qty: 870, pct: 6 }, { name: "Klepon", qty: "1.180", pct: 9 },
      { name: "Puding Coklat", qty: "1.380", pct: 10 }, { name: "Bolu", qty: "1.610", pct: 12 },
      { name: "Es Doger", qty: "1.950", pct: 14 },
    ],
  },
};

export default function DashboardPage() {
  const [period, setPeriod] = useState<Period>("daily");
  const [visible, setVisible] = useState(false);
  const d = allData[period];

  useEffect(() => {
    const t = setTimeout(() => setVisible(true), 140);
    return () => clearTimeout(t);
  }, [period]);

  const maxLeft = Math.max(...d.leftChart.map((b) => b.val), 1);
  const maxRight = Math.max(...d.rightChart.map((b) => b.val), 1);

  return (
    <div className="flex h-full flex-col overflow-hidden">
      {/* Header */}
      <header className="flex h-16 items-center justify-between border-b px-4 sm:px-6">
        <h1 className="text-base font-semibold sm:text-lg">Dashboard</h1>
      </header>

      {/* Content */}
      <div className="flex-1 overflow-y-auto p-4 sm:p-6">
        {/* Period Filter */}
        <div className="mb-4 flex flex-wrap items-center gap-2">
          {periods.map((p) => (
            <Button
              key={p.value}
              variant={period === p.value ? "default" : "outline"}
              size="sm"
              className={cn(
                "h-8 rounded-lg text-xs",
                period === p.value && "bg-primary text-primary-foreground"
              )}
              onClick={() => {
                if (period === p.value) return;
                setVisible(false);
                setPeriod(p.value);
              }}
            >
              {p.label}
            </Button>
          ))}
          <div className="ml-2 flex items-center gap-1.5 rounded-lg border px-2.5 py-1.5 text-xs text-muted-foreground">
            <CalendarDays className="size-3.5" />
            <span>{new Date().toLocaleDateString("id-ID")}</span>
          </div>
        </div>

        {/* Animated content wrapper */}
        <div
          key={period}
          className="animate-in fade-in-0 slide-in-from-bottom-3 duration-[1500ms]"
        >
          {/* Stats */}
          <div className="mb-6 grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-5">
            {d.stats.map((s) => (
              <Card key={s.label} className="relative overflow-hidden border-border/60">
                <s.icon className="absolute -bottom-1 right-2 size-24 opacity-[0.06]" strokeWidth={1.2} />
                <CardContent className="relative z-10 p-3 sm:p-4">
                  <div className="flex items-center justify-between">
                    <span className="text-[10px] text-muted-foreground sm:text-[11px]">{s.label}</span>
                    <div className="flex items-center gap-0.5 text-[10px] sm:text-[11px]">
                      {s.trend === "up" ? (
                        <TrendingUp className="size-2.5 text-emerald-500 sm:size-3" />
                      ) : (
                        <TrendingDown className="size-2.5 text-red-500 sm:size-3" />
                      )}
                      <span className={s.trend === "up" ? "text-emerald-600" : "text-red-600"}>{s.change}</span>
                    </div>
                  </div>
                  <p className="mt-1 text-base font-semibold sm:text-lg">{s.value}</p>
                </CardContent>
              </Card>
            ))}
          </div>

          {/* Revenue Breakdown */}
          <Card className="mb-6 border-border/60">
            <CardHeader className="pb-2">
              <CardTitle className="text-xs font-semibold sm:text-sm">Revenue Breakdown by Payment</CardTitle>
            </CardHeader>
            <CardContent>
              <div
                className="mb-3 flex h-5 overflow-hidden rounded-full"
                style={{
                  transform: visible ? "scaleX(1)" : "scaleX(0)",
                  transformOrigin: "left",
                  transition: "transform 4.8s cubic-bezier(0.22, 1, 0.36, 1)",
                }}
              >
                {d.revenue.map((p) => (
                  <div
                    key={p.label}
                    className={cn(p.color, "h-full")}
                    style={{ width: `${p.pct}%` }}
                    title={`${p.label}: ${formatRp(p.value)} (${p.pct}%)`}
                  />
                ))}
              </div>
              <div className="flex flex-wrap gap-4 sm:gap-6">
                {d.revenue.map((p) => (
                  <div key={p.label} className="flex items-center gap-2">
                    <div className={cn("size-3 rounded-full", p.color)} />
                    <p.icon className="size-3.5 text-muted-foreground" />
                    <span className="text-xs font-medium">{p.label}</span>
                    <span className="text-xs text-muted-foreground">{formatRp(p.value)} ({p.pct}%)</span>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>

          {/* Charts */}
          <div className="mb-6 grid grid-cols-1 gap-4 lg:grid-cols-2">
            {/* Left chart */}
            <Card className="border-border/60">
              <CardHeader className="pb-2">
                <CardTitle className="text-xs font-semibold sm:text-sm">{d.leftTitle}</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="flex items-end gap-1 pt-2" style={{ height: 140 }}>
                  {d.leftChart.map((bar) => (
                    <div key={bar.label} className="flex flex-1 flex-col items-center gap-1">
                      <div
                        className={cn("w-full rounded-t opacity-80 hover:opacity-100", d.leftColor)}
                        style={{
                          height: visible ? `${(bar.val / maxLeft) * 100}%` : "0%",
                          transition: "height 3.4s cubic-bezier(0.22, 1, 0.36, 1)",
                          minHeight: bar.val > 0 ? undefined : undefined,
                        }}
                      />
                      <span className="text-[9px] text-muted-foreground sm:text-[10px]">{bar.label}</span>
                    </div>
                  ))}
                </div>
                <div className="mt-3 flex items-start gap-1.5 rounded-lg bg-muted/30 p-2 text-[10px] text-muted-foreground sm:text-[11px]">
                  <ArrowUpRight className="mt-0.5 size-2.5 shrink-0 text-emerald-500 sm:size-3" />
                  <span>{d.leftInsight}</span>
                </div>
              </CardContent>
            </Card>

            {/* Right chart */}
            <Card className="border-border/60">
              <CardHeader className="pb-2">
                <CardTitle className="text-xs font-semibold sm:text-sm">{d.rightTitle}</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="flex items-end gap-1.5 pt-2" style={{ height: 140 }}>
                  {d.rightChart.map((bar) => (
                    <div key={bar.label} className="flex flex-1 flex-col items-center gap-1">
                      <div
                        className="w-full rounded-t bg-primary/70 hover:bg-primary"
                        style={{
                          height: visible ? `${(bar.val / maxRight) * 100}%` : "0%",
                          transition: "height 3.6s cubic-bezier(0.22, 1, 0.36, 1) 0.25s",
                        }}
                      />
                      <span className="text-[9px] text-muted-foreground sm:text-[10px]">{bar.label}</span>
                    </div>
                  ))}
                </div>
                <div className="mt-3 flex items-start gap-1.5 rounded-lg bg-muted/30 p-2 text-[10px] text-muted-foreground sm:text-[11px]">
                  <ArrowUpRight className="mt-0.5 size-2.5 shrink-0 text-emerald-500 sm:size-3" />
                  <span>{d.rightInsight}</span>
                </div>
              </CardContent>
            </Card>
          </div>

          {/* Best & Worst Menu */}
          <div className="mb-6 grid grid-cols-1 gap-4 lg:grid-cols-2">
            {/* Best Seller */}
            <Card className="border-border/60">
              <CardHeader className="pb-2">
                <CardTitle className="flex items-center gap-2 text-xs font-semibold sm:text-sm">
                  <span className="inline-block size-2 rounded-full bg-emerald-500" />
                  Best Seller
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-3 pt-0">
                {d.best.map((item, i) => (
                  <div key={i}>
                    <div className="mb-1 flex items-center justify-between text-xs">
                      <span className="font-medium">{i + 1}. {item.name}</span>
                      <span className="text-muted-foreground">{item.qty} pcs</span>
                    </div>
                    <div className="h-1.5 w-full overflow-hidden rounded-full bg-muted">
                      <div
                        className="h-full rounded-full bg-emerald-500"
                        style={{
                          width: visible ? `${item.pct}%` : "0%",
                          transition: `width 3.2s cubic-bezier(0.22, 1, 0.36, 1) ${i * 0.32}s`,
                        }}
                      />
                    </div>
                  </div>
                ))}
              </CardContent>
            </Card>

            {/* Least Selling */}
            <Card className="border-border/60">
              <CardHeader className="pb-2">
                <CardTitle className="flex items-center gap-2 text-xs font-semibold sm:text-sm">
                  <span className="inline-block size-2 rounded-full bg-red-500" />
                  Least Selling
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-3 pt-0">
                {d.least.map((item, i) => (
                  <div key={i}>
                    <div className="mb-1 flex items-center justify-between text-xs">
                      <span className="font-medium">{i + 1}. {item.name}</span>
                      <span className="text-muted-foreground">{item.qty} pcs</span>
                    </div>
                    <div className="h-1.5 w-full overflow-hidden rounded-full bg-muted">
                      <div
                        className="h-full rounded-full bg-red-400"
                        style={{
                          width: visible ? `${item.pct}%` : "0%",
                          transition: `width 3.2s cubic-bezier(0.22, 1, 0.36, 1) ${i * 0.32}s`,
                        }}
                      />
                    </div>
                  </div>
                ))}
              </CardContent>
            </Card>
          </div>
        </div>
      </div>
    </div>
  );
}
