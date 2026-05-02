import type { ReactNode } from "react";
import AppShell from "@/components/layout/AppShell";

export default function PosLayout({ children }: { children: ReactNode }) {
  return <AppShell>{children}</AppShell>;
}
