<?php

use App\Http\Controllers\Api\{
    EvaluationController
};
use Illuminate\Support\Facades\Route;

Route::get('/', fn () => response()->json(['message' => env('APP_NAME')]));

Route::get('/evaluations/{company}', [EvaluationController::class, 'index']);
Route::post('/evaluations/{company}', [EvaluationController::class, 'store']);
