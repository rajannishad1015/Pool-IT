"use client"

import { Inter } from "next/font/google"
import { usePathname } from "next/navigation"
import { Sidebar } from "@/components/sidebar"
import Providers from "@/components/providers"
import "./globals.css"

const inter = Inter({ subsets: ["latin"] })

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  const pathname = usePathname()
  const isAuthPage = pathname?.startsWith("/auth")

  return (
    <html lang="en" suppressHydrationWarning>
      <body className={inter.className}>
        <Providers>
          {isAuthPage ? (
            <main className="min-h-screen w-full bg-slate-900">{children}</main>
          ) : (
            <div className="flex h-screen overflow-hidden">
              <Sidebar />
              <div className="flex flex-1 flex-col overflow-y-auto bg-slate-50/50">
                <header className="flex h-16 items-center justify-between border-b bg-white px-8 sticky top-0 z-40 shadow-sm/5">
                  <div className="flex items-center gap-3">
                    <div className="h-1.5 w-1.5 rounded-full bg-slate-300" />
                    <span className="text-[10px] font-bold text-slate-400 uppercase tracking-[0.2em]">NCR Region Operations</span>
                  </div>
                  <div className="flex items-center gap-6">
                    <div className="flex items-center gap-2 px-3 py-1.5 rounded-lg bg-slate-50 border border-slate-100">
                      <div className="flex h-1.5 w-1.5 rounded-full bg-red-500" />
                      <span className="text-[10px] font-bold text-slate-600 uppercase tracking-tight">2 System Alerts</span>
                    </div>
                    <div className="h-4 w-px bg-slate-200" />
                    <div className="flex items-center gap-3 cursor-pointer">
                      <div className="text-right">
                        <p className="text-sm font-semibold text-slate-900 leading-none">Rajan Nishad</p>
                        <p className="text-[10px] font-bold uppercase text-slate-400 tracking-wider mt-1">Super Admin</p>
                      </div>
                      <div className="h-9 w-9 rounded-xl bg-slate-100 border border-slate-200 flex items-center justify-center font-bold text-slate-600">
                        RN
                      </div>
                    </div>
                  </div>
                </header>
                <main className="p-10 max-w-[1600px] mx-auto w-full">{children}</main>
              </div>
            </div>
          )}
        </Providers>
      </body>
    </html>
  )
}
