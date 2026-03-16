"use client"

import { cn } from "@/lib/utils"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { useQuery, useQueryClient } from "@tanstack/react-query"
import { supabase } from "@/lib/supabase"
import { useEffect } from "react"
import { 
  Users, 
  Car, 
  Clock, 
  ShieldAlert, 
  ArrowUpRight, 
  ArrowDownRight,
  Map as MapIcon,
  Search,
  MoreHorizontal,
  Activity,
  MessageSquare
} from "lucide-react"
import Link from "next/link"

export default function DashboardOverview() {
  const queryClient = useQueryClient()

  // Real-time KPI Queries
  const { data: activeRidesCount = 0 } = useQuery({
    queryKey: ["active-rides-count"],
    queryFn: async () => {
      const { count } = await supabase.from('rides').select('*', { count: 'exact', head: true }).eq('status', 'active')
      return count || 0
    }
  })

  const { data: passengersCount = 0 } = useQuery({
    queryKey: ["passengers-count"],
    queryFn: async () => {
      const { count } = await supabase.from('profiles').select('*', { count: 'exact', head: true })
      return count || 0
    }
  })

  const { data: driversOnlineCount = 0 } = useQuery({
    queryKey: ["drivers-online-count"],
    queryFn: async () => {
      const { count } = await supabase.from('drivers').select('*', { count: 'exact', head: true }).eq('is_online', true)
      return count || 0
    }
  })

  const { data: pendingVerificationsCount = 0 } = useQuery({
    queryKey: ["pending-verifications-count"],
    queryFn: async () => {
      const { count } = await supabase.from('drivers').select('*', { count: 'exact', head: true }).eq('verification_status', 'pending')
      return count || 0
    }
  })

  // Real-time Activity Feed
  const { data: activityItems = [] } = useQuery({
    queryKey: ["dashboard-activity"],
    queryFn: async () => {
      // Combining recent events for a unified feed
      const { data: docs } = await supabase.from('driver_documents')
        .select('id, doc_type, created_at, profiles:driver_id(full_name)')
        .eq('status', 'pending')
        .order('created_at', { ascending: false })
        .limit(3)
      
      const { data: newUsers } = await supabase.from('profiles')
        .select('id, full_name, created_at')
        .order('created_at', { ascending: false })
        .limit(3)

      const { data: safetyAlerts } = await supabase.from('safety_incidents')
        .select('id, type, created_at, profiles:user_id(full_name)')
        .order('created_at', { ascending: false })
        .limit(3)

      const { data: supportTickets } = await supabase.from('support_tickets')
        .select('id, subject, created_at, profiles:user_id(full_name)')
        .eq('status', 'open')
        .order('created_at', { ascending: false })
        .limit(3)

      const items = [
        ...(docs || []).map(d => ({
          id: d.id,
          type: "verification",
          title: "Document Pending Review",
          subtitle: `${(d.profiles as any)?.full_name || 'Driver'} • ${d.doc_type}`,
          time: d.created_at,
          icon: Clock,
          color: "blue"
        })),
        ...(newUsers || []).map(u => ({
          id: u.id,
          type: "security",
          title: "New User Registered",
          subtitle: u.full_name || 'Unnamed User',
          time: u.created_at,
          icon: ShieldAlert,
          color: "rose"
        })),
        ...(safetyAlerts || []).map(s => ({
          id: s.id,
          type: "safety",
          title: s.type,
          subtitle: (s.profiles as any)?.full_name || 'System Alert',
          time: s.created_at,
          icon: ShieldAlert,
          color: "rose"
        })),
        ...(supportTickets || []).map(t => ({
          id: t.id,
          type: "support",
          title: t.subject,
          subtitle: (t.profiles as any)?.full_name || 'New Inquiry',
          time: t.created_at,
          icon: MessageSquare,
          color: "blue"
        }))
      ].sort((a, b) => new Date(b.time || '').getTime() - new Date(a.time || '').getTime())

      return items
    }
  })

  // Setup Real-time Listeners
  useEffect(() => {
    const channel = supabase.channel('dashboard-updates')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'rides' }, () => {
        queryClient.invalidateQueries({ queryKey: ["active-rides-count"] })
      })
      .on('postgres_changes', { event: '*', schema: 'public', table: 'profiles' }, () => {
        queryClient.invalidateQueries({ queryKey: ["passengers-count"] })
        queryClient.invalidateQueries({ queryKey: ["dashboard-activity"] })
      })
      .on('postgres_changes', { event: '*', schema: 'public', table: 'drivers' }, () => {
        queryClient.invalidateQueries({ queryKey: ["drivers-online-count"] })
      })
      .on('postgres_changes', { event: '*', schema: 'public', table: 'driver_documents' }, () => {
        queryClient.invalidateQueries({ queryKey: ["pending-verifications-count"] })
        queryClient.invalidateQueries({ queryKey: ["dashboard-activity"] })
      })
      .on('postgres_changes', { event: '*', schema: 'public', table: 'safety_incidents' }, () => {
        queryClient.invalidateQueries({ queryKey: ["dashboard-activity"] })
      })
      .on('postgres_changes', { event: '*', schema: 'public', table: 'support_tickets' }, () => {
        queryClient.invalidateQueries({ queryKey: ["dashboard-activity"] })
      })
      .subscribe()

    return () => {
      supabase.removeChannel(channel)
    }
  }, [queryClient])

  const stats = [
    { label: "Active Rides", value: activeRidesCount.toLocaleString(), trend: "+12%", up: true, icon: Car, color: "blue" },
    { label: "Passengers", value: passengersCount.toLocaleString(), trend: "+5%", up: true, icon: Users, color: "emerald" },
    { label: "Drivers Online", value: driversOnlineCount.toLocaleString(), trend: "-2%", up: false, icon: MapIcon, color: "amber" },
    { label: "Approve Queue", value: pendingVerificationsCount.toLocaleString(), trend: "High", up: false, icon: Clock, color: "rose" },
  ]

  return (
    <div className="space-y-6 animate-in transition-all">
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h1 className="text-3xl font-bold tracking-tight text-slate-900">Dashboard Overview</h1>
          <p className="text-slate-500 mt-1">Platform performance and daily operations overview.</p>
        </div>
        <div className="flex items-center gap-3">
          <div className="relative group">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-slate-400 group-focus-within:text-blue-500 transition-colors" />
            <input 
              placeholder="Search everything..." 
              className="pl-10 pr-4 py-2.5 rounded-2xl border border-slate-200 bg-white shadow-sm focus:ring-4 focus:ring-blue-500/10 focus:border-blue-500 outline-none w-64 lg:w-80 transition-all font-medium"
            />
          </div>
          <button className="p-2.5 rounded-2xl border bg-white shadow-sm hover:bg-slate-50 transition-all hover:scale-105 active:scale-95">
            <MoreHorizontal className="h-5 w-5 text-slate-600" />
          </button>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {stats.map((stat, i) => (
          <Card key={i} className="group overflow-hidden border-none shadow-xl hover:shadow-2xl transition-all duration-500 rounded-[2rem] bg-white">
            <CardContent className="p-8 relative">
              <div className={cn(
                "absolute -right-8 -top-8 h-32 w-32 rounded-full opacity-[0.04] transition-transform duration-700 group-hover:scale-150",
                stat.color === 'blue' ? "bg-blue-600" : 
                stat.color === 'emerald' ? "bg-emerald-600" :
                stat.color === 'amber' ? "bg-amber-600" : "bg-rose-600"
              )} />
              <div className="flex items-center justify-between">
                <div className={cn(
                  "p-4 rounded-2xl shadow-inner shadow-black/5 transition-transform duration-300 group-hover:rotate-12",
                  stat.color === 'blue' ? "bg-blue-50 text-blue-600" : 
                  stat.color === 'emerald' ? "bg-emerald-50 text-emerald-600" :
                  stat.color === 'amber' ? "bg-amber-50 text-amber-600" : "bg-rose-50 text-rose-600"
                )}>
                  <stat.icon className="h-7 w-7" />
                </div>
                <Badge className={cn(
                  "flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-bold border-none",
                  stat.up ? "bg-emerald-50 text-emerald-600" : "bg-rose-50 text-rose-600"
                )}>
                  {stat.up ? <ArrowUpRight className="h-3 w-3" /> : <ArrowDownRight className="h-3 w-3" />}
                  {stat.trend}
                </Badge>
              </div>
              <div className="mt-6">
                <p className="text-xs font-bold text-slate-400 uppercase tracking-[0.2em]">{stat.label}</p>
                <p className="text-4xl font-extrabold text-slate-900 mt-2 flex items-baseline gap-1">
                  {stat.value}
                  {stat.up && <span className="h-2 w-2 rounded-full bg-emerald-500 animate-pulse ml-2" />}
                </p>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 pb-12">
        <Card className="lg:col-span-2 border-none shadow-lg rounded-2xl overflow-hidden bg-white">
          <CardHeader className="flex flex-row items-center justify-between px-8 py-6 border-b border-slate-100 bg-slate-50/50">
            <div className="flex flex-col">
              <CardTitle className="text-xl font-bold text-slate-800">Live Ride Map</CardTitle>
              <p className="text-slate-500 text-sm mt-0.5">Real-time view of active rides and locations.</p>
            </div>
            <div className="flex items-center gap-2 rounded-full bg-emerald-50 px-3 py-1 border border-emerald-100">
              <span className="relative flex h-2 w-2">
                <span className="absolute inline-flex h-full w-full animate-ping rounded-full bg-emerald-400 opacity-75"></span>
                <span className="relative inline-flex h-2 w-2 rounded-full bg-emerald-500"></span>
              </span>
              <span className="text-[10px] font-bold text-emerald-600 uppercase tracking-widest leading-none">System Live</span>
            </div>
          </CardHeader>
          <CardContent className="p-0">
            <div className="bg-slate-100 aspect-[16/8] flex items-center justify-center relative overflow-hidden group">
               <div className="absolute inset-0 bg-[url('https://images.unsplash.com/photo-1524661135-423995f22d0b?auto=format&fit=crop&q=80&w=2000')] bg-cover opacity-60" />
               <div className="absolute inset-0 bg-gradient-to-t from-white via-transparent to-white/10" />
               <div className="z-10 text-center px-8 bg-white/90 backdrop-blur-sm p-8 rounded-2xl border border-white shadow-xl">
                 <div className="h-12 w-12 bg-blue-600 rounded-xl flex items-center justify-center mx-auto mb-4 shadow-lg shadow-blue-500/20">
                    <MapIcon className="h-6 w-6 text-white" />
                 </div>
                 <h3 className="font-bold text-slate-900 text-xl mb-1">Fleet Operations</h3>
                 <p className="text-slate-600 max-w-sm text-sm">Monitoring {activeRidesCount} active rides across active locations.</p>
                 <Link href="/monitoring" className="mt-6 px-6 py-2.5 bg-blue-600 text-white rounded-xl font-semibold shadow-md hover:bg-blue-700 transition-all inline-block">
                    View Map
                 </Link>
               </div>
            </div>
          </CardContent>
        </Card>

        <Card className="border-none shadow-lg rounded-2xl bg-white overflow-hidden flex flex-col">
          <CardHeader className="px-8 py-6 border-b border-slate-100">
            <CardTitle className="text-xl font-bold text-slate-800">System Alerts</CardTitle>
            <p className="text-slate-500 text-sm mt-0.5">Actionable updates and status reports.</p>
          </CardHeader>
          <CardContent className="p-0 flex-1 overflow-y-auto custom-scrollbar">
            <div className="divide-y divide-slate-50">
              {activityItems.length > 0 ? activityItems.map((item) => (
                <div key={item.id} className="px-8 py-6 hover:bg-slate-50 transition-all cursor-pointer group flex items-start gap-5">
                  <div className={cn(
                    "h-12 w-12 rounded-2xl flex items-center justify-center shrink-0 transition-transform group-hover:scale-110 shadow-sm",
                    item.type === 'safety' ? "bg-rose-50 text-rose-600 animate-pulse" : 
                    item.type === 'support' ? "bg-blue-50 text-blue-600" :
                    item.type === 'security' ? "bg-rose-50 text-rose-600" : "bg-blue-50 text-blue-600"
                  )}>
                    <item.icon className="h-6 w-6" />
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="text-[10px] font-bold text-slate-400 uppercase tracking-[0.2em] mb-1">
                      {item.type}
                    </p>
                    <p className="text-sm font-bold text-slate-900 truncate tracking-tight">
                      {item.title}
                    </p>
                    <p className="text-xs text-slate-500 mt-1 font-medium italic">{item.subtitle}</p>
                  </div>
                  <span className="text-[10px] font-bold text-slate-400">
                    {item.time ? new Date(item.time).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }) : 'now'}
                  </span>
                </div>
              )) : (
                <div className="px-8 py-12 text-center">
                  <Activity className="h-10 w-10 text-slate-200 mx-auto mb-3" />
                  <p className="text-sm font-bold text-slate-400">No recent activity</p>
                </div>
              )}
            </div>
          </CardContent>
          <div className="p-4 bg-slate-50">
            <button className="w-full py-2.5 text-xs font-bold text-blue-600 hover:bg-blue-50 border border-blue-200 rounded-xl transition-all">
              View Activity Log
            </button>
          </div>
        </Card>
      </div>
    </div>
  )
}
