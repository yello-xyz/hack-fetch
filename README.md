# HackFetch
Simple cURL wrapper for Hacklang. Basic HTTP client API inspired by [node-fetch](https://www.npmjs.com/package/node-fetch).
## Common Usage
### Plain text or HTML
```Hack
use function Yello\HackFetch\fetch_async;

$response = await fetch_async('https://httpbin.org/get?param=23');
$body = await $response->textAsync();

echo $body;
```
### JSON response
```Hack
use function Yello\HackFetch\fetch_async;

$response = await fetch_async('https://httpbin.org/get?name=foobar');
$data = await $response->jsonAsync();

echo $data;
```
### Simple form post
```Hack
use function Yello\HackFetch\fetch_async;

$response = await fetch_async(
  'https://httpbin.org/post',
  shape('method' => 'POST', 'body' => 'param=23'),
);
$data = await $response->jsonAsync();

echo $data;
```
### Post with JSON
```Hack
use function Yello\HackFetch\fetch_async;

$response = await fetch_async(
  'https://httpbin.org/post',
  shape(
    'method' => 'POST',
    'body' => \json_encode(shape('param' => 23, 'name' => 'foobar')),
    'headers' => dict['content-type' => 'application/json'],
  ),
);
$data = await $response->jsonAsync();

echo $data;
```
### Handling exceptions
Note that 3xx-5xx responses are *not* exceptions (see next section). Wrapping the fetch function into a try/catch block will catch all exceptions, including errors originating from core libraries, network errors, and operational errors.
```Hack
use function Yello\HackFetch\fetch_async;

try {
  await fetch_async('https://domain.invalid');
} catch (\Exception $e) {
  echo $e->getMessage(); // Could not resolve host: domain.invalid
}
```
### Handling client and server errors
```Hack
use function Yello\HackFetch\fetch_async;

$response = await fetch_async('https://httpbin.org/status/400');
if ($response->ok()) {
  // status >= 200 && status < 300
} else {
  echo $response->status(); // 400
}
```
### Streams
You can use async iterators to read the response body.
```Hack
use function Yello\HackFetch\fetch_async;

$response = 
  await fetch_async('https://httpbin.org/stream-bytes/100?chunk_size=1');

foreach ($response->body() await as $chunk) {
  echo $chunk;
}
```
