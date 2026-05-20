<?php

namespace App\Livewire\Admin;

use App\Models\User;
use Livewire\Component;
use Livewire\WithPagination;
use Illuminate\Support\Facades\Hash;
use Livewire\Attributes\Layout;

#[Layout('layouts.app')]
class UserManager extends Component
{
    use WithPagination;

    public $search = '';
    public $perPage = 10;
    
    // Form fields
    public $userId;
    public $name;
    public $email;
    public $mobile;
    public $selectedRoles = [];
    public $password;
    
    public $showModal = false;
    public $isEdit = false;

    protected $queryString = ['search'];

    public function updatingSearch()
    {
        $this->resetPage();
    }

    public function loadMore()
    {
        $this->perPage += 10;
    }

    public function openModal()
    {
        $this->resetForm();
        $this->showModal = true;
    }

    public function closeModal()
    {
        $this->showModal = false;
        $this->resetForm();
    }

    public function resetForm()
    {
        $this->userId = null;
        $this->name = '';
        $this->email = '';
        $this->mobile = '';
        $this->selectedRoles = [];
        $this->password = '';
        $this->isEdit = false;
        $this->resetErrorBag();
    }

    public function save()
    {
        $rules = [
            'name' => 'required|string|max:255',
            'email' => 'required|email|unique:users,email,' . $this->userId,
            'mobile' => 'required|string|max:15|unique:users,mobile,' . $this->userId,
            'selectedRoles' => 'required|array|min:1',
        ];

        if (!$this->isEdit) {
            $rules['password'] = 'required|min:6';
        }

        $this->validate($rules);

        if ($this->isEdit) {
            $user = User::find($this->userId);
            $user->update([
                'name' => $this->name,
                'email' => $this->email,
                'mobile' => $this->mobile,
            ]);
            
            // Sync Multiple Roles
            $roleIds = \App\Models\Role::whereIn('name', $this->selectedRoles)->pluck('id');
            $user->roles()->sync($roleIds);

            if ($this->password) {
                $user->update(['password' => Hash::make($this->password)]);
            }

            session()->flash('message', 'User updated successfully.');
        } else {
            $user = User::create([
                'name' => $this->name,
                'email' => $this->email,
                'mobile' => $this->mobile,
                'password' => Hash::make($this->password),
            ]);

            // Assign Multiple Roles
            $roleIds = \App\Models\Role::whereIn('name', $this->selectedRoles)->pluck('id');
            $user->roles()->attach($roleIds);

            session()->flash('message', 'User created successfully.');
        }

        $this->closeModal();
    }

    public function edit($id)
    {
        $this->isEdit = true;
        $user = User::with('roles')->find($id);
        $this->userId = $user->id;
        $this->name = $user->name;
        $this->email = $user->email;
        $this->mobile = $user->mobile;
        $this->selectedRoles = $user->roles->pluck('name')->toArray();
        $this->password = '';
        
        $this->showModal = true;
    }

    public function delete($id)
    {
        if ($id === auth()->id()) {
            session()->flash('error', 'You cannot delete yourself.');
            return;
        }
        
        User::destroy($id);
        session()->flash('message', 'User deleted successfully.');
    }

    public function render()
    {
        $users = User::query()
            ->with('roles')
            ->where(function($query) {
                $query->where('name', 'like', '%' . $this->search . '%')
                    ->orWhere('email', 'like', '%' . $this->search . '%')
                    ->orWhere('mobile', 'like', '%' . $this->search . '%');
            })
            ->latest()
            ->paginate($this->perPage);

        return view('livewire.admin.user-manager', [
            'users' => $users,
            'roles' => \App\Models\Role::all()
        ]);
    }
}
