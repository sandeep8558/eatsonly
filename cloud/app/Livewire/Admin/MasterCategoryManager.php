<?php

namespace App\Livewire\Admin;

use App\Models\MasterCategory;
use Livewire\Component;
use Livewire\WithFileUploads;
use Illuminate\Support\Facades\Storage;
use Livewire\Attributes\Layout;

class MasterCategoryManager extends Component
{
    use WithFileUploads;

    public $categories;
    public $name, $is_active = true, $category_id;
    public $isOpen = false;

    public $search = '';

    #[Layout('layouts.app')]
    public function render()
    {
        $query = MasterCategory::orderBy('name', 'asc');

        if ($this->search) {
            $query->where('name', 'like', '%' . $this->search . '%');
        }

        $this->categories = $query->get();
        return view('livewire.admin.master-category-manager');
    }

    public function create()
    {
        $this->resetInputFields();
        $this->openModal();
    }

    public function openModal()
    {
        $this->isOpen = true;
    }

    public function closeModal()
    {
        $this->isOpen = false;
    }

    private function resetInputFields()
    {
        $this->name = '';
        $this->is_active = true;
        $this->category_id = null;
    }

    public function store()
    {
        $this->validate([
            'name' => 'required|string|max:255',
        ]);

        $data = [
            'name' => $this->name,
            'is_active' => $this->is_active,
        ];

        MasterCategory::updateOrCreate(['id' => $this->category_id], $data);

        session()->flash('message', $this->category_id ? 'Category Updated Successfully.' : 'Category Created Successfully.');

        $this->closeModal();
        $this->resetInputFields();
    }

    public function edit($id)
    {
        $category = MasterCategory::findOrFail($id);
        $this->category_id = $id;
        $this->name = $category->name;
        $this->is_active = $category->is_active;

        $this->openModal();
    }

    public function delete($id)
    {
        $category = MasterCategory::find($id);
        $category->delete();
        session()->flash('message', 'Category Deleted Successfully.');
    }

    public function toggleStatus($id)
    {
        $category = MasterCategory::find($id);
        $category->is_active = !$category->is_active;
        $category->save();
    }
}
