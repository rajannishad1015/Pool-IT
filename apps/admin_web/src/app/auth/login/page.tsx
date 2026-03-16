"use client"

import { useState } from "react"
import { useRouter } from "next/navigation"
import { createClient } from "@/lib/supabase/client"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Shield, Lock, Mail, ArrowRight, Loader2 } from "lucide-react"

export default function LoginPage() {
  const router = useRouter()
  const supabase = createClient()
  const [email, setEmail] = useState("")
  const [password, setPassword] = useState("")
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault()
    setLoading(true)
    setError(null)

    try {
      console.log("Attempting login for:", email)
      const { data, error } = await supabase.auth.signInWithPassword({
        email,
        password,
      })

      if (error) {
        console.error("Login error:", error)
        throw error
      }
      
      console.log("Login successful, refreshing router...")
      // Refresh the router to ensure cookies are picked up by the middleware
      router.refresh()
      
      // Give a small delay for cookies to propagate before redirecting
      setTimeout(() => {
        router.push("/")
      }, 100)
    } catch (err: any) {
      console.error("Login catch block:", err)
      setError(err.message || "Invalid credentials")
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen w-full flex items-center justify-center bg-slate-900 overflow-hidden relative">
      {/* Background Decorative Elements */}
      <div className="absolute top-0 left-0 w-full h-full">
        <div className="absolute top-[-10%] left-[-10%] w-[40%] h-[40%] bg-blue-600/20 rounded-full blur-[120px]" />
        <div className="absolute bottom-[-10%] right-[-10%] w-[40%] h-[40%] bg-indigo-600/20 rounded-full blur-[120px]" />
      </div>

      <div className="relative z-10 w-full max-w-md px-6 animate-in">
        <div className="flex flex-col items-center mb-10">
          <div className="h-14 w-14 bg-blue-600 rounded-xl flex items-center justify-center shadow-lg mb-6">
            <Shield className="h-7 w-7 text-white" />
          </div>
          <h1 className="text-2xl font-bold text-white tracking-tight">SmartPool Admin</h1>
          <p className="text-slate-400 mt-1 text-sm">Secure Management Portal</p>
        </div>

        <Card className="border-slate-800 bg-slate-900/80 backdrop-blur-xl shadow-2xl rounded-2xl overflow-hidden">
          <CardHeader className="pt-8 pb-4 px-8">
            <CardTitle className="text-lg font-semibold text-white text-center">Admin Login</CardTitle>
          </CardHeader>
          <CardContent className="px-8 pb-8 space-y-6">
            <form onSubmit={handleLogin} className="space-y-4">
              <div className="space-y-2">
                <Label className="text-xs font-medium text-slate-400 ml-1">Email Address</Label>
                <div className="relative group">
                  <Mail className="absolute left-4 top-1/2 -translate-y-1/2 h-4 w-4 text-slate-500 group-focus-within:text-blue-500 transition-colors" />
                  <Input 
                    type="email" 
                    placeholder="admin@smartpool.com" 
                    className="h-12 pl-12 pr-4 rounded-xl bg-slate-800/50 border-slate-700 text-white placeholder:text-slate-600 focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    required
                  />
                </div>
              </div>

              <div className="space-y-2">
                <Label className="text-xs font-medium text-slate-400 ml-1">Password</Label>
                <div className="relative group">
                  <Lock className="absolute left-4 top-1/2 -translate-y-1/2 h-4 w-4 text-slate-500 group-focus-within:text-blue-500 transition-colors" />
                  <Input 
                    type="password" 
                    placeholder="••••••••" 
                    className="h-12 pl-12 pr-4 rounded-xl bg-slate-800/50 border-slate-700 text-white placeholder:text-slate-600 focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all"
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    required
                  />
                </div>
              </div>

              {error && (
                <div className="px-4 py-3 bg-red-500/10 border border-red-500/20 rounded-lg text-xs font-medium text-red-500 text-center">
                  {error}
                </div>
              )}

              <Button 
                type="submit"
                disabled={loading}
                className="w-full h-12 bg-blue-600 hover:bg-blue-700 text-white rounded-xl font-semibold transition-all group"
              >
                {loading ? (
                  <Loader2 className="h-5 w-5 animate-spin" />
                ) : (
                  <>
                    Login
                    <ArrowRight className="h-4 w-4 ml-2 group-hover:translate-x-1 transition-transform" />
                  </>
                )}
              </Button>
            </form>

            <div className="pt-2 text-center">
              <button disabled className="text-xs font-medium text-slate-500 hover:text-slate-300 transition-colors">
                Forgot Password?
              </button>
            </div>
          </CardContent>
        </Card>

        <p className="text-center mt-10 text-[10px] uppercase font-bold tracking-[0.2em] text-slate-600">
          SmartPool Admin • Version 2.4.0
        </p>
      </div>
    </div>
  )
}
