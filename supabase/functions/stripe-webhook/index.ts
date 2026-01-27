import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import Stripe from 'https://esm.sh/stripe@11.1.0?target=deno'

const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY')!, {
  apiVersion: '2022-11-15',
})

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
)

serve(async (req) => {
  try {
    const signature = req.headers.get('Stripe-Signature')
    if (!signature) {
      return new Response(JSON.stringify({ error: 'No signature' }), { status: 400 })
    }

    const body = await req.text()

    const event = stripe.webhooks.constructEvent(
      body,
      signature,
      Deno.env.get('STRIPE_WEBHOOK_SECRET')!
    )

    console.log('Webhook event received:', event.type)

    if (event.type === 'checkout.session.completed') {
      const session = event.data.object as any
      const customerEmail = session.customer_details?.email

      console.log('Customer email:', customerEmail)

      if (customerEmail) {
        const { data, error } = await supabase
          .from('profiles')
          .update({
            subscription_status: 'active',
            stripe_customer_id: session.customer,
            current_period_end: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000).toISOString()
          })
          .eq('email', customerEmail)

        if (error) {
          console.error('Supabase update error:', error)
        } else {
          console.log('Profile updated successfully')
        }
      }
    }

    return new Response(JSON.stringify({ received: true }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' }
    })
  } catch (err) {
    console.error('Webhook error:', err.message)
    return new Response(JSON.stringify({ error: err.message }), {
      status: 400,
      headers: { 'Content-Type': 'application/json' }
    })
  }
})
