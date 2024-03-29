use type Facebook\HackTest\HackTest;
use function Facebook\FBExpect\expect;
use function Yello\HackFetch\fetch_async;

final class IntegrationTest extends HackTest {
  public async function testGetText(): Awaitable<void> {
    $response = await fetch_async('https://httpbin.org/get?param=23');
    $text = await $response->textAsync();
    expect($response->ok())->toBeTrue();
    expect($response->status())->toBeSame(200);
    expect(\substr($text, 0, 40))->toBeSame(
      "{\n  \"args\": {\n    \"param\": \"23\"\n  }, \n  ",
    );
  }

  public async function testGetJson(): Awaitable<void> {
    $response = await fetch_async('https://httpbin.org/get?name=foobar');
    $json = await $response->jsonAsync();
    expect($response->ok())->toBeTrue();
    expect($response->status())->toBeSame(200);
    expect($response->headers()['content-type'])->toBeSame('application/json');
    expect($json->{'args'}->{'name'})->toBeSame('foobar');
  }

  public async function testSimplePost(): Awaitable<void> {
    $response = await fetch_async(
      'https://httpbin.org/post',
      shape('method' => 'POST', 'body' => 'param=23'),
    );
    $json = await $response->jsonAsync();
    expect($response->ok())->toBeTrue();
    expect($response->status())->toBeSame(200);
    expect($json->{'form'}->{'param'})->toBeSame('23');
  }

  public async function testPostJson(): Awaitable<void> {
    $response = await fetch_async(
      'https://httpbin.org/post',
      shape(
        'method' => 'POST',
        'body' => \json_encode(shape('param' => 23, 'name' => 'foobar')),
        'headers' => dict['content-type' => 'application/json'],
      ),
    );
    $json = await $response->jsonAsync();
    expect($response->ok())->toBeTrue();
    expect($response->status())->toBeSame(200);
    expect(\json_decode($json->{'data'})->{'param'})->toBeSame(23);
  }

  public async function testStreamResponse(): Awaitable<void> {
    $response =
      await fetch_async('https://httpbin.org/stream-bytes/100?chunk_size=1');
    $chunks = vec[];
    foreach ($response->body() await as $chunk) {
      $chunks[] = $chunk;
    }
    expect($response->ok())->toBeTrue();
    expect($response->status())->toBeSame(200);
    expect($response->headers()['content-type'])->toBeSame(
      'application/octet-stream',
    );
    expect(\count($chunks))->toBeGreaterThan(1);
    expect(\strlen(\HH\Lib\Str\join($chunks, '')))->toBeSame(100);
  }

  public async function testStatus(): Awaitable<void> {
    $response = await fetch_async('https://httpbin.org/status/300');
    expect($response->ok())->toBeFalse();
    expect($response->status())->toBeSame(300);
  }

  public async function testNotFound(): Awaitable<void> {
    $response = await fetch_async('https://httpbin.org/not-found');
    expect($response->ok())->toBeFalse();
    expect($response->status())->toBeSame(404);
    expect($response->headers()['content-type'])->toBeSame('text/html');
  }

  public async function testInvalidDomain(): Awaitable<void> {
    try {
      await fetch_async('https://domain.invalid');
      expect(true)->toBeFalse();
    } catch (\Exception $e) {
      expect($e->getMessage())->toBeSame(
        'Could not resolve host: domain.invalid',
      );
    }
  }

  public async function testFileTransfer(): Awaitable<void> {
    $file_name = 'test.png';
    $check_sum = '5cca6069f68fbf739fce37e0963f21e7';

    $response = await fetch_async('https://httpbin.org/image/png');
    $file = fopen($file_name, 'w');
    foreach ($response->body() await as $chunk) {
      fwrite($file, $chunk);
    }
    fclose($file);

    expect(\md5_file($file_name))->toBeSame($check_sum);

    $file = fopen($file_name, 'r');
    $response =
      await fetch_async('https://httpbin.org/anything', shape('file' => $file));
    fclose($file);
    \unlink($file_name);

    $json = await $response->jsonAsync();

    $file = fopen($file_name, 'w');
    fwrite($file, \base64_decode(\substr(
      $json->{'data'},
      \strlen('data:application/octet-stream;base64,'),
    )));
    fclose($file);

    expect(\md5_file($file_name))->toBeSame($check_sum);
    \unlink($file_name);
  }
}
