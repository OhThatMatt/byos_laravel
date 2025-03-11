<?php

namespace Database\Seeders;

use App\Models\Device;
use App\Models\Plugin;
use App\Models\User;
use Illuminate\Database\Seeder;

// use Illuminate\Database\Console\Seeds\WithoutModelEvents;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        if (app()->isLocal()) {
            User::factory()->create([
                'name' => 'Test User',
                'email' => 'admin@example.com',
                'password' => bcrypt('admin@example.com'),
            ]);

            // Device::factory(5)->create();

            // Plugin::factory(3)->create();
        }
    }
}
