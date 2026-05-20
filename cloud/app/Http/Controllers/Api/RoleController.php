<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Role;
use Illuminate\Http\Request;

class RoleController extends Controller
{
    /**
     * Get all available roles except super admin.
     */
    public function index()
    {
        $roles = Role::where('name', '!=', 'saas_super_admin')
            ->get(['name', 'display_name']);

        return response()->json([
            'status' => 'success',
            'data' => $roles
        ]);
    }
}
