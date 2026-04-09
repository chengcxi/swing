import { createClient } from '@supabase/supabase-js';

const SUPABASE_URL = 'https://wykrktxowxbqosxlarjb.supabase.co';
const SUPABASE_ANON_KEY = 'sb_publishable_E2eEfXS48220XQVwnpVVJg_-3qjuccK';

export const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
