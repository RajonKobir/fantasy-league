<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\City;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

class CityController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $q = $request->get('q');
        $countryId = $request->get('country_id');

        $query = City::query()->with('country');

        if ($countryId) {
            $query->where('country_id', $countryId);
        }

        if ($q) {
            $query->where('name', 'like', "%{$q}%");
        }

        $cities = $query->orderBy('name')->limit(100)->get(['id', 'country_id', 'name', 'lat', 'lng']);

        return response()->json(['success' => true, 'data' => $cities]);
    }

    public function show(City $city): JsonResponse
    {
        return response()->json(['success' => true, 'data' => $city]);
    }
}
