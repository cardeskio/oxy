-- ============================================================================
-- ORDERS SYSTEM
-- Enables ordering from service provider listings
-- ============================================================================

-- Order status enum
DO $$ BEGIN
    CREATE TYPE order_status AS ENUM (
        'pending',      -- Order placed, awaiting confirmation
        'confirmed',    -- Provider confirmed the order
        'preparing',    -- Order is being prepared
        'ready',        -- Ready for delivery/pickup
        'out_for_delivery', -- On the way
        'delivered',    -- Successfully delivered
        'completed',    -- Order completed (after delivery confirmed)
        'cancelled'     -- Order cancelled
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Delivery type enum
DO $$ BEGIN
    CREATE TYPE delivery_type AS ENUM ('delivery', 'pickup');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- ============================================================================
-- ORDERS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Order parties
    customer_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    provider_id UUID NOT NULL REFERENCES public.service_providers(id) ON DELETE CASCADE,
    
    -- Order details
    order_number TEXT NOT NULL UNIQUE,
    status order_status NOT NULL DEFAULT 'pending',
    
    -- Items (JSONB array of order items)
    items JSONB NOT NULL DEFAULT '[]'::jsonb,
    -- Structure: [{ listing_id, title, quantity, unit_price, total_price, notes }]
    
    -- Pricing
    subtotal DOUBLE PRECISION NOT NULL DEFAULT 0,
    delivery_fee DOUBLE PRECISION DEFAULT 0,
    total_amount DOUBLE PRECISION NOT NULL DEFAULT 0,
    
    -- Delivery info
    delivery_type delivery_type NOT NULL DEFAULT 'delivery',
    delivery_address TEXT,
    delivery_apartment TEXT,  -- Property name if tenant
    delivery_unit TEXT,       -- Unit label if tenant
    delivery_instructions TEXT,
    delivery_phone TEXT NOT NULL,
    delivery_name TEXT NOT NULL,
    
    -- Coordinates for delivery
    delivery_latitude DOUBLE PRECISION,
    delivery_longitude DOUBLE PRECISION,
    
    -- Timing
    requested_time TIMESTAMP WITH TIME ZONE, -- When customer wants delivery
    estimated_delivery TIMESTAMP WITH TIME ZONE,
    actual_delivery TIMESTAMP WITH TIME ZONE,
    
    -- Notes and communication
    customer_notes TEXT,
    provider_notes TEXT,
    cancellation_reason TEXT,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    confirmed_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_orders_customer ON public.orders(customer_id);
CREATE INDEX IF NOT EXISTS idx_orders_provider ON public.orders(provider_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON public.orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_created ON public.orders(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_orders_number ON public.orders(order_number);

-- ============================================================================
-- ORDER ITEMS TABLE (for detailed tracking)
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.order_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
    listing_id UUID REFERENCES public.service_listings(id) ON DELETE SET NULL,
    
    title TEXT NOT NULL,
    description TEXT,
    quantity INTEGER NOT NULL DEFAULT 1,
    unit_price DOUBLE PRECISION NOT NULL,
    total_price DOUBLE PRECISION NOT NULL,
    notes TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_order_items_order ON public.order_items(order_id);

-- ============================================================================
-- USER DELIVERY SETTINGS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.user_delivery_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
    
    -- Default delivery info
    default_name TEXT,
    default_phone TEXT,
    default_address TEXT,
    default_apartment TEXT,  -- Auto-filled from tenant's property
    default_unit TEXT,       -- Auto-filled from tenant's unit
    default_instructions TEXT,
    
    -- Location
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================================
-- GENERATE ORDER NUMBER FUNCTION
-- ============================================================================

CREATE OR REPLACE FUNCTION generate_order_number()
RETURNS TRIGGER AS $$
BEGIN
    -- Format: ORD-YYYYMMDD-XXXX (random 4 chars)
    NEW.order_number := 'ORD-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-' || 
        UPPER(SUBSTRING(MD5(RANDOM()::TEXT) FROM 1 FOR 4));
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_generate_order_number ON public.orders;
CREATE TRIGGER trigger_generate_order_number
    BEFORE INSERT ON public.orders
    FOR EACH ROW
    WHEN (NEW.order_number IS NULL)
    EXECUTE FUNCTION generate_order_number();

-- ============================================================================
-- UPDATE TIMESTAMPS TRIGGER
-- ============================================================================

CREATE OR REPLACE FUNCTION update_order_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    
    -- Set confirmed_at when status changes to confirmed
    IF NEW.status = 'confirmed' AND OLD.status = 'pending' THEN
        NEW.confirmed_at = NOW();
    END IF;
    
    -- Set completed_at when status changes to completed
    IF NEW.status = 'completed' AND OLD.status != 'completed' THEN
        NEW.completed_at = NOW();
    END IF;
    
    -- Set actual_delivery when delivered
    IF NEW.status = 'delivered' AND OLD.status != 'delivered' THEN
        NEW.actual_delivery = NOW();
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_order_timestamp ON public.orders;
CREATE TRIGGER trigger_update_order_timestamp
    BEFORE UPDATE ON public.orders
    FOR EACH ROW
    EXECUTE FUNCTION update_order_timestamp();

-- ============================================================================
-- ORDER NOTIFICATION FUNCTIONS
-- ============================================================================

-- Notify provider of new order
CREATE OR REPLACE FUNCTION notify_new_order()
RETURNS TRIGGER AS $$
DECLARE
    provider_user_id UUID;
    customer_name TEXT;
BEGIN
    -- Get provider's user_id
    SELECT user_id INTO provider_user_id
    FROM public.service_providers
    WHERE id = NEW.provider_id;
    
    -- Get customer name
    SELECT full_name INTO customer_name
    FROM public.profiles
    WHERE id = NEW.customer_id;
    
    -- Create notification for provider
    INSERT INTO public.notifications (user_id, type, title, body, data)
    VALUES (
        provider_user_id,
        'order_new',
        'New Order Received! 🛒',
        'Order #' || NEW.order_number || ' from ' || COALESCE(customer_name, 'Customer') || 
        ' - KES ' || NEW.total_amount::TEXT,
        jsonb_build_object(
            'order_id', NEW.id,
            'order_number', NEW.order_number,
            'total_amount', NEW.total_amount
        )
    );
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trigger_notify_new_order ON public.orders;
CREATE TRIGGER trigger_notify_new_order
    AFTER INSERT ON public.orders
    FOR EACH ROW
    EXECUTE FUNCTION notify_new_order();

-- Notify customer of order status change
CREATE OR REPLACE FUNCTION notify_order_status_change()
RETURNS TRIGGER AS $$
DECLARE
    provider_name TEXT;
    status_title TEXT;
    status_body TEXT;
BEGIN
    -- Only notify on status changes
    IF OLD.status = NEW.status THEN
        RETURN NEW;
    END IF;
    
    -- Get provider name
    SELECT business_name INTO provider_name
    FROM public.service_providers
    WHERE id = NEW.provider_id;
    
    -- Set notification message based on status
    CASE NEW.status
        WHEN 'confirmed' THEN
            status_title := 'Order Confirmed ✅';
            status_body := 'Your order #' || NEW.order_number || ' has been confirmed by ' || provider_name;
        WHEN 'preparing' THEN
            status_title := 'Order Being Prepared 👨‍🍳';
            status_body := 'Your order #' || NEW.order_number || ' is being prepared';
        WHEN 'ready' THEN
            status_title := 'Order Ready! 📦';
            status_body := 'Your order #' || NEW.order_number || ' is ready for ' || 
                CASE NEW.delivery_type WHEN 'delivery' THEN 'delivery' ELSE 'pickup' END;
        WHEN 'out_for_delivery' THEN
            status_title := 'Out for Delivery 🚗';
            status_body := 'Your order #' || NEW.order_number || ' is on the way!';
        WHEN 'delivered' THEN
            status_title := 'Order Delivered! 🎉';
            status_body := 'Your order #' || NEW.order_number || ' has been delivered';
        WHEN 'completed' THEN
            status_title := 'Order Completed';
            status_body := 'Thank you for your order #' || NEW.order_number;
        WHEN 'cancelled' THEN
            status_title := 'Order Cancelled ❌';
            status_body := 'Your order #' || NEW.order_number || ' has been cancelled' ||
                CASE WHEN NEW.cancellation_reason IS NOT NULL 
                    THEN '. Reason: ' || NEW.cancellation_reason 
                    ELSE '' END;
        ELSE
            RETURN NEW;
    END CASE;
    
    -- Create notification for customer
    INSERT INTO public.notifications (user_id, type, title, body, data)
    VALUES (
        NEW.customer_id,
        'order_update',
        status_title,
        status_body,
        jsonb_build_object(
            'order_id', NEW.id,
            'order_number', NEW.order_number,
            'status', NEW.status
        )
    );
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trigger_notify_order_status ON public.orders;
CREATE TRIGGER trigger_notify_order_status
    AFTER UPDATE ON public.orders
    FOR EACH ROW
    EXECUTE FUNCTION notify_order_status_change();

-- ============================================================================
-- ROW LEVEL SECURITY
-- ============================================================================

ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_delivery_settings ENABLE ROW LEVEL SECURITY;

-- Orders: customers can see their own, providers can see orders to them
DROP POLICY IF EXISTS orders_select ON public.orders;
CREATE POLICY orders_select ON public.orders
    FOR SELECT TO authenticated
    USING (
        customer_id = auth.uid() OR
        provider_id IN (SELECT id FROM public.service_providers WHERE user_id = auth.uid())
    );

-- Customers can create orders
DROP POLICY IF EXISTS orders_insert ON public.orders;
CREATE POLICY orders_insert ON public.orders
    FOR INSERT TO authenticated
    WITH CHECK (customer_id = auth.uid());

-- Customers can update their pending orders, providers can update order status
DROP POLICY IF EXISTS orders_update ON public.orders;
CREATE POLICY orders_update ON public.orders
    FOR UPDATE TO authenticated
    USING (
        customer_id = auth.uid() OR
        provider_id IN (SELECT id FROM public.service_providers WHERE user_id = auth.uid())
    );

-- Order items follow order access
DROP POLICY IF EXISTS order_items_select ON public.order_items;
CREATE POLICY order_items_select ON public.order_items
    FOR SELECT TO authenticated
    USING (
        order_id IN (
            SELECT id FROM public.orders 
            WHERE customer_id = auth.uid() OR
            provider_id IN (SELECT id FROM public.service_providers WHERE user_id = auth.uid())
        )
    );

DROP POLICY IF EXISTS order_items_insert ON public.order_items;
CREATE POLICY order_items_insert ON public.order_items
    FOR INSERT TO authenticated
    WITH CHECK (
        order_id IN (SELECT id FROM public.orders WHERE customer_id = auth.uid())
    );

-- Delivery settings: users can only access their own
DROP POLICY IF EXISTS delivery_settings_all ON public.user_delivery_settings;
CREATE POLICY delivery_settings_all ON public.user_delivery_settings
    FOR ALL TO authenticated
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- ============================================================================
-- GRANTS
-- ============================================================================

GRANT ALL ON public.orders TO authenticated;
GRANT ALL ON public.order_items TO authenticated;
GRANT ALL ON public.user_delivery_settings TO authenticated;

-- ============================================================================
-- REALTIME
-- ============================================================================

DO $$ BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.orders;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- ============================================================================
-- ADD NOTIFICATION TYPES TO ENUM (if not exists)
-- ============================================================================

-- Check and add new notification types
DO $$
BEGIN
    -- Add order_new if not exists
    IF NOT EXISTS (SELECT 1 FROM pg_enum WHERE enumlabel = 'order_new' AND enumtypid = 'notification_type'::regtype) THEN
        ALTER TYPE notification_type ADD VALUE 'order_new';
    END IF;
EXCEPTION WHEN others THEN
    NULL;
END $$;

DO $$
BEGIN
    -- Add order_update if not exists
    IF NOT EXISTS (SELECT 1 FROM pg_enum WHERE enumlabel = 'order_update' AND enumtypid = 'notification_type'::regtype) THEN
        ALTER TYPE notification_type ADD VALUE 'order_update';
    END IF;
EXCEPTION WHEN others THEN
    NULL;
END $$;
