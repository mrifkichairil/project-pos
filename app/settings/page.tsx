"use client";

import { useState } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Switch } from "@/components/ui/switch";
import { Store, MapPin, Wifi, Percent } from "lucide-react";

export default function SettingsPage() {
  const [storeName, setStoreName] = useState("Warung Kita");
  const [address, setAddress] = useState("");
  const [wifiPassword, setWifiPassword] = useState("");
  const [taxEnabled, setTaxEnabled] = useState(false);
  const [taxRate, setTaxRate] = useState("10");
  const [saving, setSaving] = useState(false);

  const handleSave = async () => {
    setSaving(true);
    // Simulate API call
    await new Promise((resolve) => setTimeout(resolve, 1000));
    setSaving(false);
    alert("Pengaturan berhasil disimpan!");
  };

  return (
    <div className="flex h-full flex-col overflow-hidden">
      {/* Header */}
      <header className="flex h-16 items-center justify-between border-b px-4 sm:px-6">
        <h1 className="text-base font-semibold sm:text-lg">Pengaturan</h1>
      </header>

      {/* Content */}
      <div className="flex-1 overflow-y-auto p-4 sm:p-6">
        <div className="mx-auto max-w-2xl space-y-6">
          {/* Store Information */}
          <Card className="border-border/60">
            <CardHeader>
              <CardTitle className="flex items-center gap-2 text-sm font-semibold">
                <Store className="size-4" />
                Informasi Toko
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="space-y-2">
                <Label htmlFor="storeName" className="text-xs">
                  Nama Toko
                </Label>
                <Input
                  id="storeName"
                  value={storeName}
                  onChange={(e) => setStoreName(e.target.value)}
                  placeholder="Masukkan nama toko"
                  className="text-sm"
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="address" className="text-xs flex items-center gap-2">
                  <MapPin className="size-3.5" />
                  Alamat
                </Label>
                <Input
                  id="address"
                  value={address}
                  onChange={(e) => setAddress(e.target.value)}
                  placeholder="Masukkan alamat toko"
                  className="text-sm"
                />
              </div>
            </CardContent>
          </Card>

          {/* WiFi Settings */}
          <Card className="border-border/60">
            <CardHeader>
              <CardTitle className="flex items-center gap-2 text-sm font-semibold">
                <Wifi className="size-4" />
                Pengaturan WiFi
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="space-y-2">
                <Label htmlFor="wifiPassword" className="text-xs">
                  Password WiFi
                </Label>
                <Input
                  id="wifiPassword"
                  type="password"
                  value={wifiPassword}
                  onChange={(e) => setWifiPassword(e.target.value)}
                  placeholder="Masukkan password WiFi"
                  className="text-sm"
                />
              </div>
            </CardContent>
          </Card>

          {/* Tax Settings */}
          <Card className="border-border/60">
            <CardHeader>
              <CardTitle className="flex items-center gap-2 text-sm font-semibold">
                <Percent className="size-4" />
                Pengaturan Pajak
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="flex items-center justify-between rounded-lg border p-4">
                <div className="space-y-0.5">
                  <Label htmlFor="taxEnabled" className="text-xs font-medium">
                    Aktifkan Pajak
                  </Label>
                  <p className="text-[10px] text-muted-foreground">
                    Menambahkan pajak ke setiap transaksi
                  </p>
                </div>
                <Switch
                  id="taxEnabled"
                  checked={taxEnabled}
                  onCheckedChange={setTaxEnabled}
                />
              </div>
              {taxEnabled && (
                <div className="space-y-2 animate-in fade-in-0 slide-in-from-top-2 duration-300">
                  <Label htmlFor="taxRate" className="text-xs">
                    Tarif Pajak (%)
                  </Label>
                  <Input
                    id="taxRate"
                    type="number"
                    value={taxRate}
                    onChange={(e) => setTaxRate(e.target.value)}
                    placeholder="Masukkan tarif pajak"
                    className="text-sm"
                    min="0"
                    max="100"
                  />
                </div>
              )}
            </CardContent>
          </Card>

          {/* Save Button */}
          <div className="flex justify-end gap-2">
            <Button
              onClick={handleSave}
              disabled={saving}
              className="min-w-[120px]"
            >
              {saving ? "Menyimpan..." : "Simpan"}
            </Button>
          </div>
        </div>
      </div>
    </div>
  );
}
