<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Country;
use Illuminate\Http\Request;
use Inertia\Inertia;

class CountryController extends Controller
{
    public function index()
    {
        $countries = Country::orderBy('name')->paginate(25);
        return Inertia::render('Admin/Countries/Index', ['countries' => $countries]);
    }

    public function create()
    {
        return Inertia::render('Admin/Countries/Create');
    }

    public function store(Request $request)
    {
        $request->validate(['name' => 'required|string|unique:countries,name']);

        Country::create(['name' => $request->name, 'iso_code' => $request->iso_code]);

        return redirect()->route('admin.countries.index')->with('success', 'Country created');
    }

    public function edit(Country $country)
    {
        return Inertia::render('Admin/Countries/Edit', ['country' => $country]);
    }

    public function update(Request $request, Country $country)
    {
        $request->validate(['name' => 'required|string|unique:countries,name,' . $country->id]);

        $country->update(['name' => $request->name, 'iso_code' => $request->iso_code]);

        return redirect()->route('admin.countries.index')->with('success', 'Country updated');
    }

    public function destroy(Country $country)
    {
        $country->delete();
        return redirect()->route('admin.countries.index')->with('success', 'Country deleted');
    }
}
