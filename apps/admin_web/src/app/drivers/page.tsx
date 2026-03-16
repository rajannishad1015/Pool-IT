"use client"

import { useQuery, useQueryClient } from "@tanstack/react-query"
import { supabase } from "@/lib/supabase"
import { cn } from "@/lib/utils"
import { useEffect } from "react"
import { 
  Table, 
  TableBody, 
  TableCell, 
  TableHead, 
  TableHeader, 
  TableRow 
} from "@/components/ui/table"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { 
  Search, 
  Filter, 
  ShieldCheck, 
  UserX, 
  MoreVertical,
  ArrowUpDown,
  Download,
  Plus,
  Car
} from "lucide-react"

export default function DriversPage() {
  const queryClient = useQueryClient()

  const { data: drivers, isLoading } = useQuery({
    queryKey: ["drivers"],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("drivers")
        .select(`
          *,
          profiles:id (
            full_name,
            phone_number,
            avatar_url
          )
        `)
      if (error) throw error
      return data
    }
  })

  // Real-time synchronization
  useEffect(() => {
    const channel = supabase.channel('driver-updates')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'drivers' }, () => {
        queryClient.invalidateQueries({ queryKey: ["drivers"] })
      })
      .on('postgres_changes', { event: '*', schema: 'public', table: 'profiles' }, () => {
        queryClient.invalidateQueries({ queryKey: ["drivers"] })
      })
      .subscribe()

    return () => {
      supabase.removeChannel(channel)
    }
  }, [queryClient])

  return (
    <div className="space-y-8 animate-in transition-all">
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h1 className="text-3xl font-bold tracking-tight text-slate-900">Drivers</h1>
          <p className="text-slate-500 mt-1">Manage driver profiles, verification, and performance.</p>
        </div>
        <div className="flex items-center gap-3">
          <Button variant="outline" className="rounded-xl border-slate-200 h-10 px-4 font-semibold text-slate-600 hover:bg-slate-50 gap-2 shadow-sm">
            <Download className="h-4 w-4" /> Export
          </Button>
          <Button className="bg-blue-600 hover:bg-blue-700 h-10 px-5 rounded-xl font-semibold shadow-md gap-2">
            <Plus className="h-4 w-4" /> Add Driver
          </Button>
        </div>
      </div>

      <div className="bg-white rounded-2xl border border-slate-100 p-2 shadow-lg flex flex-wrap items-center gap-3">
        <div className="relative flex-1 min-w-[300px]">
          <Search className="absolute left-4 top-1/2 -translate-y-1/2 h-5 w-5 text-slate-400" />
          <Input 
            placeholder="Search by name, license number or ID..." 
            className="h-12 pl-12 pr-4 rounded-xl border-none bg-slate-50/50 focus-visible:ring-2 focus-visible:ring-blue-500/20 font-medium text-slate-900" 
          />
        </div>
        <Button variant="outline" className="h-12 px-5 rounded-xl border-slate-100 bg-white font-semibold gap-2 text-slate-600 hover:bg-slate-50">
          <Filter className="h-5 w-5" /> Filter
        </Button>
      </div>

      <div className="rounded-2xl border border-slate-100 shadow-md overflow-hidden bg-white">
        <Table>
          <TableHeader className="bg-slate-50/50">
            <TableRow>
              <TableHead className="py-4 px-8 font-bold text-xs text-slate-400">Driver</TableHead>
              <TableHead className="py-4 px-4 font-bold text-xs text-slate-400">License No.</TableHead>
              <TableHead className="py-4 px-4 font-bold text-xs text-slate-400">Status</TableHead>
              <TableHead className="py-4 px-4 font-bold text-xs text-slate-400 text-right">Total Earnings</TableHead>
              <TableHead className="py-4 px-4 font-bold text-xs text-slate-400 text-center">Strikes</TableHead>
              <TableHead className="py-4 px-4 font-bold text-xs text-slate-400">Last Seen</TableHead>
              <TableHead className="py-4 px-8 text-right font-bold text-xs text-slate-400">Actions</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {isLoading ? (
              <TableRow>
                <TableCell colSpan={7} className="text-center py-20">
                  <div className="flex flex-col items-center gap-4">
                    <div className="h-10 w-10 border-4 border-slate-100 border-t-blue-600 rounded-full animate-spin" />
                    <p className="font-bold text-slate-400 text-sm">Loading Drivers...</p>
                  </div>
                </TableCell>
              </TableRow>
            ) : drivers?.length === 0 ? (
              <TableRow>
                <TableCell colSpan={7} className="text-center py-24">
                   <div className="max-w-xs mx-auto">
                     <div className="h-20 w-20 bg-slate-50 rounded-[2rem] flex items-center justify-center mx-auto mb-6">
                       <Car className="h-10 w-10 text-slate-200" />
                     </div>
                     <h3 className="text-xl font-black text-slate-900">No Drivers Found</h3>
                     <p className="text-slate-500 mt-2 font-medium">We couldn't find any drivers matching your criteria.</p>
                     <Button variant="outline" className="mt-6 rounded-xl border-slate-200">Clear All Filters</Button>
                   </div>
                </TableCell>
              </TableRow>
            ) : drivers?.map((driver) => (
              <TableRow key={driver.id} className="hover:bg-slate-50 transition-colors border-b border-slate-50 last:border-0">
                <TableCell className="py-4 px-8">
                  <div className="flex items-center gap-4">
                    <div className="h-10 w-10 rounded-lg bg-blue-50 flex items-center justify-center font-bold text-blue-600">
                      {(driver.profiles as any)?.full_name?.charAt(0) || "D"}
                    </div>
                    <div>
                      <p className="font-bold text-slate-900 leading-tight">{(driver.profiles as any)?.full_name}</p>
                      <p className="text-xs text-slate-400 mt-0.5">{(driver.profiles as any)?.phone_number}</p>
                    </div>
                  </div>
                </TableCell>
                <TableCell className="py-5 px-4">
                  <div className="px-3 py-1.5 bg-slate-100 rounded-lg inline-block">
                    <span className="font-mono text-xs font-black text-slate-600 tracking-wider uppercase">{driver.dl_number}</span>
                  </div>
                </TableCell>
                <TableCell className="py-4 px-4">
                  <Badge variant="outline" className={cn(
                    "px-3 py-1 rounded-full font-bold text-[10px] border-none shadow-sm capitalize",
                    driver.verification_status === 'verified' ? "bg-emerald-50 text-emerald-600" : 
                    driver.verification_status === 'pending' ? "bg-amber-50 text-amber-600" : 
                    "bg-rose-50 text-rose-600"
                  )}>
                    {driver.verification_status}
                  </Badge>
                </TableCell>
                <TableCell className="py-4 px-4 text-right">
                  <p className="font-bold text-slate-900">₹{driver.total_earnings?.toLocaleString()}</p>
                </TableCell>
                <TableCell className="py-4 px-4 text-center">
                   <div className={cn(
                     "h-7 w-7 rounded-md flex items-center justify-center mx-auto text-xs font-bold",
                     driver.strikes && driver.strikes > 0 ? "bg-rose-100 text-rose-600" : "bg-slate-100 text-slate-400"
                   )}>
                    {driver.strikes || 0}
                   </div>
                </TableCell>
                <TableCell className="py-4 px-4">
                  <div className="flex flex-col">
                    <p className="text-xs font-semibold text-slate-900 capitalize">{driver.last_online_at ? 'online' : 'away'}</p>
                    <p className="text-[10px] text-slate-400">
                      {driver.last_online_at ? new Date(driver.last_online_at).toLocaleDateString(undefined, { month: 'short', day: 'numeric' }) : 'No history'}
                    </p>
                  </div>
                </TableCell>
                <TableCell className="py-4 px-8 text-right">
                  <div className="flex justify-end gap-2">
                    <Button variant="ghost" size="icon" className="h-8 w-8 rounded-lg hover:bg-emerald-50 hover:text-emerald-600" title="Verify Documents">
                      <ShieldCheck className="h-4 w-4" />
                    </Button>
                    <Button variant="ghost" size="icon" className="h-8 w-8 rounded-lg hover:bg-slate-100" title="Options">
                      <MoreVertical className="h-4 w-4" />
                    </Button>
                  </div>
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
        <div className="bg-slate-50/50 p-6 flex items-center justify-between border-t border-slate-50">
          <p className="text-xs font-bold text-slate-400 tracking-widest uppercase italic">Showing {drivers?.length || 0} Total Drivers</p>
          <div className="flex gap-2">
            <Button disabled variant="outline" className="rounded-xl border-slate-200 h-9 font-black text-[10px] uppercase tracking-widest px-4">Previous</Button>
            <Button variant="outline" className="rounded-xl border-slate-200 h-9 font-black text-[10px] uppercase tracking-widest px-4 hover:bg-white hover:shadow-md transition-all">Next Page</Button>
          </div>
        </div>
      </div>
    </div>
  )
}
