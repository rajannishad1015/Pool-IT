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
  User, 
  Ban, 
  MoreVertical,
  ArrowUpDown,
  Download,
  Users
} from "lucide-react"

export default function RidersPage() {
  const queryClient = useQueryClient()

  const { data: riders, isLoading } = useQuery({
    queryKey: ["riders"],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("profiles")
        .select("*")
        .order('created_at', { ascending: false })
      if (error) throw error
      return data
    }
  })

  // Real-time synchronization
  useEffect(() => {
    const channel = supabase.channel('rider-updates')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'profiles' }, () => {
        queryClient.invalidateQueries({ queryKey: ["riders"] })
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
          <h1 className="text-3xl font-bold tracking-tight text-slate-900">Passenger Directory</h1>
          <p className="text-slate-500 mt-1">Manage and oversee all registered passengers.</p>
        </div>
        <div className="flex items-center gap-3">
          <Button variant="outline" className="rounded-xl border-slate-200 h-10 px-4 font-semibold text-slate-600 hover:bg-slate-50 gap-2 shadow-sm">
            <Download className="h-4 w-4" /> Export
          </Button>
          <div className="h-10 px-4 rounded-xl bg-blue-50 border border-blue-100 flex items-center gap-2 font-bold text-xs text-blue-600">
             <Users className="h-4 w-4" /> {riders?.length || 0} Passengers
          </div>
        </div>
      </div>

      <div className="bg-white rounded-2xl border border-slate-100 p-2 shadow-lg flex flex-wrap items-center gap-3">
        <div className="relative flex-1 min-w-[300px]">
          <Search className="absolute left-4 top-1/2 -translate-y-1/2 h-5 w-5 text-slate-400" />
          <Input 
            placeholder="Search by name, phone or email..." 
            className="h-12 pl-12 pr-4 rounded-xl border-none bg-slate-50/50 focus-visible:ring-2 focus-visible:ring-blue-500/20 text-slate-900" 
          />
        </div>
        <Button variant="outline" className="h-12 px-5 rounded-xl border-slate-100 bg-white font-semibold gap-2 text-slate-600 hover:bg-slate-50">
          <Filter className="h-5 w-5" /> Filter
        </Button>
      </div>

      <div className="rounded-2xl border border-slate-100 shadow-xl overflow-hidden bg-white">
        <Table>
          <TableHeader className="bg-slate-50/50 border-b border-slate-100">
            <TableRow className="hover:bg-transparent">
              <TableHead className="py-4 px-6 font-bold text-xs text-slate-500">Passenger Details</TableHead>
              <TableHead className="py-4 px-4 font-bold text-xs text-slate-500 whitespace-nowrap">
                 <div className="flex items-center gap-2">Joined Date <ArrowUpDown className="h-3 w-3" /></div>
              </TableHead>
              <TableHead className="py-4 px-4 font-bold text-xs text-slate-500">Status</TableHead>
              <TableHead className="py-4 px-4 font-bold text-xs text-slate-500">Activity</TableHead>
              <TableHead className="py-4 px-6 text-right font-bold text-xs text-slate-500">Actions</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {isLoading ? (
              <TableRow>
                <TableCell colSpan={5} className="text-center py-20">
                  <div className="flex flex-col items-center gap-4">
                    <div className="h-12 w-12 border-4 border-blue-100 border-t-blue-600 rounded-full animate-spin" />
                    <p className="font-bold text-slate-400 text-sm tracking-widest uppercase">Fetching Rider Data...</p>
                  </div>
                </TableCell>
              </TableRow>
            ) : riders?.length === 0 ? (
              <TableRow>
                <TableCell colSpan={5} className="text-center py-24">
                   <div className="max-w-xs mx-auto text-center">
                     <div className="h-20 w-20 bg-slate-50 rounded-[2rem] flex items-center justify-center mx-auto mb-6">
                       <User className="h-10 w-10 text-slate-200" />
                     </div>
                     <h3 className="text-xl font-black text-slate-900">No Riders Mapped</h3>
                     <p className="text-slate-500 mt-2 font-medium">The rider network is currently offline or unpopulated.</p>
                   </div>
                </TableCell>
              </TableRow>
            ) : riders?.map((rider) => (
              <TableRow key={rider.id} className="group hover:bg-slate-50/50 transition-all border-b border-slate-50 last:border-0">
                <TableCell className="py-4 px-6">
                  <div className="flex items-center gap-3">
                    <div className="h-10 w-10 rounded-lg bg-slate-50 border border-slate-100 flex items-center justify-center font-bold text-blue-600 transition-transform">
                      {rider.full_name?.charAt(0) || "R"}
                    </div>
                    <div>
                      <p className="font-bold text-slate-900">{rider.full_name || "Unknown User"}</p>
                      <p className="text-xs text-slate-500 font-medium">{rider.phone_number || "No Phone"}</p>
                    </div>
                  </div>
                </TableCell>
                <TableCell className="py-4 px-4">
                  <span className="text-xs text-slate-500">
                    {rider.created_at ? new Date(rider.created_at).toLocaleDateString(undefined, { month: 'short', day: 'numeric', year: 'numeric' }) : 'N/A'}
                  </span>
                </TableCell>
                <TableCell className="py-4 px-4">
                  <Badge variant="outline" className={cn(
                    "px-3 py-1 rounded-full text-[10px] font-bold border-none",
                    rider.is_verified ? "bg-emerald-50 text-emerald-600" : "bg-slate-100 text-slate-500"
                  )}>
                    {rider.is_verified ? 'Verified' : 'Unverified'}
                  </Badge>
                </TableCell>
                <TableCell className="py-4 px-4">
                   <div className="flex flex-col gap-1">
                     <div className="h-1 w-16 bg-slate-100 rounded-full overflow-hidden">
                        <div className="h-full bg-blue-500 w-[60%]" />
                     </div>
                     <p className="text-[10px] font-bold text-slate-400 uppercase tracking-tight">Activity Log</p>
                   </div>
                </TableCell>
                <TableCell className="py-4 px-6 text-right">
                  <div className="flex justify-end gap-2">
                    <Button variant="outline" size="icon" className="h-8 w-8 rounded-lg border-slate-100 hover:bg-red-50 hover:text-red-600 hover:border-red-200" title="Block User">
                      <Ban className="h-3.5 w-3.5" />
                    </Button>
                    <Button variant="outline" size="icon" className="h-8 w-8 rounded-lg border-slate-100" title="Options">
                      <MoreVertical className="h-3.5 w-3.5 text-slate-400" />
                    </Button>
                  </div>
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </div>
    </div>
  )
}
