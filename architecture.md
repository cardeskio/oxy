# Kenya Property Management System - Architecture

## Design Inspiration
**WhatsApp-inspired UX**: Familiar green/teal color palette, tab-based navigation, list-centric layouts with avatars, floating action buttons, and clean minimal design.

## Color Palette (WhatsApp-inspired)
- **Primary**: Teal Green (#128C7E)
- **Primary Dark**: Dark Teal (#075E54)
- **Accent**: Light Green (#25D366)
- **Background**: Light gray (#F0F2F5)
- **Surface**: White
- **Text**: Dark gray on light, white on dark

## MVP Scope (Admin App Focus)

### Core Modules
1. **Properties & Units** - Property listing, unit management
2. **Tenants** - Tenant profiles and management
3. **Leases** - Lease lifecycle (draft → active → ended)
4. **Invoices** - Monthly billing, line items
5. **Payments** - Payment capture and allocation
6. **Maintenance** - Ticket management

### Data Models (`lib/models/`)
- `property.dart` - Property with units
- `unit.dart` - Individual rental unit
- `tenant.dart` - Tenant profile
- `lease.dart` - Lease agreement
- `invoice.dart` - Invoice with line items
- `payment.dart` - Payment record
- `maintenance_ticket.dart` - Maintenance request

### Services (`lib/services/`)
- `property_service.dart` - CRUD for properties/units
- `tenant_service.dart` - Tenant management
- `lease_service.dart` - Lease lifecycle
- `invoice_service.dart` - Invoice generation/management
- `payment_service.dart` - Payment capture/allocation
- `maintenance_service.dart` - Ticket management

### Pages (`lib/pages/`)
- `admin_shell.dart` - Main navigation shell with tabs
- `properties_page.dart` - Properties list
- `property_detail_page.dart` - Property with units
- `tenants_page.dart` - Tenants list
- `tenant_detail_page.dart` - Tenant profile
- `invoices_page.dart` - Invoices list
- `payments_page.dart` - Payments list
- `maintenance_page.dart` - Tickets list
- `dashboard_page.dart` - Overview metrics

### Components (`lib/components/`)
- `property_card.dart` - Property list item
- `unit_card.dart` - Unit list item
- `tenant_card.dart` - Tenant list item
- `invoice_card.dart` - Invoice list item
- `payment_card.dart` - Payment list item
- `ticket_card.dart` - Maintenance ticket item
- `stat_card.dart` - Dashboard stat card
- `empty_state.dart` - Empty state placeholder
- `search_header.dart` - Search/filter header

### Navigation Structure
```
Admin App (Bottom Tabs):
├── Dashboard (Home icon)
├── Properties (Building icon)  
├── Tenants (People icon)
├── Invoices (Receipt icon)
└── More (Menu icon)
    ├── Payments
    ├── Maintenance
    └── Settings
```

## Authentication & Roles

### User Types
- **Admin Users** (Property owners, managers, accountants, caretakers)
  - Full access to admin app with role-based permissions
  - Access via org_members table
- **Tenant Users**
  - Access to tenant portal only
  - Access via tenant_user_links table

### Tenant Claim Code Flow
1. Tenant signs up → Gets unique 6-character claim code
2. Tenant shares code with property owner
3. Owner enters code in "Link Tenant" page
4. System links tenant record to auth user
5. Tenant gains access to tenant portal

### Auth Pages
- `/login` - Email/password login
- `/signup` - Registration (choose owner or tenant)
- `/forgot-password` - Password reset
- `/claim-code` - Displays claim code after tenant signup
- `/create-org` - Organization creation for owners
- `/link-tenant` - Link tenant account via claim code

### Tenant Portal (`/tenant/*`)
- Dashboard with rental summary, balance, quick actions
- Invoices list and detail view
- Payments history
- Maintenance requests
- Profile and sign out

## Database (Supabase)

### Key Tables
- `profiles` - User profiles (linked to auth.users)
- `orgs` - Organizations
- `org_members` - User roles within orgs
- `tenant_claim_codes` - Claim codes for tenant linking
- `tenant_user_links` - Links auth users to tenant records

### Row Level Security
- Org isolation via org_id on all tables
- Tenant access scoped to their linked records
- Role-based permissions enforced at database level

## Implementation Order
1. Theme setup (WhatsApp colors)
2. Data models
3. Services with sample data
4. Navigation shell
5. Auth pages and services
6. Dashboard page
7. Properties module
8. Tenants module
9. Invoices module
10. Payments module
11. Maintenance module
12. Tenant portal
