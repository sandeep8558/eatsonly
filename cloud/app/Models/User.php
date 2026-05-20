<?php

namespace App\Models;

// use Illuminate\Contracts\Auth\MustVerifyEmail;
use Database\Factories\UserFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\Hidden;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Support\Facades\DB;

#[Fillable(['name', 'email', 'mobile', 'password'])]
#[Hidden(['password', 'remember_token'])]
class User extends Authenticatable
{
    /** @use HasFactory<UserFactory> */
    use HasApiTokens, HasFactory, Notifiable, HasUuids;

    protected $connection = 'mysql';

    public $incrementing = false;
    protected $keyType = 'string';

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
        ];
    }

    public function restaurant(): HasOne
    {
        return $this->hasOne(Restaurant::class);
    }

    public function roles(): \Illuminate\Database\Eloquent\Relations\BelongsToMany
    {
        return $this->belongsToMany(Role::class);
    }

    public function getRolesAttribute()
    {
        if (!array_key_exists('roles', $this->relations)) {
            $this->relations['roles'] = $this->roles()->get();
        }

        $globalRoles = $this->relations['roles'];

        $restaurantRoles = Role::join('restaurant_role_user', 'roles.id', '=', 'restaurant_role_user.role_id')
            ->where('restaurant_role_user.user_id', $this->id)
            ->select('roles.*')
            ->get();

        return $globalRoles->merge($restaurantRoles)->unique('id')->values();
    }

    public function hasRole(string $role, $restaurantId = null): bool
    {
        if ($this->roles()->where('name', $role)->exists()) {
            return true;
        }

        if (!$restaurantId) {
            $restaurantId = request()->header('X-Restaurant-ID') 
                ?? request()->input('restaurant_id') 
                ?? request()->query('restaurant_id');
        }

        if ($restaurantId) {
            return DB::table('restaurant_role_user')
                ->join('roles', 'restaurant_role_user.role_id', '=', 'roles.id')
                ->where('restaurant_role_user.user_id', $this->id)
                ->where('restaurant_role_user.restaurant_id', $restaurantId)
                ->where('roles.name', $role)
                ->exists();
        }

        return false;
    }

    public function hasAnyRole(array $roles, $restaurantId = null): bool
    {
        if ($this->roles()->whereIn('name', $roles)->exists()) {
            return true;
        }

        if (!$restaurantId) {
            $restaurantId = request()->header('X-Restaurant-ID') 
                ?? request()->input('restaurant_id') 
                ?? request()->query('restaurant_id');
        }

        if ($restaurantId) {
            return DB::table('restaurant_role_user')
                ->join('roles', 'restaurant_role_user.role_id', '=', 'roles.id')
                ->where('restaurant_role_user.user_id', $this->id)
                ->where('restaurant_role_user.restaurant_id', $restaurantId)
                ->whereIn('roles.name', $roles)
                ->exists();
        }

        return false;
    }

    public function isSuperAdmin(): bool
    {
        return $this->hasRole('saas_super_admin');
    }

    public function isRestaurant(): bool
    {
        return $this->hasRole('admin');
    }

    public function isCustomer(): bool
    {
        return $this->hasRole('customer');
    }

    public function subscriptions(): HasMany
    {
        return $this->hasMany(Subscription::class);
    }

    public function addresses(): HasMany
    {
        return $this->hasMany(Address::class);
    }

    public function activeSubscription()
    {
        return $this->hasOne(Subscription::class)
            ->where('status', 'active')
            ->where('ends_at', '>', now())
            ->latestOfMany();
    }

    public function getSubscriptionSummary()
    {
        $sub = $this->activeSubscription;
        
        if (!$sub) {
            // Check if this user is a staff member of a restaurant
            $link = DB::table('restaurant_role_user')->where('user_id', $this->id)->first();
            if ($link) {
                $restaurant = DB::table('restaurants')->where('id', $link->restaurant_id)->first();
                if ($restaurant) {
                    $owner = User::find($restaurant->user_id);
                    if ($owner) {
                        $sub = $owner->activeSubscription;
                    }
                }
            }
        }

        if (!$sub) return null;

        $daysRemaining = (int) now()->diffInDays($sub->ends_at, false);

        return [
            'plan' => $sub->plan->name ?? 'Active Plan',
            'ends_at' => $sub->ends_at->toISOString(),
            'days_remaining' => $daysRemaining,
            'should_renew' => $daysRemaining <= 3,
            'is_expired' => $daysRemaining < 0,
            'outlets_allowed' => $sub->outlets ?? 1,
        ];
    }

    /**
     * Overrides model serialization to merge global and restaurant-specific roles.
     */
    public function toArray()
    {
        $array = parent::toArray();
        $array['roles'] = $this->roles->toArray();
        $array['subscription'] = $this->getSubscriptionSummary();
        return $array;
    }
}
