"use client"

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query"
import { supabase } from "@/lib/supabase"
import { cn } from "@/lib/utils"
import { useEffect, useState, useRef } from "react"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { 
  MessageSquare, 
  Search, 
  Filter, 
  Clock, 
  Headphones,
  Mail,
  Smartphone,
  CheckCircle2,
  AlertCircle,
  MoreHorizontal,
  Send,
  User,
  ChevronRight,
  Loader2
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

export default function SupportPage() {
  const queryClient = useQueryClient()
  const [selectedTicketId, setSelectedTicketId] = useState<string | null>(null)
  const [newMessage, setNewMessage] = useState("")
  const scrollRef = useRef<HTMLDivElement>(null)

  // Fetch Tickets
  const { data: tickets = [], isLoading: isLoadingTickets } = useQuery({
    queryKey: ["support_tickets"],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("support_tickets")
        .select(`
          *,
          profiles:user_id (
            full_name,
            avatar_url
          )
        `)
        .order('created_at', { ascending: false })
      if (error) throw error
      return data || []
    }
  })

  // Fetch Messages for Selected Ticket
  const { data: messages = [], isLoading: isLoadingMessages } = useQuery({
    queryKey: ["support_messages", selectedTicketId],
    queryFn: async () => {
      if (!selectedTicketId) return []
      const { data, error } = await supabase
        .from("support_messages")
        .select("*")
        .eq('ticket_id', selectedTicketId)
        .order('created_at', { ascending: true })
      if (error) throw error
      return data || []
    },
    enabled: !!selectedTicketId
  })

  // Mutations
  const sendMessageMutation = useMutation({
    mutationFn: async (content: string) => {
      if (!selectedTicketId) return
      const { error } = await supabase
        .from("support_messages")
        .insert({
          ticket_id: selectedTicketId,
          content,
          is_from_admin: true
        })
      if (error) throw error
    },
    onSuccess: () => {
      setNewMessage("")
      queryClient.invalidateQueries({ queryKey: ["support_messages", selectedTicketId] })
    }
  })

  const updateStatusMutation = useMutation({
    mutationFn: async ({ id, status }: { id: string, status: any }) => {
      const { error } = await supabase
        .from("support_tickets")
        .update({ status })
        .eq('id', id)
      if (error) throw error
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["support_tickets"] })
    }
  })

  // Real-time Sync
  useEffect(() => {
    const channel = supabase.channel('support-updates')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'support_tickets' }, () => {
        queryClient.invalidateQueries({ queryKey: ["support_tickets"] })
      })
      .on('postgres_changes', { event: '*', schema: 'public', table: 'support_messages' }, (payload) => {
        if (payload.new && (payload.new as any).ticket_id === selectedTicketId) {
          queryClient.invalidateQueries({ queryKey: ["support_messages", selectedTicketId] })
        }
      })
      .subscribe()

    return () => {
      supabase.removeChannel(channel)
    }
  }, [queryClient, selectedTicketId])

  // Scroll to bottom of chat
  useEffect(() => {
    if (scrollRef.current) {
      scrollRef.current.scrollTop = scrollRef.current.scrollHeight
    }
  }, [messages])

  const selectedTicket = tickets.find(t => t.id === selectedTicketId)

  return (
    <div className="space-y-8 animate-in transition-all h-[calc(100vh-140px)] flex flex-col">
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 shrink-0">
        <div>
          <h1 className="text-3xl font-bold tracking-tight text-slate-900">Help Desk</h1>
          <p className="text-slate-500 mt-1">Manage customer support and inquiries in real-time.</p>
        </div>
        <div className="flex items-center gap-3">
           <div className="flex items-center gap-2 px-3 py-1.5 rounded-full bg-blue-50 border border-blue-100">
              <div className="h-1.5 w-1.5 rounded-full bg-blue-500 animate-pulse" />
              <span className="text-[10px] font-bold text-blue-600 uppercase tracking-widest">{tickets.filter(t => t.status === 'open').length} Open Tickets</span>
           </div>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-4 gap-6 flex-1 min-h-0">
        {/* Ticket List */}
        <div className="lg:col-span-1 space-y-4 flex flex-col min-h-0">
           <div className="relative shrink-0">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-slate-400" />
              <Input 
                placeholder="Search..." 
                className="pl-9 h-10 rounded-xl border-slate-100 bg-white" 
              />
           </div>

           <div className="flex-1 overflow-y-auto pr-2 custom-scrollbar space-y-3">
              {isLoadingTickets && (
                <div className="flex justify-center py-10">
                   <Loader2 className="h-6 w-6 animate-spin text-slate-300" />
                </div>
              )}
              {tickets.map((ticket) => (
                <div 
                  key={ticket.id} 
                  onClick={() => setSelectedTicketId(ticket.id)}
                  className={cn(
                    "p-4 rounded-2xl border transition-all cursor-pointer group relative",
                    selectedTicketId === ticket.id 
                      ? "bg-white border-blue-200 shadow-lg ring-1 ring-blue-500/5" 
                      : "bg-white border-slate-50 hover:border-slate-200"
                  )}
                >
                   <div className="flex justify-between items-start mb-2">
                      <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider">#{ticket.id.substring(0, 8)}</span>
                      <Badge className={cn(
                        "px-1.5 py-0 rounded-full text-[8px] font-bold uppercase",
                        ticket.priority === 'urgent' ? "bg-rose-100 text-rose-700" : 
                        ticket.priority === 'high' ? "bg-amber-100 text-amber-700" : "bg-slate-100 text-slate-500"
                      )}>
                        {ticket.priority}
                      </Badge>
                   </div>
                   <h4 className="text-sm font-bold text-slate-900 group-hover:text-blue-600 transition-colors line-clamp-1">{ticket.subject}</h4>
                   <div className="flex items-center justify-between mt-3">
                      <p className="text-[10px] text-slate-400 font-medium">{(ticket.profiles as any)?.full_name || 'Anonymous'}</p>
                      <span className="text-[10px] text-slate-400 flex items-center gap-1 font-bold italic">
                         <Clock className="h-2.5 w-2.5" /> {timeAgo(ticket.created_at)}
                      </span>
                   </div>
                </div>
              ))}
              {tickets.length === 0 && !isLoadingTickets && (
                <div className="text-center py-10">
                   <p className="text-xs font-bold text-slate-400 uppercase tracking-widest">No tickets found</p>
                </div>
              )}
           </div>
        </div>

        {/* Chat / Ticket Details */}
        <div className="lg:col-span-3 flex flex-col gap-6 min-h-0">
           {selectedTicket ? (
             <Card className="flex-1 border-none shadow-2xl rounded-[2.5rem] bg-white overflow-hidden flex flex-col">
                <CardHeader className="px-8 py-6 border-b border-slate-50 shrink-0">
                   <div className="flex items-center justify-between">
                      <div className="flex items-center gap-4">
                         <div className="h-12 w-12 rounded-2xl bg-blue-50 flex items-center justify-center font-bold text-blue-600">
                            {(selectedTicket.profiles as any)?.full_name?.substring(0, 2).toUpperCase() || 'A'}
                         </div>
                         <div>
                            <CardTitle className="text-xl font-bold text-slate-900 leading-tight">{selectedTicket.subject}</CardTitle>
                            <div className="flex items-center gap-2 mt-1">
                               <span className="text-xs font-semibold text-slate-500">{(selectedTicket.profiles as any)?.full_name}</span>
                               <div className="h-1 w-1 rounded-full bg-slate-200" />
                               <span className="text-xs font-bold text-blue-600 uppercase tracking-widest text-[10px]">{selectedTicket.category}</span>
                            </div>
                         </div>
                      </div>
                      <div className="flex items-center gap-2">
                         <select 
                            value={selectedTicket.status || 'open'}
                            onChange={(e) => updateStatusMutation.mutate({ id: selectedTicket.id, status: e.target.value })}
                            className="text-xs font-bold bg-slate-50 border-none rounded-xl px-4 py-2 outline-none focus:ring-2 focus:ring-blue-100 cursor-pointer"
                         >
                            <option value="open">Open</option>
                            <option value="in_progress">In Progress</option>
                            <option value="resolved">Resolved</option>
                            <option value="closed">Closed</option>
                         </select>
                         <Button variant="ghost" size="icon" className="h-10 w-10 rounded-xl hover:bg-slate-50 text-slate-400">
                            <MoreHorizontal className="h-5 w-5" />
                         </Button>
                      </div>
                   </div>
                </CardHeader>

                <CardContent className="p-0 flex-1 overflow-hidden flex flex-col">
                   <div 
                      ref={scrollRef}
                      className="flex-1 overflow-y-auto px-8 py-10 space-y-6 custom-scrollbar bg-slate-50/30"
                   >
                      {messages.map((msg) => (
                        <div 
                          key={msg.id} 
                          className={cn(
                            "flex flex-col max-w-[80%]",
                            msg.is_from_admin ? "ml-auto items-end" : "mr-auto items-start"
                          )}
                        >
                           <div className={cn(
                             "px-5 py-3.5 rounded-[1.5rem] shadow-sm text-sm font-medium leading-relaxed tracking-tight",
                             msg.is_from_admin 
                               ? "bg-slate-900 text-white rounded-tr-none" 
                               : "bg-white border border-slate-100 text-slate-800 rounded-tl-none"
                           )}>
                              {msg.content}
                           </div>
                           <span className="mt-1.5 px-1 text-[10px] font-bold text-slate-400 flex items-center gap-1 uppercase tracking-wider">
                              <Clock className="h-2.5 w-2.5" />
                              {timeAgo(msg.created_at)}
                           </span>
                        </div>
                      ))}
                      {messages.length === 0 && !isLoadingMessages && (
                        <div className="flex flex-col items-center justify-center py-20 text-center">
                           <div className="h-16 w-16 bg-blue-50 rounded-3xl flex items-center justify-center mb-4 border border-blue-100">
                              <MessageSquare className="h-8 w-8 text-blue-500" />
                           </div>
                           <h4 className="text-lg font-bold text-slate-900">Start the conversation</h4>
                           <p className="text-slate-500 text-xs mt-1 max-w-[240px]">Send a message to update the user about their support ticket status.</p>
                        </div>
                      )}
                   </div>

                   <div className="p-8 border-t border-slate-50 bg-white shrink-0">
                      <div className="relative">
                         <Input 
                            value={newMessage}
                            onChange={(e) => setNewMessage(e.target.value)}
                            placeholder="Type your response here..." 
                            className="h-14 pl-6 pr-16 rounded-2xl border-slate-100 bg-slate-50/50 shadow-inner font-medium focus-visible:ring-blue-500/10"
                            onKeyDown={(e) => e.key === 'Enter' && sendMessageMutation.mutate(newMessage)}
                         />
                         <Button 
                            onClick={() => sendMessageMutation.mutate(newMessage)}
                            disabled={!newMessage.trim() || sendMessageMutation.isPending}
                            className="absolute right-2 top-1/2 -translate-y-1/2 h-10 w-10 p-0 rounded-xl bg-blue-600 hover:bg-blue-700 shadow-lg shadow-blue-500/20"
                         >
                            {sendMessageMutation.isPending ? <Loader2 className="h-4 w-4 animate-spin" /> : <Send className="h-4 w-4" />}
                         </Button>
                      </div>
                   </div>
                </CardContent>
             </Card>
           ) : (
             <div className="flex-1 flex flex-col items-center justify-center bg-slate-50/40 rounded-[2.5rem] border border-dashed border-slate-200">
                <div className="h-24 w-24 bg-white rounded-[2rem] shadow-xl flex items-center justify-center mb-6 border border-slate-100">
                   <Headphones className="h-10 w-10 text-slate-300" />
                </div>
                <h3 className="text-2xl font-bold text-slate-900 tracking-tight">Select a Ticket</h3>
                <p className="text-slate-500 max-w-xs text-center mt-2 leading-relaxed">Choose a ticket from the sidebar to view details and start responding to users.</p>
             </div>
           )}
        </div>
      </div>
    </div>
  )
}
