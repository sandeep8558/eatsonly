<?php

namespace App\Livewire\Admin;

use App\Models\MasterMenu;
use App\Models\MasterCategory;
use Livewire\Component;
use Livewire\WithFileUploads;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Http;
use Livewire\Attributes\Layout;

class MasterMenuManager extends Component
{
    use WithFileUploads;

    public $menus;
    public $name, $description, $image, $is_active = true, $menu_id;
    public $oldImage;
    public $selectedCategories = [];
    public $isOpen = false;
    public $search = '';
    public $filterCategory = '';

    #[Layout('layouts.app')]
    public function render()
    {
        $query = MasterMenu::with('categories')->orderBy('name', 'asc');

        if ($this->search) {
            $query->where('name', 'like', '%' . $this->search . '%');
        }

        if ($this->filterCategory) {
            $query->whereHas('categories', function($q) {
                $q->where('master_categories.id', $this->filterCategory);
            });
        }

        $this->menus = $query->get();
        return view('livewire.admin.master-menu-manager', [
            'availableCategories' => MasterCategory::where('is_active', true)->orderBy('name', 'asc')->get()
        ]);
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
        $this->description = '';
        $this->image = null;
        $this->oldImage = null;
        $this->is_active = true;
        $this->menu_id = null;
        $this->selectedCategories = [];
    }

    public function store()
    {
        $this->validate([
            'name' => 'required|string|max:255',
            'description' => 'nullable|string',
            'image' => 'nullable|image|max:2048',
            'selectedCategories' => 'required|array|min:1',
        ]);

        $data = [
            'name' => $this->name,
            'description' => $this->description,
            'is_active' => $this->is_active,
        ];

        if ($this->image) {
            if ($this->oldImage) {
                Storage::disk('public')->delete($this->oldImage);
            }
            $data['image'] = $this->image->store('master-menus', 'public');
        }

        $menu = MasterMenu::updateOrCreate(['id' => $this->menu_id], $data);
        $menu->categories()->sync($this->selectedCategories);

        session()->flash('message', $this->menu_id ? 'Menu Updated Successfully.' : 'Menu Created Successfully.');

        $this->closeModal();
        $this->resetInputFields();
    }

    public function edit($id)
    {
        $menu = MasterMenu::with('categories')->findOrFail($id);
        $this->menu_id = $id;
        $this->name = $menu->name;
        $this->description = $menu->description;
        $this->oldImage = $menu->image;
        $this->is_active = $menu->is_active;
        $this->selectedCategories = $menu->categories->pluck('id')->toArray();

        $this->openModal();
    }

    public function delete($id)
    {
        $menu = MasterMenu::find($id);
        if ($menu->image) {
            Storage::disk('public')->delete($menu->image);
        }
        $menu->delete();
        session()->flash('message', 'Menu Deleted Successfully.');
    }

    public function toggleStatus($id)
    {
        $menu = MasterMenu::find($id);
        $menu->is_active = !$menu->is_active;
        $menu->save();
    }

    public function generateDescription()
    {
        if (empty($this->name)) {
            $this->addError('name', 'Please enter a menu name first.');
            return;
        }

        $key = config('services.gemini.key');
        if (empty($key)) {
            session()->flash('message', 'Gemini API Key is missing in .env');
            return;
        }

        $prompt = "Write a short, appetizing, 1-sentence restaurant menu description for a food item named '{$this->name}'. Make it sound delicious but keep it under 150 characters. Return ONLY the description, no quotes, no markdown.";

        try {
            $response = Http::post("https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent?key={$key}", [
                'contents' => [['parts' => [['text' => $prompt]]]]
            ]);

            if ($response->successful()) {
                $result = $response->json();
                $text = trim($result['candidates'][0]['content']['parts'][0]['text'] ?? '');
                if ($text) {
                    $this->description = str_replace('"', '', $text);
                    return;
                }
                session()->flash('message', 'Failed to generate description.');
            } else {
                session()->flash('message', 'AI API Error: ' . $response->body());
            }
        } catch (\Exception $e) {
            session()->flash('message', 'AI Error: ' . $e->getMessage());
        }
    }

    public function autoCategorizeSingle()
    {
        if (empty($this->name)) {
            $this->addError('name', 'Please enter a menu name first.');
            return;
        }

        $key = config('services.gemini.key');
        if (empty($key)) {
            session()->flash('message', 'Gemini API Key is missing in .env');
            return;
        }

        $categories = MasterCategory::where('is_active', true)->get();
        if ($categories->isEmpty()) return;

        $catList = $categories->map(function($c) { return "ID: {$c->id}, Name: {$c->name}"; })->implode("\n");
        $prompt = "I have a food menu item named '{$this->name}'. Its description is '{$this->description}'.\n\nHere are the available categories:\n{$catList}\n\nSelect the most suitable categories for this item. Return ONLY a valid JSON array of the category IDs. Do not include any other text, markdown, or explanation. Example: [\"uuid-1\", \"uuid-2\"]";

        try {
            $response = Http::post("https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent?key={$key}", [
                'contents' => [['parts' => [['text' => $prompt]]]]
            ]);

            if ($response->successful()) {
                $result = $response->json();
                $text = trim($result['candidates'][0]['content']['parts'][0]['text'] ?? '');
                
                // Clean markdown if present
                $cleanText = str_replace(['```json', '```'], '', $text);
                $selectedIds = json_decode(trim($cleanText), true);

                if (is_array($selectedIds)) {
                    $this->selectedCategories = array_intersect($categories->pluck('id')->toArray(), $selectedIds);
                    return;
                }

                session()->flash('message', 'Failed to parse AI response. Raw: ' . substr($text, 0, 100));
            } else {
                session()->flash('message', 'AI API Error: ' . $response->body());
            }
        } catch (\Exception $e) {
            session()->flash('message', 'AI Error: ' . $e->getMessage());
        }
    }

    public function autoCategorizeAll()
    {
        $menus = MasterMenu::with('categories')->get();
        // Filter menus that have no categories
        $menusToCategorize = $menus->filter(function($m) { return $m->categories->isEmpty(); });

        if ($menusToCategorize->isEmpty()) {
            session()->flash('message', 'All menus already have categories!');
            return;
        }

        $key = config('services.gemini.key');
        if (empty($key)) {
            session()->flash('message', 'Gemini API Key is missing in .env');
            return;
        }

        $categories = MasterCategory::where('is_active', true)->get();
        $catList = $categories->map(function($c) { return "ID: {$c->id}, Name: {$c->name}"; })->implode("\n");
        
        $menuList = $menusToCategorize->map(function($m) { return "ID: {$m->id}, Name: {$m->name}"; })->implode("\n");

        $prompt = "I have the following food menu items:\n{$menuList}\n\nHere are the available categories:\n{$catList}\n\nFor each menu item, select the most suitable categories. Return ONLY a valid JSON array of objects. Do not include any other text, markdown, or explanation. Format: [{\"menu_id\": \"uuid\", \"category_ids\": [\"cat-uuid\"]}]";

        try {
            $response = Http::post("https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent?key={$key}", [
                'contents' => [['parts' => [['text' => $prompt]]]]
            ]);

            if ($response->successful()) {
                $result = $response->json();
                $text = trim($result['candidates'][0]['content']['parts'][0]['text'] ?? '');
                
                $cleanText = str_replace(['```json', '```'], '', $text);
                $mappings = json_decode(trim($cleanText), true);

                if (is_array($mappings)) {
                    foreach ($mappings as $mapping) {
                        if (isset($mapping['menu_id']) && isset($mapping['category_ids'])) {
                            $menu = MasterMenu::find($mapping['menu_id']);
                            if ($menu) {
                                $validCatIds = array_intersect($categories->pluck('id')->toArray(), $mapping['category_ids']);
                                $menu->categories()->sync($validCatIds);
                            }
                        }
                    }
                    session()->flash('message', 'Successfully auto-categorized ' . count($mappings) . ' menus!');
                    return;
                }
                session()->flash('message', 'Failed to parse AI response. Raw: ' . substr($text, 0, 100));
            } else {
                session()->flash('message', 'AI API Error: ' . $response->body());
            }
        } catch (\Exception $e) {
            session()->flash('message', 'AI Error: ' . $e->getMessage());
        }
    }
}
