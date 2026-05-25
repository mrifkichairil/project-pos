# Warung Kita POS

Warung Kita POS adalah aplikasi point-of-sale berbasis web untuk operasional warung/restoran. Aplikasi ini mencakup kasir, dashboard, menu, inventori, transaksi, member/loyalty, pengaturan toko, pengguna, dan fondasi multi-tenant.

## Stack

- Next.js 16 App Router
- React 19
- TypeScript
- PostgreSQL dengan `pg`
- Tailwind CSS 4
- shadcn/ui `base-nova` dengan ikon Lucide
- Midtrans Snap untuk pembayaran
- Vitest dan Testing Library

## Fitur Utama

- Login internal dengan cookie session `session_token`.
- Role pengguna: `admin`, `manager`, dan `cashier`.
- Multi-tenant shared schema melalui tabel `tenants`, `user_tenants`, dan `auth_sessions`.
- POS kasir untuk membuat order, menghitung pajak/layanan, add-on, member, poin, dan refund.
- Dashboard ringkasan operasional.
- Manajemen menu, bahan baku, HPP, harga jual, kategori, dan add-on.
- Inventori bahan dan stok.
- Riwayat transaksi.
- Member, tier, saldo poin, dan ledger poin.
- Pengaturan toko: nama, alamat, WiFi, PB1, service charge, PPN, QRIS, dan konversi poin.
- Manajemen tenant dan user.

## Kebutuhan Lokal

- Node.js 20.9 atau lebih baru.
- npm.
- PostgreSQL.
- `psql` jika ingin menjalankan migrasi lewat terminal.

## Setup

1. Install dependency:

```bash
npm install
```

2. Buat file `.env` atau `.env.local`:

```env
DATABASE_URL=postgresql://postgres:password@localhost:5432/warung_kita
MIDTRANS_IS_PRODUCTION=false
MIDTRANS_SERVER_KEY=
MIDTRANS_CLIENT_KEY=
```

3. Buat database PostgreSQL, lalu jalankan migrasi SQL secara berurutan dari `database/migrations`.

Contoh PowerShell:

```powershell
$env:DATABASE_URL="postgresql://postgres:password@localhost:5432/warung_kita"
Get-ChildItem database/migrations/*.sql | Sort-Object Name | ForEach-Object {
  psql $env:DATABASE_URL -f $_.FullName
}
```

4. Isi data awal. Untuk demo multi-tenant lengkap, gunakan:

Bash/macOS/Linux:

```bash
psql "$DATABASE_URL" -f database/seed/seed-all.sql
```

PowerShell:

```powershell
psql $env:DATABASE_URL -f database/seed/seed-all.sql
```

5. Jalankan development server:

```bash
npm run dev
```

Buka `http://localhost:3000`.

## Akun Seed

Jika memakai `database/seed/seed-all.sql`, semua password di bawah adalah `password`.

- `admin`
- `manager_a`
- `kasir_a1`
- `kasir_a2`
- `manager_b`
- `kasir_b1`
- `kasir_b2`

Jika migrasi `020_seed_superadmin.sql` dijalankan, tersedia juga:

- username: `superadmin`
- password: `admin123`

## Script

```bash
npm run dev          # server development
npm run build        # build produksi
npm run start        # menjalankan build produksi
npm run lint         # ESLint
npm run test         # Vitest sekali jalan
npm run test:watch   # Vitest watch mode
```

## Struktur Proyek

```text
app/                  Halaman App Router dan API route handlers
components/           Komponen layout dan shadcn/ui
database/migrations/  Migrasi PostgreSQL
database/seed/        Data awal/demo
lib/                  DB client, session, tenant scope, payment, utils
public/               Asset statis
docs/                 Catatan dan rencana teknis
```

Rute utama aplikasi:

- `/` - login
- `/dashboard`
- `/pos`
- `/inventory`
- `/transactions`
- `/member`
- `/menu`
- `/user`
- `/tenant`
- `/settings`

## Database dan Multi-Tenant

Migrasi multi-tenant memakai urutan expand, backfill, contract:

1. `017_add_multitenant_foundation_expand.sql`
2. `018_backfill_multitenant_default_tenant.sql`
3. `019_enforce_multitenant_constraints_contract.sql`

Validasi setelah migrasi:

```sql
SELECT COUNT(*) FROM tenants;
SELECT COUNT(*) FROM users WHERE active_tenant_id IS NULL;
SELECT COUNT(*) FROM menus WHERE tenant_id IS NULL;
```

Untuk rollout aman, jalankan tahap expand dan backfill lebih dulu, deploy API yang sudah tenant-aware, lalu jalankan contract setelah data dan aplikasi tervalidasi.

## Catatan Pengembangan

- Koneksi database dibuat di `lib/db.ts` dan wajib memakai `DATABASE_URL`.
- Session aktif dibaca dari cookie `session_token` melalui `lib/get-session.ts`.
- Endpoint yang butuh tenant aktif dapat memakai helper `requireTenantScope()` dari `lib/tenant-scope.ts`.
- Komponen UI mengikuti konfigurasi `components.json` dan berada di `components/ui`.
- Proyek ini memakai Next.js 16; baca dokumentasi lokal di `node_modules/next/dist/docs/` sebelum mengubah API atau pola App Router.
