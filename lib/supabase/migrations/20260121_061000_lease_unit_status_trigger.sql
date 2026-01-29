-- Trigger to automatically sync unit status with lease status
-- When a lease is created/terminated/deleted, the unit status updates accordingly

CREATE OR REPLACE FUNCTION public.handle_lease_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- On DELETE: Set unit to vacant
    IF TG_OP = 'DELETE' THEN
        UPDATE units 
        SET status = 'vacant', updated_at = NOW()
        WHERE id = OLD.unit_id;
        RETURN OLD;
    END IF;
    
    -- On UPDATE: Check if status changed
    IF TG_OP = 'UPDATE' THEN
        -- If lease was active and is now ended
        IF OLD.status = 'active' AND NEW.status = 'ended' THEN
            UPDATE units 
            SET status = 'vacant', updated_at = NOW()
            WHERE id = NEW.unit_id;
        END IF;
        
        -- If lease becomes active, set unit to occupied
        IF NEW.status = 'active' AND (OLD.status IS NULL OR OLD.status != 'active') THEN
            UPDATE units 
            SET status = 'occupied', updated_at = NOW()
            WHERE id = NEW.unit_id;
        END IF;
        
        RETURN NEW;
    END IF;
    
    -- On INSERT: If new active lease, set unit to occupied
    IF TG_OP = 'INSERT' THEN
        IF NEW.status = 'active' THEN
            UPDATE units 
            SET status = 'occupied', updated_at = NOW()
            WHERE id = NEW.unit_id;
        END IF;
        RETURN NEW;
    END IF;
    
    RETURN NULL;
END;
$$;

-- Create the trigger
DROP TRIGGER IF EXISTS on_lease_change ON leases;
CREATE TRIGGER on_lease_change
    AFTER INSERT OR UPDATE OR DELETE ON leases
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_lease_change();
