<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\City;
use App\Models\Country;
use Illuminate\Http\Request;
use Inertia\Inertia;

class CityController extends Controller
{
    public function index()
    {
        $cities = City::with('country')->orderBy('name')->paginate(50);
        return Inertia::render('Admin/Cities/Index', ['cities' => $cities]);
    }

    public function create()
    {
        $countries = Country::orderBy('name')->get(['id','name']);
        return Inertia::render('Admin/Cities/Create', ['countries' => $countries]);
    }

    public function store(Request $request)
    {
        $request->validate([
            'name' => 'required|string',
            'country_id' => 'required|exists:countries,id',
        ]);

        City::create($request->only(['country_id','name','lat','lng']));

        return redirect()->route('admin.cities.index')->with('success', 'City created');
    }

    public function edit(City $city)
    {
        $countries = Country::orderBy('name')->get(['id','name']);
        return Inertia::render('Admin/Cities/Edit', ['city' => $city, 'countries' => $countries]);
    }

    public function update(Request $request, City $city)
    {
        $request->validate([
            'name' => 'required|string',
            'country_id' => 'required|exists:countries,id',
        ]);

        $city->update($request->only(['country_id','name','lat','lng']));

        return redirect()->route('admin.cities.index')->with('success', 'City updated');
    }

    public function destroy(City $city)
    {
        $city->delete();
        return redirect()->route('admin.cities.index')->with('success', 'City deleted');
    }
}
