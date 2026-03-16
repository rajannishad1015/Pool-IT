export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  // Allows to automatically instantiate createClient with right options
  // instead of createClient<Database, { PostgrestVersion: 'XX' }>(URL, KEY)
  __InternalSupabase: {
    PostgrestVersion: "14.4"
  }
  public: {
    Tables: {
      admin_profiles: {
        Row: {
          created_at: string | null
          full_name: string
          id: string
          role: Database["public"]["Enums"]["adimn_role"]
          updated_at: string | null
        }
        Insert: {
          created_at?: string | null
          full_name: string
          id: string
          role?: Database["public"]["Enums"]["adimn_role"]
          updated_at?: string | null
        }
        Update: {
          created_at?: string | null
          full_name?: string
          id?: string
          role?: Database["public"]["Enums"]["adimn_role"]
          updated_at?: string | null
        }
        Relationships: []
      }
      bank_details: {
        Row: {
          account_holder_name: string
          account_number: string
          bank_name: string | null
          created_at: string | null
          id: string
          ifsc_code: string
          updated_at: string | null
          user_id: string | null
        }
        Insert: {
          account_holder_name: string
          account_number: string
          bank_name?: string | null
          created_at?: string | null
          id?: string
          ifsc_code: string
          updated_at?: string | null
          user_id?: string | null
        }
        Update: {
          account_holder_name?: string
          account_number?: string
          bank_name?: string | null
          created_at?: string | null
          id?: string
          ifsc_code?: string
          updated_at?: string | null
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "bank_details_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      bookings: {
        Row: {
          created_at: string | null
          fare_paid: number
          id: string
          passenger_id: string | null
          pickup_lat_lng: unknown
          pickup_location_name: string | null
          ride_id: string | null
          seats_booked: number | null
          status: string | null
        }
        Insert: {
          created_at?: string | null
          fare_paid: number
          id?: string
          passenger_id?: string | null
          pickup_lat_lng?: unknown
          pickup_location_name?: string | null
          ride_id?: string | null
          seats_booked?: number | null
          status?: string | null
        }
        Update: {
          created_at?: string | null
          fare_paid?: number
          id?: string
          passenger_id?: string | null
          pickup_lat_lng?: unknown
          pickup_location_name?: string | null
          ride_id?: string | null
          seats_booked?: number | null
          status?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "bookings_passenger_id_fkey"
            columns: ["passenger_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "bookings_ride_id_fkey"
            columns: ["ride_id"]
            isOneToOne: false
            referencedRelation: "rides"
            referencedColumns: ["id"]
          },
        ]
      }
      driver_documents: {
        Row: {
          created_at: string | null
          doc_type: Database["public"]["Enums"]["document_type"]
          driver_id: string | null
          expiry_date: string | null
          file_path: string
          id: string
          metadata: Json | null
          rejection_reason: string | null
          status: Database["public"]["Enums"]["verification_status"]
          updated_at: string | null
        }
        Insert: {
          created_at?: string | null
          doc_type: Database["public"]["Enums"]["document_type"]
          driver_id?: string | null
          expiry_date?: string | null
          file_path: string
          id?: string
          metadata?: Json | null
          rejection_reason?: string | null
          status?: Database["public"]["Enums"]["verification_status"]
          updated_at?: string | null
        }
        Update: {
          created_at?: string | null
          doc_type?: Database["public"]["Enums"]["document_type"]
          driver_id?: string | null
          expiry_date?: string | null
          file_path?: string
          id?: string
          metadata?: Json | null
          rejection_reason?: string | null
          status?: Database["public"]["Enums"]["verification_status"]
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "driver_documents_driver_id_fkey"
            columns: ["driver_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      drivers: {
        Row: {
          aadhaar_number: string | null
          created_at: string | null
          dl_number: string | null
          id: string
          is_online: boolean | null
          last_online_at: string | null
          strikes: number | null
          total_earnings: number | null
          updated_at: string | null
          verification_status: Database["public"]["Enums"]["verification_status"]
        }
        Insert: {
          aadhaar_number?: string | null
          created_at?: string | null
          dl_number?: string | null
          id: string
          is_online?: boolean | null
          last_online_at?: string | null
          strikes?: number | null
          total_earnings?: number | null
          updated_at?: string | null
          verification_status?: Database["public"]["Enums"]["verification_status"]
        }
        Update: {
          aadhaar_number?: string | null
          created_at?: string | null
          dl_number?: string | null
          id?: string
          is_online?: boolean | null
          last_online_at?: string | null
          strikes?: number | null
          total_earnings?: number | null
          updated_at?: string | null
          verification_status?: Database["public"]["Enums"]["verification_status"]
        }
        Relationships: [
          {
            foreignKeyName: "drivers_id_fkey"
            columns: ["id"]
            isOneToOne: true
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      emergency_contacts: {
        Row: {
          auto_share: boolean | null
          id: string
          name: string
          phone_number: string
          relationship: string | null
          user_id: string | null
        }
        Insert: {
          auto_share?: boolean | null
          id?: string
          name: string
          phone_number: string
          relationship?: string | null
          user_id?: string | null
        }
        Update: {
          auto_share?: boolean | null
          id?: string
          name?: string
          phone_number?: string
          relationship?: string | null
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "emergency_contacts_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      profiles: {
        Row: {
          avatar_url: string | null
          created_at: string | null
          date_of_birth: string | null
          full_name: string | null
          gender: string | null
          home_lat_lng: unknown
          home_location_name: string | null
          id: string
          is_verified: boolean | null
          last_lat_lng: unknown
          phone_number: string | null
          trust_score: number | null
          updated_at: string | null
          work_lat_lng: unknown
          work_location_name: string | null
        }
        Insert: {
          avatar_url?: string | null
          created_at?: string | null
          date_of_birth?: string | null
          full_name?: string | null
          gender?: string | null
          home_lat_lng?: unknown
          home_location_name?: string | null
          id: string
          is_verified?: boolean | null
          last_lat_lng?: unknown
          phone_number?: string | null
          trust_score?: number | null
          updated_at?: string | null
          work_lat_lng?: unknown
          work_location_name?: string | null
        }
        Update: {
          avatar_url?: string | null
          created_at?: string | null
          date_of_birth?: string | null
          full_name?: string | null
          gender?: string | null
          home_lat_lng?: unknown
          home_location_name?: string | null
          id?: string
          is_verified?: boolean | null
          last_lat_lng?: unknown
          phone_number?: string | null
          trust_score?: number | null
          updated_at?: string | null
          work_lat_lng?: unknown
          work_location_name?: string | null
        }
        Relationships: []
      }
      rides: {
        Row: {
          base_fare: number
          created_at: string | null
          departure_time: string
          destination_lat_lng: unknown
          destination_name: string
          detour_max_km: number | null
          driver_id: string | null
          id: string
          origin_lat_lng: unknown
          origin_name: string
          preferences: Json | null
          seats_available: number
          seats_total: number
          status: string | null
          vehicle_id: string | null
        }
        Insert: {
          base_fare: number
          created_at?: string | null
          departure_time: string
          destination_lat_lng: unknown
          destination_name: string
          detour_max_km?: number | null
          driver_id?: string | null
          id?: string
          origin_lat_lng: unknown
          origin_name: string
          preferences?: Json | null
          seats_available: number
          seats_total: number
          status?: string | null
          vehicle_id?: string | null
        }
        Update: {
          base_fare?: number
          created_at?: string | null
          departure_time?: string
          destination_lat_lng?: unknown
          destination_name?: string
          detour_max_km?: number | null
          driver_id?: string | null
          id?: string
          origin_lat_lng?: unknown
          origin_name?: string
          preferences?: Json | null
          seats_available?: number
          seats_total?: number
          status?: string | null
          vehicle_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "rides_driver_id_fkey"
            columns: ["driver_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "rides_vehicle_id_fkey"
            columns: ["vehicle_id"]
            isOneToOne: false
            referencedRelation: "vehicles"
            referencedColumns: ["id"]
          },
        ]
      }
      safety_incidents: {
        Row: {
          id: string
          created_at: string | null
          user_id: string | null
          ride_id: string | null
          type: string
          priority: Database["public"]["Enums"]["incident_priority"] | null
          status: Database["public"]["Enums"]["incident_status"] | null
          location_name: string | null
          description: string | null
          resolved_at: string | null
          resolved_by: string | null
        }
        Insert: {
          id?: string
          created_at?: string | null
          user_id?: string | null
          ride_id?: string | null
          type: string
          priority?: Database["public"]["Enums"]["incident_priority"] | null
          status?: Database["public"]["Enums"]["incident_status"] | null
          location_name?: string | null
          description?: string | null
          resolved_at?: string | null
          resolved_by?: string | null
        }
        Update: {
          id?: string
          created_at?: string | null
          user_id?: string | null
          ride_id?: string | null
          type?: string
          priority?: Database["public"]["Enums"]["incident_priority"] | null
          status?: Database["public"]["Enums"]["incident_status"] | null
          location_name?: string | null
          description?: string | null
          resolved_at?: string | null
          resolved_by?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "safety_incidents_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "safety_incidents_ride_id_fkey"
            columns: ["ride_id"]
            isOneToOne: false
            referencedRelation: "rides"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "safety_incidents_resolved_by_fkey"
            columns: ["resolved_by"]
            isOneToOne: false
            referencedRelation: "admin_profiles"
            referencedColumns: ["id"]
          }
        ]
      }
      support_tickets: {
        Row: {
          id: string
          created_at: string | null
          user_id: string | null
          subject: string
          category: string | null
          priority: Database["public"]["Enums"]["ticket_priority"] | null
          status: Database["public"]["Enums"]["ticket_status"] | null
          assigned_to: string | null
        }
        Insert: {
          id?: string
          created_at?: string | null
          user_id?: string | null
          subject: string
          category?: string | null
          priority?: Database["public"]["Enums"]["ticket_priority"] | null
          status?: Database["public"]["Enums"]["ticket_status"] | null
          assigned_to?: string | null
        }
        Update: {
          id?: string
          created_at?: string | null
          user_id?: string | null
          subject?: string
          category?: string | null
          priority?: Database["public"]["Enums"]["ticket_priority"] | null
          status?: Database["public"]["Enums"]["ticket_status"] | null
          assigned_to?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "support_tickets_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "support_tickets_assigned_to_fkey"
            columns: ["assigned_to"]
            isOneToOne: false
            referencedRelation: "admin_profiles"
            referencedColumns: ["id"]
          }
        ]
      }
      support_messages: {
        Row: {
          id: string
          created_at: string | null
          ticket_id: string | null
          sender_id: string | null
          content: string
          is_from_admin: boolean | null
        }
        Insert: {
          id?: string
          created_at?: string | null
          ticket_id?: string | null
          sender_id?: string | null
          content: string
          is_from_admin?: boolean | null
        }
        Update: {
          id?: string
          created_at?: string | null
          ticket_id?: string | null
          sender_id?: string | null
          content?: string
          is_from_admin?: boolean | null
        }
        Relationships: [
          {
            foreignKeyName: "support_messages_ticket_id_fkey"
            columns: ["ticket_id"]
            isOneToOne: false
            referencedRelation: "support_tickets"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "support_messages_sender_id_fkey"
            columns: ["sender_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          }
        ]
      }
      transactions: {
        Row: {
          amount: number
          created_at: string | null
          description: string | null
          id: string
          type: string | null
          wallet_id: string | null
        }
        Insert: {
          amount: number
          created_at?: string | null
          description?: string | null
          id?: string
          type?: string | null
          wallet_id?: string | null
        }
        Update: {
          amount?: number
          created_at?: string | null
          description?: string | null
          id?: string
          type?: string | null
          wallet_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "transactions_wallet_id_fkey"
            columns: ["wallet_id"]
            isOneToOne: false
            referencedRelation: "wallets"
            referencedColumns: ["user_id"]
          },
        ]
      }
      vehicles: {
        Row: {
          color: string
          created_at: string | null
          id: string
          is_ac: boolean | null
          make: string
          model: string
          owner_id: string | null
          photo_url: string | null
          plate_number: string
          status: Database["public"]["Enums"]["verification_status"] | null
        }
        Insert: {
          color: string
          created_at?: string | null
          id?: string
          is_ac?: boolean | null
          make: string
          model: string
          owner_id?: string | null
          photo_url?: string | null
          plate_number: string
          status?: Database["public"]["Enums"]["verification_status"] | null
        }
        Update: {
          color?: string
          created_at?: string | null
          id?: string
          is_ac?: boolean | null
          make?: string
          model?: string
          owner_id?: string | null
          photo_url?: string | null
          plate_number?: string
          status?: Database["public"]["Enums"]["verification_status"] | null
        }
        Relationships: [
          {
            foreignKeyName: "vehicles_owner_id_fkey"
            columns: ["owner_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      wallets: {
        Row: {
          balance: number | null
          updated_at: string | null
          user_id: string
        }
        Insert: {
          balance?: number | null
          updated_at?: string | null
          user_id: string
        }
        Update: {
          balance?: number | null
          updated_at?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "wallets_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: true
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      is_admin: { Args: never; Returns: boolean }
    }
    Enums: {
      adimn_role:
        | "super_admin"
        | "ops_manager"
        | "document_reviewer"
        | "safety_officer"
        | "finance_admin"
        | "support_agent"
        | "marketing_admin"
        | "analyst"
      document_type:
        | "aadhaar_front"
        | "aadhaar_back"
        | "dl"
        | "rc"
        | "insurance"
        | "puc"
        | "vehicle_photo"
      incident_priority: "critical" | "high" | "medium" | "low"
      incident_status: "active" | "investigating" | "resolved"
      ticket_priority: "low" | "medium" | "high" | "urgent"
      ticket_status: "open" | "in_progress" | "resolved" | "closed"
      verification_status: "unverified" | "pending" | "verified" | "rejected"
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}
