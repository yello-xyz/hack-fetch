use namespace HH\Lib\C;
use type Facebook\HackTest\HackTest;
use function Facebook\FBExpect\expect;
use function Yello\HackFetch\fetch_async;

final class IntegrationTest extends HackTest {
  public async function testGetText(): Awaitable<void> {
    $response = await fetch_async('https://httpbin.org/get?param=23');
    $text = await $response->textAsync();
    expect(\substr($text, 0, 40))->toBeSame(
      "{\n  \"args\": {\n    \"param\": \"23\"\n  }, \n  ",
    );
  }

  public async function testGetJson(): Awaitable<void> {
    $response = await fetch_async('https://httpbin.org/get?name=foobar');
    $json = await $response->jsonAsync();
    expect($json->{'args'}->{'name'})->toBeSame('foobar');
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
    expect(\json_decode($json->{'data'})->{'param'})->toBeSame(23);
  }

  public async function testStreamResponse(): Awaitable<void> {
    $response =
      await fetch_async('https://httpbin.org/stream-bytes/100?chunk_size=1');
    $chunks = vec[];
    foreach ($response->body() await as $chunk) {
      $chunks[] = $chunk;
    }
    expect(C\count($chunks))->toBeGreaterThan(1);
    expect(\strlen(\HH\Lib\Str\join($chunks, '')))->toBeSame(100);
  }
}
