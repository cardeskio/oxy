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
    PostgrestVersion: "14.1"
  }
  public: {
    Tables: {
      audit_logs: {
        Row: {
          action: string
          actor_user_id: string | null
          created_at: string
          entity_id: string
          entity_type: string
          id: string
          metadata_json: Json | null
          org_id: string
        }
        Insert: {
          action: string
          actor_user_id?: string | null
          created_at?: string
          entity_id: string
          entity_type: string
          id?: string
          metadata_json?: Json | null
          org_id: string
        }
        Update: {
          action?: string
          actor_user_id?: string | null
          created_at?: string
          entity_id?: string
          entity_type?: string
          id?: string
          metadata_json?: Json | null
          org_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "audit_logs_actor_user_id_fkey"
            columns: ["actor_user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "audit_logs_org_id_fkey"
            columns: ["org_id"]
            isOneToOne: false
            referencedRelation: "orgs"
            referencedColumns: ["id"]
          },
        ]
      }
      charge_types: {
        Row: {
          created_at: string
          default_amount: number | null
          id: string
          is_recurring: boolean
          name: string
          org_id: string
          updated_at: string
        }
        Insert: {
          created_at?: string
          default_amount?: number | null
          id?: string
          is_recurring?: boolean
          name: string
          org_id: string
          updated_at?: string
        }
        Update: {
          created_at?: string
          default_amount?: number | null
          id?: string
          is_recurring?: boolean
          name?: string
          org_id?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "charge_types_org_id_fkey"
            columns: ["org_id"]
            isOneToOne: false
            referencedRelation: "orgs"
            referencedColumns: ["id"]
          },
        ]
      }
      documents: {
        Row: {
          created_at: string
          entity_id: string
          entity_type: string
          file_name: string
          id: string
          mime_type: string
          org_id: string
          storage_path: string
          uploaded_by: string | null
        }
        Insert: {
          created_at?: string
          entity_id: string
          entity_type: string
          file_name: string
          id?: string
          mime_type: string
          org_id: string
          storage_path: string
          uploaded_by?: string | null
        }
        Update: {
          created_at?: string
          entity_id?: string
          entity_type?: string
          file_name?: string
          id?: string
          mime_type?: string
          org_id?: string
          storage_path?: string
          uploaded_by?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "documents_org_id_fkey"
            columns: ["org_id"]
            isOneToOne: false
            referencedRelation: "orgs"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "documents_uploaded_by_fkey"
            columns: ["uploaded_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      invoice_lines: {
        Row: {
          amount: number
          balance_amount: number
          charge_type: string
          charge_type_id: string | null
          description: string
          id: string
          invoice_id: string
          org_id: string | null
        }
        Insert: {
          amount: number
          balance_amount: number
          charge_type: string
          charge_type_id?: string | null
          description: string
          id?: string
          invoice_id: string
          org_id?: string | null
        }
        Update: {
          amount?: number
          balance_amount?: number
          charge_type?: string
          charge_type_id?: string | null
          description?: string
          id?: string
          invoice_id?: string
          org_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "invoice_lines_charge_type_id_fkey"
            columns: ["charge_type_id"]
            isOneToOne: false
            referencedRelation: "charge_types"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "invoice_lines_invoice_id_fkey"
            columns: ["invoice_id"]
            isOneToOne: false
            referencedRelation: "invoices"
            referencedColumns: ["id"]
          },
        ]
      }
      invoices: {
        Row: {
          balance_amount: number
          created_at: string
          due_date: string
          id: string
          lease_id: string
          org_id: string | null
          period_end: string
          period_start: string
          property_id: string
          status: string
          tenant_id: string
          total_amount: number
          unit_id: string
          updated_at: string
        }
        Insert: {
          balance_amount: number
          created_at?: string
          due_date: string
          id?: string
          lease_id: string
          org_id?: string | null
          period_end: string
          period_start: string
          property_id: string
          status?: string
          tenant_id: string
          total_amount: number
          unit_id: string
          updated_at?: string
        }
        Update: {
          balance_amount?: number
          created_at?: string
          due_date?: string
          id?: string
          lease_id?: string
          org_id?: string | null
          period_end?: string
          period_start?: string
          property_id?: string
          status?: string
          tenant_id?: string
          total_amount?: number
          unit_id?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "invoices_lease_id_fkey"
            columns: ["lease_id"]
            isOneToOne: false
            referencedRelation: "leases"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "invoices_property_id_fkey"
            columns: ["property_id"]
            isOneToOne: false
            referencedRelation: "properties"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "invoices_tenant_id_fkey"
            columns: ["tenant_id"]
            isOneToOne: false
            referencedRelation: "tenants"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "invoices_unit_id_fkey"
            columns: ["unit_id"]
            isOneToOne: false
            referencedRelation: "units"
            referencedColumns: ["id"]
          },
        ]
      }
      leases: {
        Row: {
          created_at: string
          deposit_amount: number
          due_day: number
          end_date: string | null
          grace_days: number
          id: string
          late_fee_type: string
          late_fee_value: number | null
          move_in_notes: string | null
          move_out_notes: string | null
          org_id: string | null
          property_id: string
          rent_amount: number
          start_date: string
          status: string
          tenant_id: string
          unit_id: string
          updated_at: string
        }
        Insert: {
          created_at?: string
          deposit_amount: number
          due_day: number
          end_date?: string | null
          grace_days?: number
          id?: string
          late_fee_type?: string
          late_fee_value?: number | null
          move_in_notes?: string | null
          move_out_notes?: string | null
          org_id?: string | null
          property_id: string
          rent_amount: number
          start_date: string
          status?: string
          tenant_id: string
          unit_id: string
          updated_at?: string
        }
        Update: {
          created_at?: string
          deposit_amount?: number
          due_day?: number
          end_date?: string | null
          grace_days?: number
          id?: string
          late_fee_type?: string
          late_fee_value?: number | null
          move_in_notes?: string | null
          move_out_notes?: string | null
          org_id?: string | null
          property_id?: string
          rent_amount?: number
          start_date?: string
          status?: string
          tenant_id?: string
          unit_id?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "leases_property_id_fkey"
            columns: ["property_id"]
            isOneToOne: false
            referencedRelation: "properties"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "leases_tenant_id_fkey"
            columns: ["tenant_id"]
            isOneToOne: false
            referencedRelation: "tenants"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "leases_unit_id_fkey"
            columns: ["unit_id"]
            isOneToOne: false
            referencedRelation: "units"
            referencedColumns: ["id"]
          },
        ]
      }
      maintenance_costs: {
        Row: {
          amount: number
          id: string
          item: string
          notes: string | null
          org_id: string | null
          ticket_id: string
        }
        Insert: {
          amount: number
          id?: string
          item: string
          notes?: string | null
          org_id?: string | null
          ticket_id: string
        }
        Update: {
          amount?: number
          id?: string
          item?: string
          notes?: string | null
          org_id?: string | null
          ticket_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "maintenance_costs_ticket_id_fkey"
            columns: ["ticket_id"]
            isOneToOne: false
            referencedRelation: "maintenance_tickets"
            referencedColumns: ["id"]
          },
        ]
      }
      maintenance_tickets: {
        Row: {
          assigned_to_user_id: string | null
          created_at: string
          description: string
          id: string
          lease_id: string | null
          org_id: string | null
          priority: string
          property_id: string
          resolved_at: string | null
          status: string
          tenant_id: string | null
          title: string
          unit_id: string
          updated_at: string
          vendor_id: string | null
          vendor_name: string | null
        }
        Insert: {
          assigned_to_user_id?: string | null
          created_at?: string
          description: string
          id?: string
          lease_id?: string | null
          org_id?: string | null
          priority?: string
          property_id: string
          resolved_at?: string | null
          status?: string
          tenant_id?: string | null
          title: string
          unit_id: string
          updated_at?: string
          vendor_id?: string | null
          vendor_name?: string | null
        }
        Update: {
          assigned_to_user_id?: string | null
          created_at?: string
          description?: string
          id?: string
          lease_id?: string | null
          org_id?: string | null
          priority?: string
          property_id?: string
          resolved_at?: string | null
          status?: string
          tenant_id?: string | null
          title?: string
          unit_id?: string
          updated_at?: string
          vendor_id?: string | null
          vendor_name?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "fk_maintenance_tickets_vendor"
            columns: ["vendor_id"]
            isOneToOne: false
            referencedRelation: "vendors"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "maintenance_tickets_lease_id_fkey"
            columns: ["lease_id"]
            isOneToOne: false
            referencedRelation: "leases"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "maintenance_tickets_property_id_fkey"
            columns: ["property_id"]
            isOneToOne: false
            referencedRelation: "properties"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "maintenance_tickets_tenant_id_fkey"
            columns: ["tenant_id"]
            isOneToOne: false
            referencedRelation: "tenants"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "maintenance_tickets_unit_id_fkey"
            columns: ["unit_id"]
            isOneToOne: false
            referencedRelation: "units"
            referencedColumns: ["id"]
          },
        ]
      }
      notification_outbox: {
        Row: {
          channel: string
          created_at: string
          id: string
          last_error: string | null
          org_id: string
          payload_json: Json
          recipient: string
          scheduled_at: string | null
          sent_at: string | null
          status: string
          template_key: string
          updated_at: string
        }
        Insert: {
          channel: string
          created_at?: string
          id?: string
          last_error?: string | null
          org_id: string
          payload_json?: Json
          recipient: string
          scheduled_at?: string | null
          sent_at?: string | null
          status?: string
          template_key: string
          updated_at?: string
        }
        Update: {
          channel?: string
          created_at?: string
          id?: string
          last_error?: string | null
          org_id?: string
          payload_json?: Json
          recipient?: string
          scheduled_at?: string | null
          sent_at?: string | null
          status?: string
          template_key?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "notification_outbox_org_id_fkey"
            columns: ["org_id"]
            isOneToOne: false
            referencedRelation: "orgs"
            referencedColumns: ["id"]
          },
        ]
      }
      org_members: {
        Row: {
          created_at: string
          id: string
          org_id: string
          role: string
          updated_at: string
          user_id: string
        }
        Insert: {
          created_at?: string
          id?: string
          org_id: string
          role: string
          updated_at?: string
          user_id: string
        }
        Update: {
          created_at?: string
          id?: string
          org_id?: string
          role?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "org_members_org_id_fkey"
            columns: ["org_id"]
            isOneToOne: false
            referencedRelation: "orgs"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "org_members_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      orgs: {
        Row: {
          country: string
          created_at: string
          id: string
          name: string
          updated_at: string
        }
        Insert: {
          country?: string
          created_at?: string
          id?: string
          name: string
          updated_at?: string
        }
        Update: {
          country?: string
          created_at?: string
          id?: string
          name?: string
          updated_at?: string
        }
        Relationships: []
      }
      payment_allocations: {
        Row: {
          amount_allocated: number
          id: string
          invoice_id: string
          invoice_line_id: string
          org_id: string | null
          payment_id: string
        }
        Insert: {
          amount_allocated: number
          id?: string
          invoice_id: string
          invoice_line_id: string
          org_id?: string | null
          payment_id: string
        }
        Update: {
          amount_allocated?: number
          id?: string
          invoice_id?: string
          invoice_line_id?: string
          org_id?: string | null
          payment_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "payment_allocations_invoice_id_fkey"
            columns: ["invoice_id"]
            isOneToOne: false
            referencedRelation: "invoices"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "payment_allocations_invoice_line_id_fkey"
            columns: ["invoice_line_id"]
            isOneToOne: false
            referencedRelation: "invoice_lines"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "payment_allocations_payment_id_fkey"
            columns: ["payment_id"]
            isOneToOne: false
            referencedRelation: "payments"
            referencedColumns: ["id"]
          },
        ]
      }
      payments: {
        Row: {
          amount: number
          captured_by: string
          created_at: string
          id: string
          lease_id: string | null
          method: string
          notes: string | null
          org_id: string | null
          paid_at: string
          reference: string
          status: string
          tenant_id: string | null
          unit_id: string | null
          updated_at: string
        }
        Insert: {
          amount: number
          captured_by: string
          created_at?: string
          id?: string
          lease_id?: string | null
          method: string
          notes?: string | null
          org_id?: string | null
          paid_at: string
          reference: string
          status?: string
          tenant_id?: string | null
          unit_id?: string | null
          updated_at?: string
        }
        Update: {
          amount?: number
          captured_by?: string
          created_at?: string
          id?: string
          lease_id?: string | null
          method?: string
          notes?: string | null
          org_id?: string | null
          paid_at?: string
          reference?: string
          status?: string
          tenant_id?: string | null
          unit_id?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "payments_lease_id_fkey"
            columns: ["lease_id"]
            isOneToOne: false
            referencedRelation: "leases"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "payments_tenant_id_fkey"
            columns: ["tenant_id"]
            isOneToOne: false
            referencedRelation: "tenants"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "payments_unit_id_fkey"
            columns: ["unit_id"]
            isOneToOne: false
            referencedRelation: "units"
            referencedColumns: ["id"]
          },
        ]
      }
      profiles: {
        Row: {
          avatar_url: string | null
          created_at: string
          email: string | null
          full_name: string
          id: string
          phone: string | null
          updated_at: string
        }
        Insert: {
          avatar_url?: string | null
          created_at?: string
          email?: string | null
          full_name: string
          id: string
          phone?: string | null
          updated_at?: string
        }
        Update: {
          avatar_url?: string | null
          created_at?: string
          email?: string | null
          full_name?: string
          id?: string
          phone?: string | null
          updated_at?: string
        }
        Relationships: []
      }
      properties: {
        Row: {
          created_at: string
          id: string
          location_text: string
          name: string
          notes: string | null
          org_id: string | null
          type: string
          updated_at: string
        }
        Insert: {
          created_at?: string
          id?: string
          location_text: string
          name: string
          notes?: string | null
          org_id?: string | null
          type: string
          updated_at?: string
        }
        Update: {
          created_at?: string
          id?: string
          location_text?: string
          name?: string
          notes?: string | null
          org_id?: string | null
          type?: string
          updated_at?: string
        }
        Relationships: []
      }
      tenant_user_links: {
        Row: {
          created_at: string
          id: string
          org_id: string | null
          tenant_id: string
          user_id: string
        }
        Insert: {
          created_at?: string
          id?: string
          org_id?: string | null
          tenant_id: string
          user_id: string
        }
        Update: {
          created_at?: string
          id?: string
          org_id?: string | null
          tenant_id?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "fk_tenant_user_links_tenant"
            columns: ["tenant_id"]
            isOneToOne: false
            referencedRelation: "tenants"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "tenant_user_links_org_id_fkey"
            columns: ["org_id"]
            isOneToOne: false
            referencedRelation: "orgs"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "tenant_user_links_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      tenants: {
        Row: {
          created_at: string
          email: string | null
          full_name: string
          id: string
          id_number: string | null
          next_of_kin_name: string | null
          next_of_kin_phone: string | null
          org_id: string | null
          phone: string
          updated_at: string
        }
        Insert: {
          created_at?: string
          email?: string | null
          full_name: string
          id?: string
          id_number?: string | null
          next_of_kin_name?: string | null
          next_of_kin_phone?: string | null
          org_id?: string | null
          phone: string
          updated_at?: string
        }
        Update: {
          created_at?: string
          email?: string | null
          full_name?: string
          id?: string
          id_number?: string | null
          next_of_kin_name?: string | null
          next_of_kin_phone?: string | null
          org_id?: string | null
          phone?: string
          updated_at?: string
        }
        Relationships: []
      }
      unit_types: {
        Row: {
          created_at: string
          default_deposit_amount: number | null
          default_rent_amount: number | null
          id: string
          name: string
          org_id: string
          updated_at: string
        }
        Insert: {
          created_at?: string
          default_deposit_amount?: number | null
          default_rent_amount?: number | null
          id?: string
          name: string
          org_id: string
          updated_at?: string
        }
        Update: {
          created_at?: string
          default_deposit_amount?: number | null
          default_rent_amount?: number | null
          id?: string
          name?: string
          org_id?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "unit_types_org_id_fkey"
            columns: ["org_id"]
            isOneToOne: false
            referencedRelation: "orgs"
            referencedColumns: ["id"]
          },
        ]
      }
      units: {
        Row: {
          created_at: string
          deposit_amount: number
          id: string
          meter_ref_power: string | null
          meter_ref_water: string | null
          org_id: string | null
          property_id: string
          rent_amount: number
          status: string
          unit_label: string
          unit_type: string | null
          unit_type_id: string | null
          updated_at: string
        }
        Insert: {
          created_at?: string
          deposit_amount: number
          id?: string
          meter_ref_power?: string | null
          meter_ref_water?: string | null
          org_id?: string | null
          property_id: string
          rent_amount: number
          status?: string
          unit_label: string
          unit_type?: string | null
          unit_type_id?: string | null
          updated_at?: string
        }
        Update: {
          created_at?: string
          deposit_amount?: number
          id?: string
          meter_ref_power?: string | null
          meter_ref_water?: string | null
          org_id?: string | null
          property_id?: string
          rent_amount?: number
          status?: string
          unit_label?: string
          unit_type?: string | null
          unit_type_id?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "units_property_id_fkey"
            columns: ["property_id"]
            isOneToOne: false
            referencedRelation: "properties"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "units_unit_type_id_fkey"
            columns: ["unit_type_id"]
            isOneToOne: false
            referencedRelation: "unit_types"
            referencedColumns: ["id"]
          },
        ]
      }
      vendors: {
        Row: {
          created_at: string
          id: string
          name: string
          notes: string | null
          org_id: string
          phone: string
          trade: string
          updated_at: string
        }
        Insert: {
          created_at?: string
          id?: string
          name: string
          notes?: string | null
          org_id: string
          phone: string
          trade: string
          updated_at?: string
        }
        Update: {
          created_at?: string
          id?: string
          name?: string
          notes?: string | null
          org_id?: string
          phone?: string
          trade?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "vendors_org_id_fkey"
            columns: ["org_id"]
            isOneToOne: false
            referencedRelation: "orgs"
            referencedColumns: ["id"]
          },
        ]
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      get_user_org_ids: { Args: { p_user_id: string }; Returns: string[] }
      get_user_tenant_org_ids: {
        Args: { p_user_id: string }
        Returns: string[]
      }
      is_org_member: {
        Args: { p_org_id: string; p_user_id: string }
        Returns: boolean
      }
      is_tenant_user: { Args: { p_user_id: string }; Returns: boolean }
    }
    Enums: {
      [_ in never]: never
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  public: {
    Enums: {},
  },
} as const
