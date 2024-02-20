# HackFetch
Simple cURL wrapper for Hacklang. API inspired by [node-fetch](https://www.npmjs.com/package/node-fetch)/`window.fetch`.
## Motivation
Wanted to play around with Hack but couldn't even find a basic HTTP client that wasn't completely abandoned.
## Basic usage
### Plain text or HTML
```Hack
use function Yello\HackFetch\fetch_async;

$response = await fetch_async('https://httpbin.org/get?param=23');
$body = await $response->textAsync();

echo $body;
```
### JSON
```Hack
use function Yello\HackFetch\fetch_async;

$response = await fetch_async('https://httpbin.org/get?name=foobar');
$data = await $response->jsonAsync();

echo $data;
```
### Simple Post
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
### Streams
```Hack
use function Yello\HackFetch\fetch_async;

$response = 
  await fetch_async('https://httpbin.org/stream-bytes/100?chunk_size=1');

foreach ($response->body() await as $chunk) {
  echo $chunk;
}
```
