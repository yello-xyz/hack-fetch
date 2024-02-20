use type Facebook\HackTest\HackTest;
use function Facebook\FBExpect\expect;
use function Yello\HackFetch\fetch_async;

final class IntegrationTest extends HackTest {
  public async function testGetText(): Awaitable<void> {
    $response =
      await fetch_async('https://jsonplaceholder.typicode.com/posts/1');
    $text = await $response->textAsync();
    expect(\substr($text, 0, 20))->toBeSame("{\n  \"userId\": 1,\n  \"");
  }

  public async function testGetJson(): Awaitable<void> {
    $response =
      await fetch_async('https://jsonplaceholder.typicode.com/posts/1');
    $json = await $response->jsonAsync();
    expect($json->{'title'})->toBeSame(
      'sunt aut facere repellat provident occaecati excepturi optio reprehenderit',
    );
  }

  public async function testPostJson(): Awaitable<void> {
    $response = await fetch_async(
      'https://jsonplaceholder.typicode.com/posts',
      shape(
        'method' => 'POST',
        'body' =>
          \json_encode(shape('title' => 'foo', 'body' => 'bar', 'userId' => 1)),
        'headers' => dict['content-type' => 'application/json'],
      ),
    );
    $json = await $response->jsonAsync();
    expect($json->{'title'})->toBeSame('foo');
  }
}
