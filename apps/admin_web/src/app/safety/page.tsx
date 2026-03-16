"use client"

import { useQuery, useQueryClient, useMutation } from "@tanstack/react-query"
import { supabase } from "@/lib/supabase"
import { cn } from "@/lib/utils"
import { useEffect, useState } from "react"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { 
  ShieldAlert, 
  MapPin, 
  Clock, 
  Phone, 
  ShieldCheck,
  AlertTriangle,
  ChevronRight,
  User,
  Activity
} from "lucide-react"

function timeAgo(date: string | null) {
  if (!date) return "Just now"
  const seconds = Math.floor((new Date().getTime() - new Date(date).getTime()) / 1000)
  if (seconds < 60) return "Just now"
  let interval = seconds / 31536000
  if (interval > 1) return Math.floor(interval) + "y ago"
  interval = seconds / 2592000
  if (interval > 1) return Math.floor(interval) + "mo ago"
  interval = seconds / 86400
  if (interval > 1) return Math.floor(interval) + "d ago"
  interval = seconds / 3600
  if (interval > 1) return Math.floor(interval) + "h ago"
  interval = seconds / 60
  if (interval > 1) return Math.floor(interval) + "m ago"
  return Math.floor(seconds) + "s ago"
}

export default function SafetyPage() {
  const queryClient = useQueryClient()

  const { data: incidents = [], isLoading } = useQuery({
    queryKey: ["incidents"],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("safety_incidents")
        .select(`
          *,
          profiles:user_id (
            full_name
          )
        `)
        .order('created_at', { ascending: false })
      if (error) throw error
      return data || []
    }
  })

  const updateStatusMutation = useMutation({
    mutationFn: async ({ id, status }: { id: string, status: 'investigating' | 'resolved' }) => {
      const { error } = await supabase
        .from("safety_incidents")
        .update({ 
          status, 
          resolved_at: status === 'resolved' ? new Date().toISOString() : null 
        })
        .eq('id', id)
      if (error) throw error
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["incidents"] })
    }
  })

  // Real-time synchronization
  useEffect(() => {
    const channel = supabase.channel('safety-updates')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'safety_incidents' }, () => {
        queryClient.invalidateQueries({ queryKey: ["incidents"] })
      })
      .subscribe()

    return () => {
      supabase.removeChannel(channel)
    }
  }, [queryClient])

  const activeAlerts = incidents.filter(i => i.status !== 'resolved').length

  return (
    <div className="space-y-8 animate-in transition-all pb-20">
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h1 className="text-3xl font-bold tracking-tight text-slate-900">Safety Center</h1>
          <p className="text-slate-500 mt-1">Monitor and resolve safety-related incidents.</p>
        </div>
        <div className="flex items-center gap-3 bg-rose-50 border border-rose-100 px-4 py-2 rounded-xl shadow-sm">
           <div className="h-2 w-2 rounded-full bg-rose-600 animate-pulse" />
           <span className="text-xs font-bold text-rose-700">{activeAlerts} Active Alerts</span>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div className="lg:col-span-2 space-y-6">
           <div className="flex items-center justify-between mb-2">
             <h2 className="text-lg font-bold text-slate-800 flex items-center gap-2">
                <Activity className="h-4 w-4 text-blue-500" />
                Recent Alerts
             </h2>
             <Button variant="ghost" className="text-xs font-semibold text-slate-400 hover:text-blue-600">Alert History</Button>
           </div>
           
           {incidents?.map((incident) => (
             <Card key={incident.id} className={cn(
               "group border border-slate-100 shadow-lg rounded-2xl overflow-hidden transition-all",
               incident.priority === 'critical' ? "bg-rose-50/20 border-rose-100" : "bg-white"
             )}>
               <CardContent className="p-6 flex items-center gap-5">
                  <div className={cn(
                    "h-14 w-14 rounded-xl flex items-center justify-center transition-transform",
                    incident.priority === 'critical' ? "bg-rose-600 text-white shadow-lg shadow-rose-600/20" : 
                    incident.priority === 'high' ? "bg-amber-500 text-white shadow-lg shadow-amber-500/20" : "bg-slate-100 text-slate-400"
                  )}>
                    <AlertTriangle className="h-6 w-6" />
                  </div>
                  
                  <div className="flex-1">
                    <div className="flex items-center gap-3 mb-1">
                       <Badge className={cn(
                         "px-2 py-0.5 rounded-full text-[10px] font-bold border-none",
                         incident.priority === 'critical' ? "bg-rose-100 text-rose-700" : 
                         incident.priority === 'high' ? "bg-amber-100 text-amber-700" : "bg-slate-100 text-slate-500"
                       )}>
                         {incident.priority || 'medium'}
                       </Badge>
                       <span className="text-[10px] font-medium text-slate-400 flex items-center gap-1.5">
                          <Clock className="h-3 w-3" /> {timeAgo(incident.created_at)}
                       </span>
                    </div>
                     <h3 className="text-xl font-bold text-slate-900 tracking-tight">{incident.type}</h3>
                    <div className="flex flex-wrap items-center gap-4 mt-3">
                       <div className="flex items-center gap-1.5 text-xs font-semibold text-slate-600">
                          <User className="h-3.5 w-3.5 text-slate-400" /> {incident.profiles?.full_name || 'System User'}
                       </div>
                       <div className="flex items-center gap-1.5 text-xs font-semibold text-slate-600">
                          <MapPin className="h-3.5 w-3.5 text-slate-400" /> {incident.location_name || 'Location Not Available'}
                       </div>
                    </div>
                  </div>

                  <div className="flex flex-col gap-2">
                     <Button 
                        className={cn(
                          "rounded-xl h-10 w-10 shadow-md transition-all",
                          incident.status === 'investigating' ? "bg-amber-500 hover:bg-amber-600" : "bg-blue-600 hover:bg-blue-700"
                        )}
                        onClick={() => updateStatusMutation.mutate({ id: incident.id, status: 'investigating' })}
                        disabled={incident.status === 'resolved'}
                      >
                        <ChevronRight className="h-4 w-4" />
                     </Button>
                     <Button 
                        variant="outline" 
                        className="rounded-xl h-10 w-10 border-slate-100 bg-white hover:bg-emerald-50 hover:text-emerald-600 hover:border-emerald-100"
                        onClick={() => updateStatusMutation.mutate({ id: incident.id, status: 'resolved' })}
                        disabled={incident.status === 'resolved'}
                      >
                        <ShieldCheck className="h-4 w-4" />
                     </Button>
                  </div>
               </CardContent>
             </Card>
           ))}

           {incidents.length === 0 && !isLoading && (
             <div className="text-center py-20 bg-white border border-slate-100 rounded-2xl shadow-sm">
                <div className="h-20 w-20 bg-slate-50 rounded-full flex items-center justify-center mx-auto mb-4">
                  <ShieldCheck className="h-10 w-10 text-slate-300" />
                </div>
                <h3 className="text-lg font-bold text-slate-900">No Active Incidents</h3>
                <p className="text-slate-500 max-w-xs mx-auto mt-1">Everything is looking good. All systems are operating normally.</p>
             </div>
           )}
        </div>

        <div className="space-y-6">
           <Card className="border-none shadow-lg rounded-2xl bg-slate-900 text-white overflow-hidden">
              <CardHeader className="p-8 pb-4">
                 <div className="h-12 w-12 bg-emerald-500/10 rounded-xl flex items-center justify-center mb-4 border border-emerald-500/10">
                    <ShieldCheck className="h-6 w-6 text-emerald-400" />
                 </div>
                 <CardTitle className="text-xl font-bold tracking-tight">Emergency Support</CardTitle>
                 <p className="text-slate-400 text-sm mt-1">Direct access to emergency services.</p>
              </CardHeader>
              <CardContent className="p-8 pt-4 space-y-6">
                 <div className="p-5 bg-white/5 rounded-2xl border border-white/10 space-y-4">
                    <p className="text-[10px] font-bold uppercase tracking-wider text-slate-500">Emergency Contacts</p>
                    <div className="grid grid-cols-2 gap-3">
                       <Button variant="outline" className="h-12 rounded-xl border-white/10 bg-white/5 hover:bg-white/10 text-white text-xs font-bold">Police Hub</Button>
                       <Button variant="outline" className="h-12 rounded-xl border-white/10 bg-white/5 hover:bg-white/10 text-white text-xs font-bold">QRU Noida</Button>
                    </div>
                 </div>

                 <div className="space-y-3">
                    <p className="text-[10px] font-bold uppercase tracking-wider text-slate-500 ml-1">Banned Users</p>
                    {[1, 2].map((i) => (
                      <div key={i} className="flex items-center justify-between p-4 bg-white/5 rounded-xl border border-white/10 transition-colors hover:bg-white/10">
                         <div className="flex items-center gap-3">
                            <div className="h-8 w-8 bg-rose-500/20 rounded-lg flex items-center justify-center font-bold text-rose-400">H</div>
                            <div>
                               <p className="text-xs font-semibold">Harsh T.</p>
                               <p className="text-[10px] text-slate-500">Verified Threat</p>
                            </div>
                         </div>
                         <Badge className="bg-rose-500 text-white border-none text-[9px] font-bold px-2">Banned</Badge>
                      </div>
                    ))}
                 </div>
              </CardContent>
              <div className="p-8 pt-0">
                 <button className="w-full py-4 bg-white text-slate-900 rounded-xl font-bold text-xs uppercase shadow-lg transition-all hover:bg-slate-50">
                    Emergency Alert
                 </button>
              </div>
           </Card>

           <div className="p-8 rounded-2xl bg-blue-600 text-white shadow-lg group">
              <h3 className="text-lg font-bold tracking-tight leading-tight">Safety Training</h3>
              <p className="text-blue-100 text-sm mt-2">2 Support Agents need recertification for SOS handling.</p>
              <Button className="mt-6 w-full bg-slate-900 hover:bg-black text-white rounded-xl h-12 font-bold text-[10px] border-none">
                 Assign Training
              </Button>
           </div>
        </div>
      </div>
    </div>
  )
}
