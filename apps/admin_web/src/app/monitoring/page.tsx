"use client"

import { useQuery, useQueryClient } from "@tanstack/react-query"
import { supabase } from "@/lib/supabase"
import { cn } from "@/lib/utils"
import { useEffect, useState, useMemo } from "react"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import {
  Map as MapIcon,
  Car,
  Users,
  MapPin,
  Clock,
  Navigation,
  Search,
  Filter,
  ArrowRight,
  ShieldCheck,
  AlertCircle,
  TrendingUp,
  Gauge
} from "lucide-react"
import dynamic from "next/dynamic"

// Dynamically import MapComponent with SSR disabled
const MapComponent = dynamic(() => import("@/components/ui/map-component"), {
  ssr: false,
  loading: () => <div className="h-[600px] w-full bg-slate-100 animate-pulse rounded-[2.5rem]" />
})

export default function LiveMonitoringPage() {
  const queryClient = useQueryClient()
  const [filter, setFilter] = useState("all")
  const [selectedRide, setSelectedRide] = useState<any>(null)
  const [searchQuery, setSearchQuery] = useState("")

  const { data: activeRides = [], isLoading } = useQuery({
    queryKey: ["active-monitoring-rides"],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("rides")
        .select(`
          *,
          profiles:driver_id (
            full_name,
            last_lat_lng
          )
        `)
        .eq('status', 'active')
        .order('departure_time', { ascending: false })
      if (error) throw error
      return data || []
    }
  })

  // Get all rides for metrics calculation
  const { data: allRides = [] } = useQuery({
    queryKey: ["all-rides-metrics"],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("rides")
        .select('id, seats_total, seats_available, status, base_fare')
      if (error) throw error
      return data || []
    }
  })

  // Get unique active cities/origins
  const { data: activeCities = 0 } = useQuery({
    queryKey: ["active-cities"],
    queryFn: async () => {
      const { data } = await supabase
        .from("rides")
        .select('origin_name')
        .eq('status', 'active')

      if (!data) return 0
      const uniqueCities = new Set(data.map(r => r.origin_name?.split(',')[0]?.trim()))
      return uniqueCities.size
    }
  })

  // Calculate real metrics
  const metrics = useMemo(() => {
    const completedRides = allRides.filter(r => r.status === 'completed')
    const activeRidesList = allRides.filter(r => r.status === 'active')

    // Seat utilization (booked seats / total seats)
    const totalSeats = allRides.reduce((sum, r) => sum + (r.seats_total || 0), 0)
    const bookedSeats = allRides.reduce((sum, r) => sum + ((r.seats_total || 0) - (r.seats_available || 0)), 0)
    const seatUtilization = totalSeats > 0 ? Math.round((bookedSeats / totalSeats) * 100) : 0

    // Average fare
    const avgFare = completedRides.length > 0
      ? Math.round(completedRides.reduce((sum, r) => sum + (r.base_fare || 0), 0) / completedRides.length)
      : 0

    // Active ride count
    const activeCount = activeRidesList.length

    return {
      seatUtilization,
      avgFare,
      activeCount
    }
  }, [allRides])

  // Search filter
  const filteredRides = useMemo(() => {
    if (!searchQuery) return activeRides
    const query = searchQuery.toLowerCase()
    return activeRides.filter(ride =>
      (ride.profiles as any)?.full_name?.toLowerCase().includes(query) ||
      ride.id.toLowerCase().includes(query) ||
      ride.origin_name?.toLowerCase().includes(query) ||
      ride.destination_name?.toLowerCase().includes(query)
    )
  }, [activeRides, searchQuery])

  // Real-time synchronization
  useEffect(() => {
    const channel = supabase.channel('monitoring-updates')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'rides', filter: "status=eq.active" }, () => {
        queryClient.invalidateQueries({ queryKey: ["active-monitoring-rides"] })
        queryClient.invalidateQueries({ queryKey: ["all-rides-metrics"] })
        queryClient.invalidateQueries({ queryKey: ["active-cities"] })
      })
      .subscribe()

    return () => {
      supabase.removeChannel(channel)
    }
  }, [queryClient])

  return (
    <div className="space-y-6 animate-in transition-all">
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h1 className="text-3xl font-bold tracking-tight text-slate-900">Live Ride Monitoring</h1>
          <p className="text-slate-500 mt-1">Real-time oversight of all current platform movement.</p>
        </div>
        <div className="flex items-center gap-3">
           <div className="flex items-center gap-2 px-3 py-1.5 rounded-full bg-emerald-50 border border-emerald-100">
              <div className="h-1.5 w-1.5 rounded-full bg-emerald-500 animate-pulse" />
              <span className="text-[10px] font-bold text-emerald-600 uppercase tracking-widest">{activeRides.length} Active Rides</span>
           </div>
           <Button className="rounded-xl bg-blue-600 hover:bg-blue-700 shadow-lg shadow-blue-500/20 px-6 font-bold text-xs uppercase tracking-wider">
              Optimize Fleet
           </Button>
        </div>
      </div>

      <div className="grid grid-cols-1 xl:grid-cols-4 gap-6">
        <div className="xl:col-span-3 space-y-6">
           {/* Real-time Map Integration */}
           <Card className="border-none shadow-xl rounded-[2.5rem] overflow-hidden bg-white h-[600px] p-0 relative group">
              <MapComponent 
                rides={activeRides.map((r: any) => {
                  const [lat, lng] = (r.profiles?.last_lat_lng as string || '').split(',').map(Number) || [0, 0]
                  return {
                    id: r.id,
                    driverName: r.profiles?.full_name || undefined,
                    lat: isNaN(lat) ? 0 : lat,
                    lng: isNaN(lng) ? 0 : lng,
                    status: 'Active Now'
                  }
                }).filter((r: any) => r.lat !== 0 && r.lng !== 0)} 
              />

              <div className="absolute bottom-8 left-8 right-8 flex items-center justify-between">
                <div className="flex items-center gap-4 bg-white/90 backdrop-blur-md p-4 rounded-3xl border border-white shadow-2xl">
                   <div className="flex items-center gap-2 px-3 py-1.5 rounded-2xl bg-slate-900 text-white text-[10px] font-bold uppercase tracking-wider">
                      <Navigation className="h-3 w-3" /> {activeCities} {activeCities === 1 ? 'City' : 'Cities'} Active
                   </div>
                   <div className="flex items-center gap-2 px-3 py-1.5 rounded-2xl bg-blue-50 text-blue-600 text-[10px] font-bold uppercase tracking-wider border border-blue-100">
                      <AlertCircle className="h-3 w-3" /> 0 Deviations
                   </div>
                </div>
                
                <div className="flex gap-2">
                   <Button variant="outline" className="h-12 w-12 rounded-2xl bg-white/90 backdrop-blur-md border-white shadow-xl hover:bg-white">
                      <Search className="h-5 w-5 text-slate-600" />
                   </Button>
                   <Button variant="outline" className="h-12 w-12 rounded-2xl bg-white/90 backdrop-blur-md border-white shadow-xl hover:bg-white text-blue-600">
                      <Navigation className="h-5 w-5" />
                   </Button>
                </div>
              </div>
           </Card>

           <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              <Card className="p-6 border-none shadow-lg rounded-[2rem] bg-white text-center">
                 <p className="text-[10px] font-bold text-slate-400 uppercase tracking-widest mb-1">Active Rides</p>
                 <p className="text-3xl font-extrabold text-blue-600">{metrics.activeCount} <span className="text-sm font-bold text-slate-400">rides</span></p>
              </Card>
              <Card className="p-6 border-none shadow-lg rounded-[2rem] bg-white text-center">
                 <p className="text-[10px] font-bold text-slate-400 uppercase tracking-widest mb-1">Seat Utilization</p>
                 <p className="text-3xl font-extrabold text-emerald-600">{metrics.seatUtilization} <span className="text-sm font-bold text-slate-400">%</span></p>
              </Card>
              <Card className="p-6 border-none shadow-lg rounded-[2rem] bg-white text-center">
                 <p className="text-[10px] font-bold text-slate-400 uppercase tracking-widest mb-1">Avg Fare</p>
                 <p className="text-3xl font-extrabold text-slate-900">₹{metrics.avgFare} <span className="text-sm font-bold text-slate-400"></span></p>
              </Card>
           </div>
        </div>

        <div className="space-y-6">
           <div className="flex items-center justify-between">
              <h2 className="text-lg font-bold text-slate-800">Current Fleet</h2>
              <Badge variant="outline" className="rounded-full bg-slate-100 border-none text-[10px] font-bold uppercase px-3 py-1 text-slate-500">
                 {activeRides.length} Total
              </Badge>
           </div>

           <div className="relative group">
              <Search className="absolute left-4 top-1/2 -translate-y-1/2 h-4 w-4 text-slate-400 group-focus-within:text-blue-500 transition-colors" />
              <input
                placeholder="Search driver or ride ID..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="w-full pl-11 pr-4 py-3 rounded-2xl border border-slate-100 bg-white shadow-sm focus:ring-4 focus:ring-blue-500/10 focus:border-blue-500 outline-none transition-all text-sm font-medium"
              />
           </div>

           <div className="space-y-4 max-h-[700px] overflow-y-auto pr-2 custom-scrollbar">
              {filteredRides.map((ride) => (
                <Card key={ride.id} className="p-5 border border-slate-50 shadow-md hover:shadow-xl transition-all cursor-pointer rounded-3xl bg-white group border-l-4 border-l-blue-600">
                   <div className="flex items-start justify-between mb-4">
                      <div className="flex items-center gap-3">
                         <div className="h-10 w-10 rounded-xl bg-slate-100 flex items-center justify-center font-bold text-slate-600 group-hover:bg-blue-50 group-hover:text-blue-600 transition-colors">
                            {(ride.profiles as any)?.full_name?.substring(0, 2).toUpperCase()}
                         </div>
                         <div>
                            <p className="text-sm font-bold text-slate-900">{(ride.profiles as any)?.full_name}</p>
                            <p className="text-[10px] text-slate-500 font-medium">#{ride.id.substring(0, 8)}</p>
                         </div>
                      </div>
                      <Badge className="bg-emerald-50 text-emerald-600 border-none text-[9px] font-bold uppercase tracking-wider px-2 py-0.5">
                         On Track
                      </Badge>
                   </div>
                   
                   <div className="space-y-3 relative before:absolute before:left-[7px] before:top-2 before:bottom-2 before:w-[2px] before:bg-slate-100">
                      <div className="flex items-center gap-3 relative pl-6">
                         <div className="absolute left-0 top-1/2 -translate-y-1/2 h-2 w-2 rounded-full border-2 border-slate-300 bg-white shadow-sm" />
                         <p className="text-xs font-semibold text-slate-600 truncate">{ride.origin_name}</p>
                      </div>
                      <div className="flex items-center gap-3 relative pl-6">
                         <div className="absolute left-0 top-1/2 -translate-y-1/2 h-2 w-2 rounded-full border-2 border-blue-600 bg-white shadow-sm" />
                         <p className="text-xs font-semibold text-slate-900 truncate">{ride.destination_name}</p>
                      </div>
                   </div>

                   <div className="flex items-center justify-between mt-5 pt-4 border-t border-slate-50">
                      <div className="flex items-center gap-2">
                         <Users className="h-3 w-3 text-slate-400" />
                         <span className="text-[10px] font-bold text-slate-600">{ride.seats_total - ride.seats_available}/{ride.seats_total} Booked</span>
                      </div>
                      <Button variant="ghost" className="h-8 px-3 rounded-lg text-[10px] font-bold uppercase tracking-wider text-blue-600 hover:bg-blue-50">
                         Details <ArrowRight className="h-3 w-3 ml-1" />
                      </Button>
                   </div>
                </Card>
              ))}

              {filteredRides.length === 0 && !isLoading && (
                <div className="text-center py-20 bg-slate-50/50 rounded-[2.5rem] border border-dashed border-slate-200">
                   <Navigation className="h-10 w-10 text-slate-300 mx-auto mb-3" />
                   <p className="text-sm font-bold text-slate-400">No active tracking</p>
                </div>
              )}
           </div>
        </div>
      </div>
    </div>
  )
}
