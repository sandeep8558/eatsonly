<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;
use App\Models\User;
use Illuminate\Support\Facades\DB;

class CheckSubscription
{
    /**
     * Handle an incoming request.
     *
     * @param  \Closure(\Illuminate\Http\Request): (\Symfony\Component\HttpFoundation\Response)  $next
     */
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();

        if (!$user) {
            return $next($request);
        }

        // Skip check for super admins
        if ($user->isSuperAdmin()) {
            return $next($request);
        }

        // Find the "Owner" of the current context
        $owner = $user;
        
        // Try to identify the restaurant context
        $restaurantId = $request->header('X-Restaurant-ID') 
            ?? $request->input('restaurant_id') 
            ?? $request->query('restaurant_id');

        if ($restaurantId) {
            // Find who owns this restaurant
            $restaurant = DB::table('restaurants')->where('id', $restaurantId)->first();
            if ($restaurant) {
                $resolvedOwner = User::find($restaurant->user_id);
                if ($resolvedOwner) {
                    $owner = $resolvedOwner;
                }
            }
        } else {
            // Fallback to finding the owner of the first restaurant this user is linked to
            $link = DB::table('restaurant_role_user')->where('user_id', $user->id)->first();
            if ($link) {
                $restaurant = DB::table('restaurants')->where('id', $link->restaurant_id)->first();
                if ($restaurant) {
                    $resolvedOwner = User::find($restaurant->user_id);
                    if ($resolvedOwner) {
                        $owner = $resolvedOwner;
                    }
                }
            }
        }

        // Check if the owner has an active subscription
        $subscription = $owner->activeSubscription;

        if (!$subscription) {
            // If the user is fetching something global (not their own restaurants, not a specific restaurant context)
            if ((!$restaurantId || $restaurantId === 'all') && $request->query('my_restaurants') !== '1' && $request->input('my_restaurants') !== '1') {
                return $next($request);
            }

            // If a customer is ordering from an expired restaurant, give a customer-friendly message
            $message = 'Your subscription has expired. Please renew your account.';
            if ($restaurantId && $user->id !== $owner->id) {
                $message = 'This restaurant is currently unavailable to accept orders.';
            }

            if ($request->expectsJson()) {
                return response()->json([
                    'success' => false,
                    'message' => $message,
                    'code' => 'SUBSCRIPTION_EXPIRED'
                ], 402); // Payment Required
            }
            
            // For web requests, avoid redirect loop if already on pricing or contact pages
            if ($request->routeIs('pricing') || $request->routeIs('contact') || $request->routeIs('profile')) {
                return $next($request);
            }

            return redirect()->route('pricing')->with('error', $message);
        }

        return $next($request);
    }
}
