# HackFetch
Simple cURL wrapper for Hacklang. Basic HTTP client API inspired by [node-fetch](https://www.npmjs.com/package/node-fetch).
## Common Usage
### Plain text or HTML
```Hack
use function Yello\HackFetch\fetch_async;

$response = await fetch_async('https://github.com/');
$body = await $response->textAsync();

echo $body;
```
### JSON response
```Hack
use function Yello\HackFetch\fetch_async;

$response = await fetch_async('https://api.github.com/users/github');
$data = await $response->jsonAsync();

echo $data;
```
### Simple form post
```Hack
use function Yello\HackFetch\fetch_async;

$response = await fetch_async(
  'https://httpbin.org/post',
  shape('method' => 'POST', 'body' => 'a=1'),
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
    'body' => \json_encode(shape('a' => 1)),
    'headers' => dict['content-type' => 'application/json'],
  ),
);
$data = await $response->jsonAsync();

echo $data;
```
### Accessing headers and other metadata
```Hack
use function Yello\HackFetch\fetch_async;

$response = await fetch_async('https://github.com/');

echo $response->ok() ? "OK" : "NOK";
echo $response->status();
echo $response->headers()['content-type'];
```
### Handling client and server errors
Note that 3xx-5xx responses are *not* exceptions.
```Hack
use function Yello\HackFetch\fetch_async;

$response = await fetch_async('https://httpbin.org/status/400');
if ($response->ok()) {
  // status >= 200 && status < 300
} else {
  echo $response->status(); // 400
}
```
### Handling exceptions
Wrapping the fetch function into a try/catch block will catch all exceptions, including errors originating from core libraries, network errors, and operational errors.
```Hack
use function Yello\HackFetch\fetch_async;

try {
  await fetch_async('https://domain.invalid');
} catch (\Exception $e) {
  echo $e->getMessage(); // Could not resolve host: domain.invalid
}
```
### Streams
You can use async iterators to read the response body.
```Hack
use function Yello\HackFetch\fetch_async;

$response = 
  await fetch_async('https://httpbin.org/stream/3');

foreach ($response->body() await as $chunk) {
  echo $chunk;
}
```
### File download
```Hack
use function Yello\HackFetch\fetch_async;

$file = fopen($file_name, 'w');
$response = await fetch_async('https://httpbin.org/image/png');
foreach ($response->body() await as $chunk) {
  fwrite($file, $chunk);
}
fclose($file);
```
### File upload
```Hack
use function Yello\HackFetch\fetch_async;

$file = fopen('test.png', 'r');
$response =
  await fetch_async('https://httpbin.org/anything', shape('file' => $file));
fclose($file);

echo $response->status();
```
