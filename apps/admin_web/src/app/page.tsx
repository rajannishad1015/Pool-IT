"use client"

import { cn } from "@/lib/utils"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { useQuery, useQueryClient } from "@tanstack/react-query"
import { supabase } from "@/lib/supabase"
import { useEffect, useState } from "react"
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
  MessageSquare,
  BarChart3,
  TrendingUp,
  CreditCard,
  MapPin,
  CheckCircle2,
  Calendar,
  Filter,
  AlertCircle
} from "lucide-react"
import Link from "next/link"
import {
  AreaChart,
  Area,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  BarChart,
  Bar,
  Legend
} from "recharts"

export default function DashboardOverview() {
  const queryClient = useQueryClient()
  const [activeTab, setActiveTab] = useState('overview')
  const [isHoveringChart, setIsHoveringChart] = useState(false)
  const [chartPeriod, setChartPeriod] = useState<'7' | '30'>('7')

  // Weekly/Monthly Performance Data
  const { data: weeklyData = [] } = useQuery({
    queryKey: ["chart-data", chartPeriod],
    queryFn: async () => {
      const days = parseInt(chartPeriod)
      const startDate = new Date()
      startDate.setDate(startDate.getDate() - days)

      // Get rides grouped by day
      const { data: rides } = await supabase
        .from('rides')
        .select('created_at, base_fare')
        .gte('created_at', startDate.toISOString())

      // Get transactions grouped by day
      const { data: transactions } = await supabase
        .from('transactions')
        .select('created_at, amount')
        .gte('created_at', startDate.toISOString())

      // Aggregate by day
      const dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
      const aggregated: Record<string, { rides: number, revenue: number }> = {}

      // Initialize all days
      for (let i = 0; i < days; i++) {
        const date = new Date()
        date.setDate(date.getDate() - (days - 1 - i))
        const key = days === 7
          ? dayNames[date.getDay()]
          : date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' })
        aggregated[key] = { rides: 0, revenue: 0 }
      }

      // Count rides
      rides?.forEach(ride => {
        const date = new Date(ride.created_at || '')
        const key = days === 7
          ? dayNames[date.getDay()]
          : date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' })
        if (aggregated[key]) {
          aggregated[key].rides += 1
          aggregated[key].revenue += ride.base_fare || 0
        }
      })

      // Add transaction amounts to revenue
      transactions?.forEach(t => {
        const date = new Date(t.created_at || '')
        const key = days === 7
          ? dayNames[date.getDay()]
          : date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' })
        if (aggregated[key]) {
          aggregated[key].revenue += t.amount || 0
        }
      })

      return Object.entries(aggregated).map(([name, data]) => ({
        name,
        rides: data.rides,
        revenue: Math.round(data.revenue)
      }))
    }
  })

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
          title: "Document Review",
          subtitle: `${(d.profiles as any)?.full_name || 'Driver'} • ${d.doc_type}`,
          time: d.created_at,
          icon: Clock,
          color: "amber"
        })),
        ...(newUsers || []).map(u => ({
          id: u.id,
          type: "new_user",
          title: "New User Registered",
          subtitle: u.full_name || 'Unnamed User',
          time: u.created_at,
          icon: Users,
          color: "emerald"
        })),
        ...(safetyAlerts || []).map(s => ({
          id: s.id,
          type: "safety",
          title: "Safety Alert: " + s.type,
          subtitle: (s.profiles as any)?.full_name || 'System Alert',
          time: s.created_at,
          icon: ShieldAlert,
          color: "rose"
        })),
        ...(supportTickets || []).map(t => ({
          id: t.id,
          type: "support",
          title: "Support: " + t.subject,
          subtitle: (t.profiles as any)?.full_name || 'New Inquiry',
          time: t.created_at,
          icon: MessageSquare,
          color: "blue"
        }))
      ].sort((a, b) => new Date(b.time || '').getTime() - new Date(a.time || '').getTime()).slice(0, 8); // top 8

      return items
    }
  })

  // Setup Real-time Listeners
  useEffect(() => {
    const channel = supabase.channel('dashboard-updates')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'rides' }, () => {
        queryClient.invalidateQueries({ queryKey: ["active-rides-count"] })
        queryClient.invalidateQueries({ queryKey: ["chart-data"] })
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
      .on('postgres_changes', { event: '*', schema: 'public', table: 'transactions' }, () => {
        queryClient.invalidateQueries({ queryKey: ["chart-data"] })
      })
      .subscribe()

    return () => {
      supabase.removeChannel(channel)
    }
  }, [queryClient])

  const stats = [
    { label: "Active Rides", value: activeRidesCount.toLocaleString(), trend: activeRidesCount > 0 ? "Live" : "No rides", up: activeRidesCount > 0, icon: Car, color: "blue", desc: "Currently in progress" },
    { label: "Total Users", value: passengersCount.toLocaleString(), trend: "All time", up: true, icon: Users, color: "emerald", desc: "Platform users" },
    { label: "Drivers Online", value: driversOnlineCount.toLocaleString(), trend: driversOnlineCount > 0 ? "Active" : "Offline", up: driversOnlineCount > 0, icon: MapIcon, color: "indigo", desc: "Currently available" },
    { label: "Pending Approvals", value: pendingVerificationsCount.toLocaleString(), trend: pendingVerificationsCount > 0 ? "Urgent" : "Clear", up: pendingVerificationsCount === 0, icon: AlertCircle, color: "rose", desc: "Drivers in queue" },
  ]



  return (
    <div className="space-y-8 animate-in slide-in-from-bottom-4 duration-700 ease-out pb-10">
      
      {/* Header Section */}
      <div className="flex flex-col md:flex-row md:items-end justify-between gap-4 bg-white/50 p-6 rounded-3xl border border-slate-100 shadow-sm backdrop-blur-xl">
        <div className="space-y-1">
          <div className="flex items-center gap-2 mb-2">
            <Badge variant="outline" className="bg-blue-50 text-blue-700 border-blue-200">Admin Live</Badge>
            <span className="text-xs font-semibold text-slate-400 uppercase tracking-wider">{new Date().toLocaleDateString('en-US', { weekday: 'long', month: 'short', day: 'numeric'})}</span>
          </div>
          <h1 className="text-4xl font-extrabold tracking-tight text-slate-900">Dashboard Overview</h1>
          <p className="text-slate-500 font-medium">Here's what is happening on your platform today.</p>
        </div>
        <div className="flex items-center gap-3">
          <div className="relative group">
            <Search className="absolute left-4 top-1/2 -translate-y-1/2 h-4 w-4 text-slate-400 group-focus-within:text-indigo-500 transition-colors" />
            <input 
              placeholder="Search users, drivers..." 
              className="pl-11 pr-4 py-3 rounded-2xl border-slate-200 bg-white shadow-sm focus:ring-4 focus:ring-indigo-500/10 focus:border-indigo-500 outline-none w-64 lg:w-80 transition-all font-medium placeholder:text-slate-400 text-sm"
            />
          </div>
          <button className="p-3 rounded-2xl border border-slate-200 bg-white shadow-sm hover:bg-slate-50 transition-all hover:scale-105 active:scale-95 text-slate-600 hover:text-indigo-600">
            <Filter className="h-5 w-5" />
          </button>
        </div>
      </div>

      {/* Tabs */}
      <div className="flex items-center gap-2 px-2 border-b border-slate-200">
        {['overview', 'analytics', 'reports'].map((tab) => (
          <button
            key={tab}
            onClick={() => setActiveTab(tab)}
            className={cn(
              "px-6 py-3 text-sm font-bold capitalize tracking-wide transition-all relative border-b-2",
              activeTab === tab 
                ? "text-indigo-600 border-indigo-600" 
                : "text-slate-500 hover:text-slate-700 border-transparent hover:border-slate-300"
            )}
          >
            {tab}
          </button>
        ))}
      </div>

      {activeTab === 'overview' && (
      <>
      {/* Stats Grid */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
        {stats.map((stat, i) => (
          <Card key={i} className="group relative overflow-hidden border-slate-100 shadow-sm hover:shadow-xl transition-all duration-500 rounded-3xl bg-white hover:-translate-y-1 cursor-pointer">
            <CardContent className="p-6">
              <div className="flex items-center justify-between pointer-events-none z-10 relative">
                <div className={cn(
                  "p-3.5 rounded-2xl transition-transform duration-500 group-hover:scale-110",
                  stat.color === 'blue' ? "bg-blue-50 text-blue-600" : 
                  stat.color === 'emerald' ? "bg-emerald-50 text-emerald-600" :
                  stat.color === 'indigo' ? "bg-indigo-50 text-indigo-600" : "bg-rose-50 text-rose-600"
                )}>
                  <stat.icon className="h-6 w-6" />
                </div>
                <Badge className={cn(
                  "flex items-center gap-1 px-2.5 py-1 rounded-xl text-xs font-bold border-0 shadow-sm",
                  stat.up ? "bg-emerald-100 text-emerald-700" : "bg-rose-100 text-rose-700"
                )}>
                  {stat.up ? <ArrowUpRight className="h-3.5 w-3.5" /> : <ArrowDownRight className="h-3.5 w-3.5" />}
                  {stat.trend}
                </Badge>
              </div>
              <div className="mt-5 pointer-events-none z-10 relative">
                <p className="text-3xl font-black text-slate-900 tracking-tight flex items-center gap-2">
                  {stat.value}
                </p>
                <div className="flex flex-col mt-1">
                  <p className="text-sm font-bold text-slate-600">{stat.label}</p>
                  <p className="text-xs font-medium text-slate-400">{stat.desc}</p>
                </div>
              </div>
              <div className={cn(
                "absolute -right-12 -top-12 h-40 w-40 rounded-full opacity-[0.03] transition-transform duration-700 group-hover:scale-[2] z-0",
                stat.color === 'blue' ? "bg-blue-600" : 
                stat.color === 'emerald' ? "bg-emerald-600" :
                stat.color === 'indigo' ? "bg-indigo-600" : "bg-rose-600"
              )} />
            </CardContent>
          </Card>
        ))}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        {/* Main Charts & Maps Section */}
        <div className="lg:col-span-2 space-y-8">
          
          {/* Interactive Chart */}
          <Card className="border-slate-100 shadow-sm rounded-3xl bg-white overflow-hidden">
            <CardHeader className="px-6 py-5 border-b border-slate-50 flex flex-row items-center justify-between bg-slate-50/50">
              <div>
                <CardTitle className="text-lg font-bold text-slate-800 flex items-center gap-2">
                  <BarChart3 className="h-5 w-5 text-indigo-500" />
                  Weekly Performance
                </CardTitle>
                <p className="text-slate-500 text-sm mt-1 font-medium">Rides vs Revenue over the last 7 days</p>
              </div>
              <div className="flex gap-2">
                <button
                  onClick={() => setChartPeriod('7')}
                  className={cn(
                    "px-3 py-1.5 text-xs font-bold rounded-lg transition-colors",
                    chartPeriod === '7' ? "bg-indigo-50 text-indigo-700" : "text-slate-500 hover:bg-slate-100"
                  )}
                >
                  7 Days
                </button>
                <button
                  onClick={() => setChartPeriod('30')}
                  className={cn(
                    "px-3 py-1.5 text-xs font-bold rounded-lg transition-colors",
                    chartPeriod === '30' ? "bg-indigo-50 text-indigo-700" : "text-slate-500 hover:bg-slate-100"
                  )}
                >
                  30 Days
                </button>
              </div>
            </CardHeader>
            <CardContent className="p-6"
              onMouseEnter={() => setIsHoveringChart(true)}
              onMouseLeave={() => setIsHoveringChart(false)}
            >
              <div className="h-[300px] w-full">
                <ResponsiveContainer width="100%" height="100%">
                  <AreaChart data={weeklyData} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
                    <defs>
                      <linearGradient id="colorRides" x1="0" y1="0" x2="0" y2="1">
                        <stop offset="5%" stopColor="#6366f1" stopOpacity={0.3}/>
                        <stop offset="95%" stopColor="#6366f1" stopOpacity={0}/>
                      </linearGradient>
                      <linearGradient id="colorRev" x1="0" y1="0" x2="0" y2="1">
                        <stop offset="5%" stopColor="#10b981" stopOpacity={0.3}/>
                        <stop offset="95%" stopColor="#10b981" stopOpacity={0}/>
                      </linearGradient>
                    </defs>
                    <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#e2e8f0" />
                    <XAxis dataKey="name" axisLine={false} tickLine={false} tick={{fill: '#64748b', fontSize: 12, fontWeight: 500}} dy={10} />
                    <YAxis axisLine={false} tickLine={false} tick={{fill: '#64748b', fontSize: 12}} />
                    <Tooltip 
                      contentStyle={{ borderRadius: '16px', border: 'none', boxShadow: '0 10px 15px -3px rgb(0 0 0 / 0.1)', fontWeight: 'bold' }}
                      itemStyle={{ fontWeight: 'bold' }}
                    />
                    <Legend iconType="circle" wrapperStyle={{ paddingTop: '20px', fontSize: '12px', fontWeight: 'bold' }} />
                    <Area type="monotone" dataKey="rides" name="Completed Rides" stroke="#6366f1" strokeWidth={3} fillOpacity={1} fill="url(#colorRides)" activeDot={{r: 6, strokeWidth: 0}} />
                    <Area type="monotone" dataKey="revenue" name="Revenue ($)" stroke="#10b981" strokeWidth={3} fillOpacity={1} fill="url(#colorRev)" />
                  </AreaChart>
                </ResponsiveContainer>
              </div>
            </CardContent>
          </Card>

          {/* Map Overview */}
          <Card className="border-slate-100 shadow-sm rounded-3xl bg-white overflow-hidden group">
            <CardHeader className="flex flex-row items-center justify-between px-6 py-5 border-b border-slate-50 bg-slate-50/50">
              <div className="flex flex-col">
                <CardTitle className="text-lg font-bold text-slate-800 flex items-center gap-2">
                  <MapPin className="h-5 w-5 text-blue-500" />
                  Live Ride Map
                </CardTitle>
                <p className="text-slate-500 text-sm mt-1 font-medium">Real-time view of active rides and locations.</p>
              </div>
              <div className="flex items-center gap-2 rounded-full bg-emerald-50 px-3 py-1.5 border border-emerald-100">
                <span className="relative flex h-2.5 w-2.5">
                  <span className="absolute inline-flex h-full w-full animate-ping rounded-full bg-emerald-400 opacity-75"></span>
                  <span className="relative inline-flex h-2.5 w-2.5 rounded-full bg-emerald-500"></span>
                </span>
                <span className="text-xs font-bold text-emerald-700 tracking-wide">Live</span>
              </div>
            </CardHeader>
            <CardContent className="p-0">
              <div className="bg-slate-100 aspect-[16/7] flex items-center justify-center relative overflow-hidden">
                 <div className="absolute inset-0 bg-[url('https://images.unsplash.com/photo-1524661135-423995f22d0b?auto=format&fit=crop&q=80&w=2000')] bg-cover opacity-[0.65] transition-transform duration-1000 group-hover:scale-105" />
                 <div className="absolute inset-0 bg-gradient-to-t from-slate-900/60 via-slate-900/20 to-transparent" />
                 <div className="z-10 absolute bottom-6 left-6 right-6 flex items-end justify-between">
                    <div>
                      <h3 className="font-bold text-white text-2xl drop-shadow-md">Active Region</h3>
                      <p className="text-slate-100 font-medium dropshadow-sm mt-1 flex items-center gap-2">
                         <Activity className="h-4 w-4" /> Monitoring {activeRidesCount} active rides
                      </p>
                    </div>
                   <Link href="/monitoring" className="px-6 py-3 bg-white/20 hover:bg-white/30 backdrop-blur-md text-white rounded-xl font-bold shadow-lg transition-all border border-white/30 flex items-center gap-2">
                      Open Map <ArrowUpRight className="h-4 w-4" />
                   </Link>
                 </div>
              </div>
            </CardContent>
          </Card>
        </div>

        {/* Sidebar Activity & Actions */}
        <div className="space-y-8">
          
          {/* Quick Actions */}
          <Card className="border-slate-100 shadow-sm rounded-3xl bg-white overflow-hidden">
             <CardHeader className="px-6 py-5 border-b border-slate-50">
               <CardTitle className="text-lg font-bold text-slate-800">Quick Actions</CardTitle>
             </CardHeader>
             <CardContent className="p-4 grid grid-cols-2 gap-3">
                <Link href="/verification" className="flex flex-col items-center justify-center p-4 rounded-2xl bg-amber-50 hover:bg-amber-100 text-amber-700 transition-colors gap-2 text-center group">
                  <Clock className="h-6 w-6 group-hover:scale-110 transition-transform" />
                  <span className="text-xs font-bold">Review Docs</span>
                </Link>
                <Link href="/support" className="flex flex-col items-center justify-center p-4 rounded-2xl bg-blue-50 hover:bg-blue-100 text-blue-700 transition-colors gap-2 text-center group">
                  <MessageSquare className="h-6 w-6 group-hover:scale-110 transition-transform" />
                  <span className="text-xs font-bold">Support Chat</span>
                </Link>
                <Link href="/safety" className="flex flex-col items-center justify-center p-4 rounded-2xl bg-rose-50 hover:bg-rose-100 text-rose-700 transition-colors gap-2 text-center group">
                  <ShieldAlert className="h-6 w-6 group-hover:scale-110 transition-transform" />
                  <span className="text-xs font-bold">Safety Center</span>
                </Link>
                <Link href="/finance" className="flex flex-col items-center justify-center p-4 rounded-2xl bg-emerald-50 hover:bg-emerald-100 text-emerald-700 transition-colors gap-2 text-center group">
                  <CreditCard className="h-6 w-6 group-hover:scale-110 transition-transform" />
                  <span className="text-xs font-bold">Finance</span>
                </Link>
             </CardContent>
          </Card>

          {/* Activity Feed */}
          <Card className="border-slate-100 shadow-sm rounded-3xl bg-white overflow-hidden flex flex-col h-[500px]">
            <CardHeader className="px-6 py-5 border-b border-slate-50 flex flex-row items-center justify-between shrink-0">
              <div>
                <CardTitle className="text-lg font-bold text-slate-800">System Logs</CardTitle>
                <p className="text-slate-500 text-xs mt-0.5 font-medium">Real-time platform activity</p>
              </div>
              <button className="text-slate-400 hover:text-indigo-600 transition-colors">
                 <MoreHorizontal className="h-5 w-5" />
              </button>
            </CardHeader>
            <CardContent className="p-0 flex-1 overflow-y-auto custom-scrollbar relative">
              <div className="absolute top-0 w-full h-4 bg-gradient-to-b from-white to-transparent z-10 pointer-events-none" />
              <div className="divide-y divide-slate-50 px-2 py-2">
                {activityItems.length > 0 ? activityItems.map((item) => (
                  <div key={item.id} className="p-4 hover:bg-slate-50 rounded-2xl transition-all cursor-pointer group flex items-start gap-4 mx-2 my-1 border border-transparent hover:border-slate-100">
                    <div className={cn(
                      "h-10 w-10 rounded-full flex items-center justify-center shrink-0 transition-transform group-hover:scale-110 shadow-sm",
                      item.color === 'rose' ? "bg-rose-100 text-rose-600 ring-4 ring-rose-50" : 
                      item.color === 'blue' ? "bg-blue-100 text-blue-600 ring-4 ring-blue-50" :
                      item.color === 'emerald' ? "bg-emerald-100 text-emerald-600 ring-4 ring-emerald-50" : "bg-amber-100 text-amber-600 ring-4 ring-amber-50"
                    )}>
                      <item.icon className="h-5 w-5" />
                    </div>
                    <div className="flex-1 min-w-0 pt-0.5">
                       <div className="flex items-center justify-between gap-2 mb-1">
                          <p className="text-sm font-bold text-slate-900 truncate">
                            {item.title}
                          </p>
                          <span className="text-[10px] font-bold text-slate-400 whitespace-nowrap bg-slate-100 px-2 py-0.5 rounded-md">
                            {item.time ? new Date(item.time).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }) : 'now'}
                          </span>
                       </div>
                      <p className="text-xs text-slate-500 font-medium truncate">{item.subtitle}</p>
                    </div>
                  </div>
                )) : (
                  <div className="px-8 py-16 text-center h-full flex flex-col items-center justify-center">
                    <div className="h-16 w-16 bg-slate-50 rounded-full flex items-center justify-center mb-4">
                      <Activity className="h-8 w-8 text-slate-300" />
                    </div>
                    <p className="text-sm font-bold text-slate-700">All caught up</p>
                    <p className="text-xs text-slate-500 font-medium mt-1">No recent activity to show.</p>
                  </div>
                )}
              </div>
              <div className="absolute bottom-0 w-full h-6 bg-gradient-to-t from-white to-transparent z-10 pointer-events-none" />
            </CardContent>
            <div className="p-4 bg-white border-t border-slate-50 shrink-0">
              <button className="w-full py-3 text-sm font-bold text-indigo-600 hover:text-white hover:bg-indigo-600 bg-indigo-50 rounded-xl transition-all flex items-center justify-center gap-2">
                View Full Logs <ArrowUpRight className="h-4 w-4" />
              </button>
            </div>
          </Card>
        </div>
      </div>
      </>
      )}

      {activeTab === 'analytics' && (
        <AnalyticsTab />
      )}

      {activeTab === 'reports' && (
        <ReportsTab />
      )}

    </div>
  )
}

// Analytics Tab Component
function AnalyticsTab() {
  // Total Revenue
  const { data: totalRevenue = 0 } = useQuery({
    queryKey: ["analytics-revenue"],
    queryFn: async () => {
      const { data } = await supabase.from('transactions').select('amount')
      return data?.reduce((sum, t) => sum + (t.amount || 0), 0) || 0
    }
  })

  // Completed Rides
  const { data: completedRides = 0 } = useQuery({
    queryKey: ["analytics-completed-rides"],
    queryFn: async () => {
      const { count } = await supabase.from('rides').select('*', { count: 'exact', head: true }).eq('status', 'completed')
      return count || 0
    }
  })

  // Average Fare
  const { data: avgFare = 0 } = useQuery({
    queryKey: ["analytics-avg-fare"],
    queryFn: async () => {
      const { data } = await supabase.from('rides').select('base_fare')
      if (!data || data.length === 0) return 0
      const total = data.reduce((sum, r) => sum + (r.base_fare || 0), 0)
      return Math.round(total / data.length)
    }
  })

  // Driver Utilization (online drivers / total drivers)
  const { data: driverStats = { total: 0, online: 0 } } = useQuery({
    queryKey: ["analytics-driver-stats"],
    queryFn: async () => {
      const { count: total } = await supabase.from('drivers').select('*', { count: 'exact', head: true })
      const { count: online } = await supabase.from('drivers').select('*', { count: 'exact', head: true }).eq('is_online', true)
      return { total: total || 0, online: online || 0 }
    }
  })

  // Top Destinations
  const { data: topDestinations = [] } = useQuery({
    queryKey: ["analytics-top-destinations"],
    queryFn: async () => {
      const { data } = await supabase.from('rides').select('destination_name')
      if (!data) return []

      const counts: Record<string, number> = {}
      data.forEach(r => {
        const dest = r.destination_name || 'Unknown'
        counts[dest] = (counts[dest] || 0) + 1
      })

      return Object.entries(counts)
        .sort((a, b) => b[1] - a[1])
        .slice(0, 5)
        .map(([name, count]) => ({ name, count }))
    }
  })

  // Bookings by Status
  const { data: bookingStats = [] } = useQuery({
    queryKey: ["analytics-booking-stats"],
    queryFn: async () => {
      const { data } = await supabase.from('bookings').select('status')
      if (!data) return []

      const counts: Record<string, number> = {}
      data.forEach(b => {
        const status = b.status || 'unknown'
        counts[status] = (counts[status] || 0) + 1
      })

      return Object.entries(counts).map(([status, count]) => ({
        status,
        count,
        fill: status === 'confirmed' ? '#10b981' : status === 'pending' ? '#f59e0b' : status === 'cancelled' ? '#ef4444' : '#94a3b8'
      }))
    }
  })

  const utilization = driverStats.total > 0 ? Math.round((driverStats.online / driverStats.total) * 100) : 0

  return (
    <div className="space-y-8 animate-in slide-in-from-bottom-4 duration-500">
      {/* Key Metrics */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
        <Card className="border-slate-100 shadow-sm rounded-3xl bg-white">
          <CardContent className="p-6">
            <div className="flex items-center gap-4">
              <div className="p-3 rounded-2xl bg-emerald-50 text-emerald-600">
                <CreditCard className="h-6 w-6" />
              </div>
              <div>
                <p className="text-xs font-bold text-slate-400 uppercase tracking-wider">Total Revenue</p>
                <p className="text-2xl font-black text-slate-900">₹{totalRevenue.toLocaleString()}</p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card className="border-slate-100 shadow-sm rounded-3xl bg-white">
          <CardContent className="p-6">
            <div className="flex items-center gap-4">
              <div className="p-3 rounded-2xl bg-blue-50 text-blue-600">
                <CheckCircle2 className="h-6 w-6" />
              </div>
              <div>
                <p className="text-xs font-bold text-slate-400 uppercase tracking-wider">Completed Rides</p>
                <p className="text-2xl font-black text-slate-900">{completedRides.toLocaleString()}</p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card className="border-slate-100 shadow-sm rounded-3xl bg-white">
          <CardContent className="p-6">
            <div className="flex items-center gap-4">
              <div className="p-3 rounded-2xl bg-amber-50 text-amber-600">
                <TrendingUp className="h-6 w-6" />
              </div>
              <div>
                <p className="text-xs font-bold text-slate-400 uppercase tracking-wider">Avg Fare</p>
                <p className="text-2xl font-black text-slate-900">₹{avgFare.toLocaleString()}</p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card className="border-slate-100 shadow-sm rounded-3xl bg-white">
          <CardContent className="p-6">
            <div className="flex items-center gap-4">
              <div className="p-3 rounded-2xl bg-indigo-50 text-indigo-600">
                <Activity className="h-6 w-6" />
              </div>
              <div>
                <p className="text-xs font-bold text-slate-400 uppercase tracking-wider">Driver Utilization</p>
                <p className="text-2xl font-black text-slate-900">{utilization}%</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
        {/* Top Destinations */}
        <Card className="border-slate-100 shadow-sm rounded-3xl bg-white">
          <CardHeader className="px-6 py-5 border-b border-slate-50">
            <CardTitle className="text-lg font-bold text-slate-800 flex items-center gap-2">
              <MapPin className="h-5 w-5 text-blue-500" />
              Top Destinations
            </CardTitle>
          </CardHeader>
          <CardContent className="p-6">
            {topDestinations.length > 0 ? (
              <div className="space-y-4">
                {topDestinations.map((dest, i) => (
                  <div key={dest.name} className="flex items-center gap-4">
                    <div className="h-8 w-8 rounded-xl bg-slate-100 flex items-center justify-center font-bold text-slate-600 text-sm">
                      #{i + 1}
                    </div>
                    <div className="flex-1">
                      <p className="text-sm font-semibold text-slate-900 truncate">{dest.name}</p>
                      <div className="mt-1 h-2 bg-slate-100 rounded-full overflow-hidden">
                        <div
                          className="h-full bg-blue-500 rounded-full"
                          style={{ width: `${(dest.count / (topDestinations[0]?.count || 1)) * 100}%` }}
                        />
                      </div>
                    </div>
                    <span className="text-sm font-bold text-slate-500">{dest.count} rides</span>
                  </div>
                ))}
              </div>
            ) : (
              <div className="py-12 text-center">
                <MapPin className="h-10 w-10 text-slate-200 mx-auto mb-3" />
                <p className="text-sm font-semibold text-slate-400">No ride data available yet</p>
              </div>
            )}
          </CardContent>
        </Card>

        {/* Booking Status Distribution */}
        <Card className="border-slate-100 shadow-sm rounded-3xl bg-white">
          <CardHeader className="px-6 py-5 border-b border-slate-50">
            <CardTitle className="text-lg font-bold text-slate-800 flex items-center gap-2">
              <BarChart3 className="h-5 w-5 text-indigo-500" />
              Booking Status Distribution
            </CardTitle>
          </CardHeader>
          <CardContent className="p-6">
            {bookingStats.length > 0 ? (
              <div className="h-[250px]">
                <ResponsiveContainer width="100%" height="100%">
                  <BarChart data={bookingStats} layout="vertical" margin={{ left: 20, right: 20 }}>
                    <CartesianGrid strokeDasharray="3 3" horizontal={true} vertical={false} stroke="#e2e8f0" />
                    <XAxis type="number" axisLine={false} tickLine={false} tick={{ fill: '#64748b', fontSize: 12 }} />
                    <YAxis type="category" dataKey="status" axisLine={false} tickLine={false} tick={{ fill: '#64748b', fontSize: 12, fontWeight: 600 }} width={80} />
                    <Tooltip contentStyle={{ borderRadius: '12px', border: 'none', boxShadow: '0 10px 15px -3px rgb(0 0 0 / 0.1)' }} />
                    <Bar dataKey="count" radius={[0, 8, 8, 0]} />
                  </BarChart>
                </ResponsiveContainer>
              </div>
            ) : (
              <div className="py-12 text-center">
                <BarChart3 className="h-10 w-10 text-slate-200 mx-auto mb-3" />
                <p className="text-sm font-semibold text-slate-400">No booking data available yet</p>
              </div>
            )}
          </CardContent>
        </Card>
      </div>
    </div>
  )
}

// Reports Tab Component
function ReportsTab() {
  // Monthly Summary Data
  const { data: monthlySummary, isLoading } = useQuery({
    queryKey: ["reports-monthly-summary"],
    queryFn: async () => {
      const startOfMonth = new Date()
      startOfMonth.setDate(1)
      startOfMonth.setHours(0, 0, 0, 0)

      const [ridesRes, transactionsRes, usersRes, incidentsRes] = await Promise.all([
        supabase.from('rides').select('*', { count: 'exact', head: true }).gte('created_at', startOfMonth.toISOString()),
        supabase.from('transactions').select('amount').gte('created_at', startOfMonth.toISOString()),
        supabase.from('profiles').select('*', { count: 'exact', head: true }).gte('created_at', startOfMonth.toISOString()),
        supabase.from('safety_incidents').select('*', { count: 'exact', head: true }).gte('created_at', startOfMonth.toISOString())
      ])

      const totalRevenue = transactionsRes.data?.reduce((sum, t) => sum + (t.amount || 0), 0) || 0

      return {
        totalRides: ridesRes.count || 0,
        totalRevenue,
        newUsers: usersRes.count || 0,
        incidents: incidentsRes.count || 0,
        month: startOfMonth.toLocaleDateString('en-US', { month: 'long', year: 'numeric' })
      }
    }
  })

  // Export handlers
  const exportToCSV = async (type: 'rides' | 'transactions' | 'users') => {
    let data: any[] = []
    let filename = ''
    let headers: string[] = []

    if (type === 'rides') {
      const response = await supabase.from('rides').select('id, origin_name, destination_name, base_fare, seats_total, seats_available, status, departure_time, created_at')
      data = response.data || []
      headers = ['ID', 'Origin', 'Destination', 'Base Fare', 'Total Seats', 'Available Seats', 'Status', 'Departure Time', 'Created At']
      filename = 'rides_report.csv'
    } else if (type === 'transactions') {
      const response = await supabase.from('transactions').select('id, amount, type, description, created_at')
      data = response.data || []
      headers = ['ID', 'Amount', 'Type', 'Description', 'Created At']
      filename = 'transactions_report.csv'
    } else if (type === 'users') {
      const response = await supabase.from('profiles').select('id, full_name, phone_number, is_verified, created_at')
      data = response.data || []
      headers = ['ID', 'Full Name', 'Phone Number', 'Verified', 'Created At']
      filename = 'users_report.csv'
    }

    if (data.length > 0) {
      const csvContent = [
        headers.join(','),
        ...data.map(row => Object.values(row).map(v => `"${v || ''}"`).join(','))
      ].join('\n')

      const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' })
      const url = URL.createObjectURL(blob)
      const link = document.createElement('a')
      link.href = url
      link.download = filename
      link.click()
      URL.revokeObjectURL(url)
    }
  }

  return (
    <div className="space-y-8 animate-in slide-in-from-bottom-4 duration-500">
      {/* Monthly Summary Card */}
      <Card className="border-slate-100 shadow-lg rounded-3xl bg-gradient-to-br from-slate-900 to-slate-800 text-white overflow-hidden">
        <CardHeader className="px-8 py-6">
          <div className="flex items-center justify-between">
            <div>
              <CardTitle className="text-2xl font-bold tracking-tight">Monthly Summary</CardTitle>
              <p className="text-slate-400 mt-1">{monthlySummary?.month || 'Loading...'}</p>
            </div>
            <Badge className="bg-white/10 text-white border-none px-4 py-2 text-xs font-bold">
              <Calendar className="h-4 w-4 mr-2" />
              Current Month
            </Badge>
          </div>
        </CardHeader>
        <CardContent className="px-8 pb-8">
          {isLoading ? (
            <div className="text-center py-8 text-slate-400">Loading summary...</div>
          ) : (
            <div className="grid grid-cols-2 md:grid-cols-4 gap-6">
              <div className="p-5 bg-white/5 rounded-2xl border border-white/10">
                <p className="text-xs font-bold text-slate-400 uppercase tracking-wider">Total Rides</p>
                <p className="text-3xl font-black mt-2">{monthlySummary?.totalRides.toLocaleString()}</p>
              </div>
              <div className="p-5 bg-white/5 rounded-2xl border border-white/10">
                <p className="text-xs font-bold text-slate-400 uppercase tracking-wider">Revenue</p>
                <p className="text-3xl font-black mt-2 text-emerald-400">₹{monthlySummary?.totalRevenue.toLocaleString()}</p>
              </div>
              <div className="p-5 bg-white/5 rounded-2xl border border-white/10">
                <p className="text-xs font-bold text-slate-400 uppercase tracking-wider">New Users</p>
                <p className="text-3xl font-black mt-2">{monthlySummary?.newUsers.toLocaleString()}</p>
              </div>
              <div className="p-5 bg-white/5 rounded-2xl border border-white/10">
                <p className="text-xs font-bold text-slate-400 uppercase tracking-wider">Incidents</p>
                <p className="text-3xl font-black mt-2 text-amber-400">{monthlySummary?.incidents}</p>
              </div>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Export Reports */}
      <div>
        <h2 className="text-xl font-bold text-slate-800 mb-6">Export Reports</h2>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          <Card className="border-slate-100 shadow-sm rounded-3xl bg-white hover:shadow-lg transition-all cursor-pointer group" onClick={() => exportToCSV('rides')}>
            <CardContent className="p-6">
              <div className="flex items-center gap-4">
                <div className="p-3 rounded-2xl bg-blue-50 text-blue-600 group-hover:bg-blue-600 group-hover:text-white transition-colors">
                  <Car className="h-6 w-6" />
                </div>
                <div className="flex-1">
                  <p className="font-bold text-slate-900">Rides Report</p>
                  <p className="text-xs text-slate-500">Export all rides data to CSV</p>
                </div>
                <ArrowUpRight className="h-5 w-5 text-slate-300 group-hover:text-blue-600 transition-colors" />
              </div>
            </CardContent>
          </Card>

          <Card className="border-slate-100 shadow-sm rounded-3xl bg-white hover:shadow-lg transition-all cursor-pointer group" onClick={() => exportToCSV('transactions')}>
            <CardContent className="p-6">
              <div className="flex items-center gap-4">
                <div className="p-3 rounded-2xl bg-emerald-50 text-emerald-600 group-hover:bg-emerald-600 group-hover:text-white transition-colors">
                  <CreditCard className="h-6 w-6" />
                </div>
                <div className="flex-1">
                  <p className="font-bold text-slate-900">Transactions Report</p>
                  <p className="text-xs text-slate-500">Export all transactions to CSV</p>
                </div>
                <ArrowUpRight className="h-5 w-5 text-slate-300 group-hover:text-emerald-600 transition-colors" />
              </div>
            </CardContent>
          </Card>

          <Card className="border-slate-100 shadow-sm rounded-3xl bg-white hover:shadow-lg transition-all cursor-pointer group" onClick={() => exportToCSV('users')}>
            <CardContent className="p-6">
              <div className="flex items-center gap-4">
                <div className="p-3 rounded-2xl bg-indigo-50 text-indigo-600 group-hover:bg-indigo-600 group-hover:text-white transition-colors">
                  <Users className="h-6 w-6" />
                </div>
                <div className="flex-1">
                  <p className="font-bold text-slate-900">Users Report</p>
                  <p className="text-xs text-slate-500">Export all users data to CSV</p>
                </div>
                <ArrowUpRight className="h-5 w-5 text-slate-300 group-hover:text-indigo-600 transition-colors" />
              </div>
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  )
}
