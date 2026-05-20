<?php

namespace App\Livewire\Admin;

use App\Models\PricingPlan;
use Livewire\Component;
use Livewire\Attributes\Layout;

class PricingPlanManager extends Component
{
    public $plans;
    public $name, $monthly_price, $yearly_price, $description;
    public $outlets = 1;
    public $is_outlets_fixed = true;
    public $features = ['']; // For the 'list' array field
    public $planId;
    public $isEdit = false;
    public $showModal = false;

    #[Layout('layouts.app')]
    public function render()
    {
        $this->plans = PricingPlan::latest()->get();
        return view('livewire.admin.pricing-plan-manager');
    }

    public function addFeature()
    {
        $this->features[] = '';
    }

    public function removeFeature($index)
    {
        unset($this->features[$index]);
        $this->features = array_values($this->features);
    }

    public function resetFields()
    {
        $this->name = '';
        $this->monthly_price = '';
        $this->yearly_price = '';
        $this->description = '';
        $this->outlets = 1;
        $this->is_outlets_fixed = true;
        $this->features = [''];
        $this->planId = null;
        $this->isEdit = false;
    }

    public function openModal()
    {
        $this->resetFields();
        $this->showModal = true;
    }

    public function closeModal()
    {
        $this->showModal = false;
    }

    public function save()
    {
        $this->validate([
            'name' => 'required|string|max:255',
            'monthly_price' => 'required|numeric|min:0',
            'yearly_price' => 'required|numeric|min:0',
            'description' => 'nullable|string',
            'outlets' => 'required|integer|min:1',
            'is_outlets_fixed' => 'required|boolean',
            'features' => 'required|array|min:1',
            'features.*' => 'required|string|max:255',
        ]);

        $data = [
            'name' => $this->name,
            'monthly_price' => $this->monthly_price,
            'yearly_price' => $this->yearly_price,
            'description' => $this->description,
            'outlets' => $this->outlets,
            'is_outlets_fixed' => $this->is_outlets_fixed,
            'list' => array_filter($this->features),
        ];

        if ($this->isEdit) {
            PricingPlan::find($this->planId)->update($data);
        } else {
            PricingPlan::create($data);
        }

        $this->closeModal();
        session()->flash('message', $this->isEdit ? 'Plan updated successfully.' : 'Plan created successfully.');
    }

    public function edit($id)
    {
        $plan = PricingPlan::findOrFail($id);
        $this->planId = $id;
        $this->name = $plan->name;
        $this->monthly_price = $plan->monthly_price;
        $this->yearly_price = $plan->yearly_price;
        $this->description = $plan->description;
        $this->outlets = $plan->outlets;
        $this->is_outlets_fixed = $plan->is_outlets_fixed;
        $this->features = $plan->list ?? [''];
        $this->isEdit = true;
        $this->showModal = true;
    }

    public function delete($id)
    {
        PricingPlan::destroy($id);
        session()->flash('message', 'Plan deleted successfully.');
    }
}
