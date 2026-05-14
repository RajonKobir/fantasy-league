<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Country;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

class CountryController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $q = $request->get('q');
        $query = Country::query();

        if ($q) {
            $query->where('name', 'like', "%{$q}%");
        }

        $countries = $query->orderBy('name')->limit(50)->get(['id', 'name', 'iso_code']);

        return response()->json(['success' => true, 'data' => $countries]);
    }

    public function show(Country $country): JsonResponse
    {
        return response()->json(['success' => true, 'data' => $country]);
    }
}
