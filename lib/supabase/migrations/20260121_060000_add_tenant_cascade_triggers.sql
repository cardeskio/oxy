-- Add trigger to handle tenant deletion cleanup
-- This ensures data consistency when a tenant is deleted

CREATE OR REPLACE FUNCTION public.handle_tenant_delete()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- End active leases for this tenant
    UPDATE leases 
    SET status = 'ended', 
        move_out_notes = COALESCE(move_out_notes, '') || ' [Auto-ended: tenant deleted]',
        updated_at = NOW()
    WHERE tenant_id = OLD.id 
    AND status = 'active';
    
    -- Set units from ended leases back to vacant
    UPDATE units 
    SET status = 'vacant', updated_at = NOW()
    WHERE id IN (
        SELECT unit_id FROM leases 
        WHERE tenant_id = OLD.id 
        AND status = 'ended'
    );
    
    -- Delete tenant_user_links
    DELETE FROM tenant_user_links WHERE tenant_id = OLD.id;
    
    -- Clear tenant_id from claim codes (don't delete the code, just unlink)
    UPDATE tenant_claim_codes 
    SET tenant_id = NULL 
    WHERE tenant_id = OLD.id;
    
    RETURN OLD;
END;
$$;

-- Create the trigger
DROP TRIGGER IF EXISTS on_tenant_delete ON tenants;
CREATE TRIGGER on_tenant_delete
    BEFORE DELETE ON tenants
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_tenant_delete();

-- Also add proper foreign key cascades if not already present
-- (These might fail if constraints already exist, which is fine)

-- Ensure leases cascade properly
DO $$
BEGIN
    -- Drop existing constraint if it exists
    ALTER TABLE leases DROP CONSTRAINT IF EXISTS leases_tenant_id_fkey;
    
    -- Add with ON DELETE SET NULL (so lease history is preserved)
    ALTER TABLE leases 
    ADD CONSTRAINT leases_tenant_id_fkey 
    FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE SET NULL;
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Could not update leases foreign key: %', SQLERRM;
END $$;
