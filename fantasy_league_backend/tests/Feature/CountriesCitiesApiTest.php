<?php

namespace Tests\Feature;

use App\Models\Country;
use App\Models\City;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class CountriesCitiesApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_countries_index_returns_list()
    {
        Country::create(['name' => 'Testland']);
        $res = $this->getJson('/api/countries');
        $res->assertStatus(200)->assertJson(['success' => true]);
        $this->assertNotEmpty($res->json('data'));
    }

    public function test_cities_index_filters_by_country()
    {
        $country = Country::create(['name' => 'CityCountry']);
        City::create(['country_id' => $country->id, 'name' => 'Sample City']);

        $res = $this->getJson('/api/cities?country_id=' . $country->id);
        $res->assertStatus(200)->assertJson(['success' => true]);
        $this->assertCount(1, $res->json('data'));
    }
}
