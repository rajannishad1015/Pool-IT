"use client"

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query"
import { supabase } from "@/lib/supabase"
import { Card, CardContent } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { 
  FileText, 
  CheckCircle, 
  XCircle, 
  ExternalLink,
  Clock,
  ShieldAlert,
  Verified,
  User,
  Eye,
  MapPin,
  Calendar,
  Phone,
  ArrowRight,
  Info
} from "lucide-react"
import { cn } from "@/lib/utils"
import { useEffect, useState } from "react"

export default function VerificationQueuePage() {
  const queryClient = useQueryClient()
  const [selectedDriver, setSelectedDriver] = useState<any>(null)
  
  const { data: pendingDrivers, isLoading } = useQuery({
    queryKey: ["pending-drivers"],
    queryFn: async () => {
      // 1. Get all pending documents with profile info
      const { data: docs, error: docError } = await supabase
        .from("driver_documents")
        .select(`
          *,
          profiles:driver_id (
            id,
            full_name,
            phone_number,
            avatar_url,
            gender,
            date_of_birth
          )
        `)
        .eq("status", "pending")
      
      if (docError) throw docError

      // 2. Get driver details for these users
      const driverIds = Array.from(new Set(docs.map(d => d.driver_id))).filter(id => id !== null) as string[]
      
      if (driverIds.length === 0) return []

      const { data: drivers, error: driverError } = await supabase
        .from("drivers")
        .select("*")
        .in("id", driverIds)
      
      if (driverError) throw driverError

      // 3. Group documents by driver
      const groupedData = drivers.map(driver => {
        const driverDocs = docs.filter(d => d.driver_id === driver.id)
        const profile = driverDocs[0]?.profiles
        return {
          ...driver,
          profiles: profile,
          driver_documents: driverDocs
        }
      })

      console.log('Grouped Verification Data:', groupedData);
      return groupedData
    }
  })

  // Real-time synchronization
  useEffect(() => {
    const channel = supabase.channel('verification-updates-group')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'drivers' }, () => {
        queryClient.invalidateQueries({ queryKey: ["pending-drivers"] })
      })
      .on('postgres_changes', { event: '*', schema: 'public', table: 'driver_documents' }, () => {
        queryClient.invalidateQueries({ queryKey: ["pending-drivers"] })
      })
      .subscribe()

    return () => {
      supabase.removeChannel(channel)
    }
  }, [queryClient])

  const approveMutation = useMutation({
    mutationFn: async (driverId: string) => {
      // 1. Approve Driver
      const { error: driverError } = await supabase
        .from("drivers")
        .update({ verification_status: 'verified' })
        .eq("id", driverId)
      
      if (driverError) throw driverError

      // 2. Mark all documents as verified
      const { error: docsError } = await supabase
        .from("driver_documents")
        .update({ status: 'verified' })
        .eq("driver_id", driverId)
        .eq("status", "pending")
      
      if (docsError) throw docsError
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["pending-drivers"] })
      queryClient.invalidateQueries({ queryKey: ["drivers"] })
      setSelectedDriver(null)
    }
  })

  const getDocUrl = (path: string) => {
    if (!path) return ""
    const { data } = supabase.storage.from("driver-docs").getPublicUrl(path)
    return data.publicUrl
  }

  return (
    <div className="space-y-8 animate-in transition-all pb-24 relative min-h-[80vh]">
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h1 className="text-3xl font-bold tracking-tight text-slate-900">Driver Onboarding Requests</h1>
          <p className="text-slate-500 mt-1">Review applicant profiles and verify submitted documents.</p>
        </div>
        <div className="flex items-center gap-3">
          <div className="h-10 px-4 rounded-xl bg-amber-50 border border-amber-100 flex items-center gap-2 font-bold text-xs text-amber-600">
            <ShieldAlert className="h-4 w-4" /> {pendingDrivers?.length || 0} Requests Pending
          </div>
        </div>
      </div>

      {isLoading ? (
        <div className="flex flex-col items-center justify-center py-40 gap-4 opacity-50">
          <div className="h-12 w-12 border-4 border-slate-100 border-t-blue-600 rounded-full animate-spin" />
          <p className="font-bold text-slate-400 text-xs uppercase tracking-wider">Gathering Requests...</p>
        </div>
      ) : pendingDrivers?.length === 0 ? (
        <div className="bg-slate-50/50 border-2 border-dashed border-slate-200 rounded-3xl py-24 text-center">
          <div className="h-20 w-20 bg-white rounded-2xl flex items-center justify-center mx-auto mb-6 shadow-sm border border-slate-100">
            <Verified className="h-10 w-10 text-emerald-500" />
          </div>
          <h3 className="font-bold text-slate-900 text-2xl tracking-tight">Queue is Empty</h3>
          <p className="text-slate-500 max-w-sm mx-auto mt-2 text-sm leading-relaxed">Great job! All driver requests have been processed.</p>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {pendingDrivers?.map((driver) => (
            <Card key={driver.id} className="group overflow-hidden border border-slate-100 shadow-lg hover:shadow-xl transition-all duration-300 rounded-3xl bg-white">
              <CardContent className="p-0">
                <div className="p-6 pb-4 flex items-center gap-4">
                  <div className="h-16 w-16 rounded-2xl bg-slate-50 flex items-center justify-center border border-slate-100 shadow-sm relative overflow-hidden">
                    {driver.profiles?.avatar_url ? (
                        <img src={driver.profiles.avatar_url} alt="" className="h-full w-full object-cover" />
                    ) : (
                        <User className="h-8 w-8 text-slate-300" />
                    )}
                  </div>
                  <div className="min-w-0">
                    <h3 className="font-bold text-slate-900 text-xl leading-tight truncate">{driver.profiles?.full_name}</h3>
                    <div className="flex items-center gap-2 mt-1">
                      <Phone className="h-3 w-3 text-slate-400" />
                      <span className="text-sm text-slate-500 font-medium">{driver.profiles?.phone_number}</span>
                    </div>
                  </div>
                </div>

                <div className="px-6 py-4 bg-slate-50/50 border-y border-slate-50 grid grid-cols-2 gap-4">
                  <div className="space-y-1">
                    <p className="text-[10px] font-bold text-slate-400 uppercase tracking-wider">DOCUMENTS</p>
                    <div className="flex items-center gap-1.5 font-bold text-slate-700">
                      <FileText className="h-3.5 w-3.5 text-blue-500" />
                      {driver.driver_documents?.length || 0} Uploaded
                    </div>
                  </div>
                  <div className="space-y-1">
                    <p className="text-[10px] font-bold text-slate-400 uppercase tracking-wider">STATUS</p>
                    <Badge variant="outline" className="bg-amber-100/50 text-amber-600 border-none font-bold text-[10px] py-0.5 px-2">
                       AWAITING REVIEW
                    </Badge>
                  </div>
                </div>

                <div className="p-6 gap-3 flex">
                  <Button 
                    variant="outline"
                    className="flex-1 rounded-2xl border-slate-200 font-bold text-xs uppercase tracking-widest h-12 gap-2 hover:bg-slate-50 transition-all border-2"
                    onClick={() => setSelectedDriver(driver)}
                  >
                    <Eye className="h-4 w-4" /> Review
                  </Button>
                  <Button 
                    className="flex-1 bg-emerald-600 hover:bg-emerald-700 text-white rounded-2xl font-bold text-xs uppercase tracking-widest h-12 gap-2 shadow-lg shadow-emerald-200 transition-all"
                    onClick={() => approveMutation.mutate(driver.id)}
                    disabled={approveMutation.isPending}
                  >
                    <CheckCircle className="h-4 w-4" /> Instant Verify
                  </Button>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      )}

      {/* Verification Detailed Modal (Simplified for the task) */}
      {selectedDriver && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 md:p-8 bg-slate-900/40 backdrop-blur-sm animate-in fade-in duration-200">
           <Card className="w-full max-w-5xl max-h-[90vh] overflow-hidden rounded-[2.5rem] shadow-2xl flex flex-col bg-white border-none">
              <div className="p-8 border-b border-slate-100 flex items-center justify-between bg-slate-50/30">
                 <div className="flex items-center gap-6">
                    <div className="h-20 w-20 rounded-3xl bg-white shadow-md border border-slate-100 overflow-hidden shrink-0">
                       {selectedDriver.profiles?.avatar_url ? (
                           <img src={selectedDriver.profiles.avatar_url} alt="" className="h-full w-full object-cover" />
                       ) : (
                           <div className="h-full w-full flex items-center justify-center bg-slate-50 text-slate-200">
                               <User className="h-10 w-10" />
                           </div>
                       )}
                    </div>
                    <div>
                       <h2 className="text-3xl font-black text-slate-900 leading-tight">{selectedDriver.profiles?.full_name}</h2>
                       <div className="flex flex-wrap items-center gap-4 mt-2">
                          <div className="flex items-center gap-2 text-slate-500 font-bold text-sm bg-white px-3 py-1 rounded-full border border-slate-100 shadow-sm">
                             <Phone className="h-3.5 w-3.5 text-blue-500" /> {selectedDriver.profiles?.phone_number}
                          </div>
                          <div className="flex items-center gap-2 text-slate-500 font-bold text-sm bg-white px-3 py-1 rounded-full border border-slate-100 shadow-sm">
                             <Calendar className="h-3.5 w-3.5 text-amber-500" /> {selectedDriver.profiles?.date_of_birth || 'N/A'}
                          </div>
                          <Badge variant="outline" className="bg-blue-50 text-blue-600 border-none font-black text-[10px] px-3 py-1 uppercase tracking-widest">
                             {selectedDriver.profiles?.gender}
                          </Badge>
                       </div>
                    </div>
                 </div>
                 <Button 
                    variant="ghost" 
                    size="icon" 
                    className="h-12 w-12 rounded-2xl hover:bg-slate-100"
                    onClick={() => setSelectedDriver(null)}
                 >
                    <XCircle className="h-6 w-6 text-slate-400" />
                 </Button>
              </div>

              <div className="flex-1 overflow-y-auto p-8 grid grid-cols-1 md:grid-cols-2 gap-8 bg-slate-50/20">
                 <div className="space-y-6">
                    <div className="flex items-center gap-2 text-slate-900 font-bold text-lg px-2">
                       <Info className="h-5 w-5 text-blue-600" /> Registration Details
                    </div>
                    <div className="grid grid-cols-1 gap-4">
                       {[
                         { label: 'License Number', value: selectedDriver.dl_number },
                         { label: 'Vehicle', value: `${selectedDriver.vehicle_make || ''} ${selectedDriver.vehicle_model || ''}` },
                         { label: 'Registration Date', value: new Date(selectedDriver.created_at).toLocaleDateString() },
                       ].map((item, idx) => (
                          <div key={idx} className="bg-white p-5 rounded-2xl border border-slate-50 shadow-sm">
                             <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest mb-1">{item.label}</p>
                             <p className="text-slate-900 font-bold">{item.value || 'Not provided'}</p>
                          </div>
                       ))}
                    </div>
                 </div>

                 <div className="space-y-6">
                    <div className="flex items-center gap-2 text-slate-900 font-bold text-lg px-2">
                       <FileText className="h-5 w-5 text-emerald-600" /> Document Files
                    </div>
                    <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                       {selectedDriver.driver_documents?.map((doc: any) => (
                          <div key={doc.id} className="group relative aspect-video bg-white rounded-2xl border border-slate-100 shadow-sm overflow-hidden cursor-pointer">
                             <img src={getDocUrl(doc.file_path)} alt={doc.doc_type} className="h-full w-full object-cover transition-transform group-hover:scale-110" />
                             <div className="absolute inset-x-0 bottom-0 bg-gradient-to-t from-slate-900/80 p-3 flex flex-col justify-end min-h-[50%]">
                                <p className="text-[10px] font-bold text-white/70 uppercase tracking-widest">{doc.doc_type.replace('_', ' ')}</p>
                                <div className="flex items-center justify-between mt-1">
                                    <span className="text-xs font-black text-white">Review Image</span>
                                    <ExternalLink className="h-3 w-3 text-white" />
                                </div>
                             </div>
                             <a href={getDocUrl(doc.file_path)} target="_blank" className="absolute inset-0 z-10" />
                          </div>
                       ))}
                    </div>
                 </div>
              </div>

              <div className="p-8 border-t border-slate-100 flex items-center justify-end gap-3 bg-white">
                 <Button 
                    variant="outline" 
                    className="rounded-2xl border-2 border-slate-100 h-14 px-8 font-black text-xs uppercase tracking-widest text-slate-500 hover:bg-slate-50 hover:text-rose-500 hover:border-rose-100 transition-all"
                    onClick={() => {
                        // For simplicity, just reject the driver
                        supabase.from("drivers").update({ verification_status: 'rejected' }).eq("id", selectedDriver.id).then(() => {
                            queryClient.invalidateQueries({ queryKey: ["pending-drivers"] })
                            setSelectedDriver(null)
                        })
                    }}
                 >
                    Reject Applicant
                 </Button>
                 <Button 
                    className="rounded-2xl bg-emerald-600 hover:bg-emerald-700 h-14 px-10 font-black text-xs uppercase tracking-widest text-white shadow-xl shadow-emerald-200 flex gap-3 transition-all scale-100 hover:scale-[1.02] active:scale-95"
                    onClick={() => approveMutation.mutate(selectedDriver.id)}
                    disabled={approveMutation.isPending}
                 >
                    {approveMutation.isPending ? "Processing..." : (
                        <>
                          <CheckCircle className="h-5 w-5" /> Approve Driver Profile
                        </>
                    )}
                 </Button>
              </div>
           </Card>
        </div>
      )}
    </div>
  )
}
