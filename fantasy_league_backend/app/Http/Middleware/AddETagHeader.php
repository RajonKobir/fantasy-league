<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class AddETagHeader
{
    /**
     * Handle an incoming request.
     *
     * @param  \Closure(\Illuminate\Http\Request): (\Symfony\Component\HttpFoundation\Response)  $next
     */
    public function handle(Request $request, Closure $next): Response
    {
        $response = $next($request);

        // Only add ETag for GET requests and JSON responses
        if ($request->isMethod('GET') && $response->headers->get('content-type') === 'application/json') {
            $content = $response->getContent();

            // Generate ETag as MD5 hash of response content
            if ($content) {
                $etag = '"' . md5($content) . '"';

                // Check if client sent If-None-Match header
                if ($request->header('If-None-Match') === $etag) {
                    // Return 304 Not Modified
                    return response('', 304)->header('ETag', $etag);
                }

                // Add ETag header to response
                $response->header('ETag', $etag);
                $response->header('Cache-Control', 'private, must-revalidate');
            }
        }

        return $response;
    }
}
