"use client"

import Link from "next/link"
import { usePathname } from "next/navigation"
import { cn } from "@/lib/utils"
import {
  LayoutDashboard,
  Users,
  Car,
  FileCheck,
  ShieldAlert,
  Wallet,
  MessageSquare,
  BarChart3,
  Settings,
  Bell,
  LogOut,
  ChevronRight,
  ShieldCheck, // Added
  CreditCard, // Added
  Headphones, // Added
} from "lucide-react"

const menuItems = [
  { icon: LayoutDashboard, label: "Dashboard", href: "/" },
  { icon: BarChart3, label: "Live Monitoring", href: "/monitoring" },
  { icon: Users, label: "Passengers", href: "/riders" },
  { icon: Car, label: "Drivers", href: "/drivers" },
  { icon: ShieldCheck, label: "Document Checks", href: "/verification" },
  { icon: ShieldAlert, label: "Safety Alerts", href: "/safety" },
  { icon: Wallet, label: "Payments", href: "/finance" },
  { icon: MessageSquare, label: "Help Desk", href: "/support" },
  { icon: Settings, label: "Settings", href: "/settings" },
]

export function Sidebar() {
  const pathname = usePathname()

  return (
    <div className="flex h-screen w-72 flex-col bg-[#0F172A] text-slate-300 shadow-2xl z-50 overflow-hidden">
      <div className="flex h-20 items-center border-b border-slate-800/50 px-8">
        <div className="flex items-center gap-3">
          <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-blue-600 shadow-lg shadow-blue-900/40">
            <ShieldAlert className="h-6 w-6 text-white" />
          </div>
          <div className="flex flex-col">
            <span className="text-lg font-bold tracking-tight text-white">SmartPool</span>
            <span className="text-[10px] uppercase tracking-widest text-slate-500 font-bold">Admin Panel</span>
          </div>
        </div>
      </div>

      <div className="flex-1 overflow-y-auto py-6 custom-scrollbar">
        <p className="px-8 text-[10px] font-bold uppercase tracking-widest text-slate-500 mb-4">Operations</p>
        <nav className="space-y-1 px-4">
          {menuItems.map((item) => {
            const isActive = pathname === item.href
            return (
              <Link
                key={item.href}
                href={item.href}
                className={cn(
                  "group flex items-center justify-between gap-3 rounded-xl px-4 py-3 text-sm font-medium transition-all duration-200",
                  isActive
                    ? "bg-blue-600 text-white shadow-lg shadow-blue-600/20"
                    : "text-slate-400 hover:bg-slate-800/50 hover:text-slate-100"
                )}
              >
                <div className="flex items-center gap-3">
                  <item.icon className={cn("h-5 w-5", isActive ? "text-white" : "text-slate-500 group-hover:text-blue-400")} />
                  {item.label}
                </div>
                {isActive && <ChevronRight className="h-4 w-4 opacity-70" />}
              </Link>
            )
          })}
        </nav>
      </div>

      <div className="border-t border-slate-800/50 p-6 bg-slate-900/50">
        <button className="flex w-full items-center gap-3 rounded-xl px-4 py-3 text-sm font-semibold text-red-400 transition-all hover:bg-red-500/10 hover:shadow-inner">
          <LogOut className="h-5 w-5" />
          Sign Out
        </button>
      </div>
    </div>
  )
}
