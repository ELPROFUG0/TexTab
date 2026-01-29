import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const STRIPE_SECRET_KEY = Deno.env.get('STRIPE_SECRET_KEY')!
const PRICE_ID = Deno.env.get('STRIPE_PRICE_ID')!
const SUCCESS_URL = 'https://textab.me/payment/success'
const CANCEL_URL = 'https://textab.me/payment/cancel'

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
)

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response(null, {
      status: 204,
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization',
      },
    })
  }

  try {
    const { email, device_id } = await req.json()

    if (!email) {
      return new Response(JSON.stringify({ error: 'Email is required' }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' },
      })
    }

    console.log('Creating checkout for:', email, 'device:', device_id)

    // Check if this user already had a subscription (has stripe_customer_id)
    const { data: profile } = await supabase
      .from('profiles')
      .select('stripe_customer_id')
      .eq('email', email)
      .single()

    let hasHadTrial = profile?.stripe_customer_id != null

    // Check if any other account on this device already used a trial
    if (!hasHadTrial && device_id) {
      const { data: deviceProfiles } = await supabase
        .from('profiles')
        .select('stripe_customer_id')
        .eq('device_id', device_id)
        .not('stripe_customer_id', 'is', null)

      if (deviceProfiles && deviceProfiles.length > 0) {
        hasHadTrial = true
        console.log('Trial blocked: device already used trial with another account')
      }
    }

    console.log('Has had trial:', hasHadTrial)

    // Build Stripe API form params
    const params = new URLSearchParams()
    params.append('mode', 'subscription')
    params.append('customer_email', email)
    params.append('line_items[0][price]', PRICE_ID)
    params.append('line_items[0][quantity]', '1')
    params.append('success_url', SUCCESS_URL)
    params.append('cancel_url', CANCEL_URL)

    // Only give trial to first-time users
    if (!hasHadTrial) {
      params.append('subscription_data[trial_period_days]', '3')
    }

    // Call Stripe API directly with fetch (avoids Deno/esm.sh timeout issues)
    const stripeRes = await fetch('https://api.stripe.com/v1/checkout/sessions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${STRIPE_SECRET_KEY}`,
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: params.toString(),
    })

    const session = await stripeRes.json()

    if (!stripeRes.ok) {
      console.error('Stripe error:', JSON.stringify(session))
      return new Response(JSON.stringify({ error: session.error?.message || 'Stripe error' }), {
        status: 500,
        headers: { 'Content-Type': 'application/json' },
      })
    }

    console.log('Checkout session created:', session.id)

    return new Response(JSON.stringify({ url: session.url }), {
      status: 200,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
      },
    })
  } catch (err) {
    console.error('Checkout error:', err.message)
    return new Response(JSON.stringify({ error: err.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    })
  }
})
