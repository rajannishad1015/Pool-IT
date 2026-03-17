"use client"

import { useQuery, useQueryClient, useMutation } from "@tanstack/react-query"
import { supabase } from "@/lib/supabase"
import { cn } from "@/lib/utils"
import { useEffect, useState } from "react"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
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
import {
  TrendingUp,
  CreditCard,
  ArrowUpRight,
  ArrowDownRight,
  DollarSign,
  Download,
  Calendar,
  Wallet,
  Check,
  Loader2
} from "lucide-react"

export default function FinancePage() {
  const queryClient = useQueryClient()

  const { data: transactions = [], isLoading } = useQuery({
    queryKey: ["transactions"],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("transactions")
        .select("*")
        .order('created_at', { ascending: false })
        .limit(20)
      if (error) throw error
      return data || []
    }
  })

  // Fetch drivers with pending earnings (drivers with earnings > 0)
  const { data: driverPayouts = [], isLoading: payoutsLoading } = useQuery({
    queryKey: ["driver-payouts"],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("drivers")
        .select(`
          id,
          total_earnings,
          is_online,
          profiles:id (
            full_name,
            phone_number
          )
        `)
        .gt('total_earnings', 0)
        .order('total_earnings', { ascending: false })
        .limit(10)
      if (error) throw error
      return data || []
    }
  })

  // Calculate next payout time (example: next Sunday at midnight)
  const getNextPayoutTime = () => {
    const now = new Date()
    const nextSunday = new Date(now)
    nextSunday.setDate(now.getDate() + (7 - now.getDay()))
    nextSunday.setHours(0, 0, 0, 0)
    const diff = nextSunday.getTime() - now.getTime()
    const hours = Math.floor(diff / (1000 * 60 * 60))
    const minutes = Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60))
    return `${hours}h ${minutes}m`
  }

  // Payout mutation (resets driver earnings after payout)
  const payoutMutation = useMutation({
    mutationFn: async (driverId: string) => {
      // In a real app, you'd process the payout first, then reset earnings
      const { error } = await supabase
        .from("drivers")
        .update({ total_earnings: 0 })
        .eq('id', driverId)
      if (error) throw error
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["driver-payouts"] })
    }
  })

  // Real-time synchronization
  useEffect(() => {
    const channel = supabase.channel('finance-updates')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'transactions' }, () => {
        queryClient.invalidateQueries({ queryKey: ["transactions"] })
      })
      .on('postgres_changes', { event: '*', schema: 'public', table: 'drivers' }, () => {
        queryClient.invalidateQueries({ queryKey: ["driver-payouts"] })
      })
      .subscribe()

    return () => {
      supabase.removeChannel(channel)
    }
  }, [queryClient])

  const grossRevenue = transactions.reduce((acc, t) => acc + (t.amount || 0), 0)
  const platformCommission = grossRevenue * 0.2
  const totalPendingPayouts = driverPayouts.reduce((acc, d) => acc + (d.total_earnings || 0), 0)

  const metrics = [
    { label: "Gross Revenue", value: `₹${grossRevenue.toLocaleString()}`, trend: transactions.length > 0 ? `${transactions.length} txns` : "No data", up: grossRevenue > 0, icon: DollarSign, color: "blue" },
    { label: "Platform Commission", value: `₹${platformCommission.toLocaleString()}`, trend: "20% share", up: true, icon: TrendingUp, color: "emerald" },
    { label: "Pending Payouts", value: `₹${totalPendingPayouts.toLocaleString()}`, trend: driverPayouts.length > 0 ? `${driverPayouts.length} drivers` : "None", up: false, icon: Wallet, color: "amber" },
  ]

  return (
    <div className="space-y-10 animate-in transition-all pb-20">
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h1 className="text-3xl font-bold tracking-tight text-slate-900">Revenue & Payments</h1>
          <p className="text-slate-500 mt-1">Platform earnings and transaction history.</p>
        </div>
        <div className="flex items-center gap-3">
          <Button variant="outline" className="rounded-xl border-slate-200 h-10 px-4 font-semibold text-slate-600 gap-2">
             <Calendar className="h-4 w-4 text-slate-400" />
             <span className="text-sm">Current Month</span>
          </Button>
          <Button className="rounded-xl bg-blue-600 text-white h-10 px-4 font-semibold shadow-md hover:bg-blue-700 gap-2">
             <Download className="h-4 w-4" />
             <span className="text-sm">Download Excel</span>
          </Button>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        {metrics.map((metric, i) => (
          <Card key={i} className="border-none shadow-lg rounded-2xl overflow-hidden bg-white">
            <CardContent className="p-8">
              <div className="flex items-center justify-between">
                <div className={cn(
                  "p-3 rounded-xl",
                  metric.color === 'blue' ? "bg-blue-50 text-blue-600" : 
                  metric.color === 'emerald' ? "bg-emerald-50 text-emerald-600" : "bg-amber-50 text-amber-600"
                )}>
                  <metric.icon className="h-6 w-6" />
                </div>
                <Badge className={cn(
                  "px-2.5 py-1 rounded-full text-xs font-bold border-none",
                  metric.up ? "bg-emerald-50 text-emerald-600" : "bg-amber-50 text-amber-600"
                )}>
                  {metric.trend}
                </Badge>
              </div>
              <div className="mt-5">
                <p className="text-xs font-bold text-slate-400 uppercase tracking-wider">{metric.label}</p>
                <p className="text-3xl font-bold text-slate-900 mt-1">{metric.value}</p>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <Card className="lg:col-span-2 border-none shadow-lg rounded-2xl overflow-hidden bg-white flex flex-col">
          <CardHeader className="px-8 py-6 border-b border-slate-50 flex flex-row items-center justify-between bg-slate-50/30">
            <CardTitle className="text-xl font-bold text-slate-800">Recent Transactions</CardTitle>
            <Badge variant="outline" className="rounded-full px-3 border-slate-100 font-bold text-slate-400">Live Updates</Badge>
          </CardHeader>
          <CardContent className="p-0 flex-1">
             <Table>
                <TableHeader className="bg-slate-50/30">
                  <TableRow className="hover:bg-transparent">
                    <TableHead className="py-4 px-6 font-bold text-xs text-slate-500">ID</TableHead>
                    <TableHead className="py-4 px-4 font-bold text-xs text-slate-500">Date</TableHead>
                    <TableHead className="py-4 px-4 font-bold text-xs text-slate-500">Amount</TableHead>
                    <TableHead className="py-4 px-4 font-bold text-xs text-slate-500">Mode</TableHead>
                    <TableHead className="py-4 px-6 text-right font-bold text-xs text-slate-500">Status</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {isLoading ? (
                    <TableRow>
                      <TableCell colSpan={5} className="py-20 text-center text-slate-400 font-semibold uppercase tracking-wider text-xs">Loading History...</TableCell>
                    </TableRow>
                  ) : transactions?.length === 0 ? (
                    <TableRow>
                      <TableCell colSpan={5} className="py-24 text-center">
                        <div className="h-12 w-12 bg-slate-50 rounded-xl flex items-center justify-center mx-auto mb-4 border border-slate-100">
                           <CreditCard className="h-6 w-6 text-slate-200" />
                        </div>
                        <p className="font-bold text-slate-900">No Transactions</p>
                        <p className="text-slate-500 text-sm mt-1">No payments recorded yet.</p>
                      </TableCell>
                    </TableRow>
                  ) : transactions?.map((t) => (
                    <TableRow key={t.id} className="hover:bg-slate-50/50 transition-all border-b border-slate-50 last:border-0 group">
                      <TableCell className="py-4 px-6">
                        <span className="font-mono text-xs font-bold text-slate-500 tracking-wider">#{t.id.slice(0, 8).toUpperCase()}</span>
                      </TableCell>
                      <TableCell className="py-4 px-4">
                        <span className="text-xs font-medium text-slate-500">{t.created_at ? new Date(t.created_at).toLocaleString(undefined, { month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' }) : 'N/A'}</span>
                      </TableCell>
                      <TableCell className="py-4 px-4">
                        <span className="font-bold text-slate-900">₹{t.amount}</span>
                      </TableCell>
                      <TableCell className="py-4 px-4">
                        <Badge variant="outline" className="border-slate-100 text-[10px] font-bold text-slate-400">Card</Badge>
                      </TableCell>
                      <TableCell className="py-4 px-6 text-right">
                        <Badge className={cn(
                          "px-3 py-1 rounded-full font-bold text-[10px] border-none shadow-sm",
                          (t as any).status === 'completed' ? "bg-emerald-50 text-emerald-600" : "bg-amber-50 text-amber-600"
                        )}>
                          {(t as any).status || 'pending'}
                        </Badge>
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
             </Table>
          </CardContent>
          <div className="p-4 bg-slate-50/50 border-t border-slate-50">
             <button className="w-full py-2 text-xs font-bold text-blue-600 hover:text-blue-700 transition-colors">View All Transactions</button>
          </div>
        </Card>

        <Card className="border-none shadow-lg rounded-2xl overflow-hidden bg-slate-900 text-white flex flex-col">
           <CardHeader className="p-8 pb-4">
              <div className="h-10 w-10 bg-white/10 rounded-xl flex items-center justify-center mb-4 border border-white/10">
                 <Wallet className="h-5 w-5 text-blue-400" />
              </div>
              <CardTitle className="text-xl font-bold tracking-tight">Driver Payouts</CardTitle>
              <p className="text-slate-400 text-sm mt-1">Manage vendor and driver settlements.</p>
           </CardHeader>
           <CardContent className="p-8 pt-4 flex-1">
              <div className="space-y-6">
                 <div className="p-5 bg-white/5 rounded-2xl border border-white/10">
                    <p className="text-[10px] font-bold uppercase tracking-wider text-slate-400 mb-1">Next Payout Cycle</p>
                    <div className="flex items-center justify-between">
                       <p className="text-xl font-bold">{getNextPayoutTime()}</p>
                       <Badge className="bg-blue-500/20 text-blue-400 border-none font-bold text-[10px] px-2.5">Scheduled</Badge>
                    </div>
                 </div>

                 <div className="space-y-3">
                    <p className="text-[10px] font-bold uppercase tracking-wider text-slate-500 ml-1">Pending Payouts ({driverPayouts.length})</p>
                    {payoutsLoading ? (
                      <div className="flex items-center justify-center py-8">
                        <Loader2 className="h-6 w-6 animate-spin text-slate-400" />
                      </div>
                    ) : driverPayouts.length > 0 ? (
                      driverPayouts.slice(0, 5).map((driver) => (
                        <div key={driver.id} className="flex items-center justify-between p-4 bg-white/5 rounded-xl border border-transparent hover:border-white/10">
                           <div className="flex items-center gap-3">
                              <div className="h-8 w-8 bg-white/10 rounded-lg flex items-center justify-center font-bold text-sm">
                                {(driver.profiles as any)?.full_name?.charAt(0)?.toUpperCase() || 'D'}
                              </div>
                              <div>
                                 <p className="text-sm font-semibold">{(driver.profiles as any)?.full_name || 'Driver'}</p>
                                 <p className="text-[10px] text-slate-500 font-bold tracking-tighter">#{driver.id.slice(0, 8).toUpperCase()}</p>
                              </div>
                           </div>
                           <div className="text-right">
                              <p className="text-sm font-bold">₹{(driver.total_earnings || 0).toLocaleString()}</p>
                              <button
                                onClick={() => payoutMutation.mutate(driver.id)}
                                disabled={payoutMutation.isPending}
                                className="text-[10px] font-bold text-blue-400 hover:text-white transition-colors disabled:opacity-50"
                              >
                                {payoutMutation.isPending ? 'Processing...' : 'Approve'}
                              </button>
                           </div>
                        </div>
                      ))
                    ) : (
                      <div className="py-8 text-center">
                        <Check className="h-8 w-8 text-emerald-400 mx-auto mb-2" />
                        <p className="text-sm text-slate-400 font-medium">All payouts cleared</p>
                      </div>
                    )}
                 </div>
              </div>
           </CardContent>
           <div className="p-6">
              <Button className="w-full py-5 bg-white text-slate-900 rounded-xl font-bold text-xs uppercase hover:bg-slate-100 transition-all">
                 Process Manual Payout
              </Button>
           </div>
        </Card>
      </div>
    </div>
  )
}
