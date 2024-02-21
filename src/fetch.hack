namespace Yello\HackFetch;

interface Response {
  public function body(): AsyncIterator<string>;
  public function textAsync(): Awaitable<string>;
  public function jsonAsync(): Awaitable<mixed>;
}

final class AsyncResponse implements Response {
  private AsyncIterator<string> $iterator;

  public function __construct(AsyncIterator<string> $iterator) {
    $this->iterator = $iterator;
  }

  public function body(): AsyncIterator<string> {
    return $this->iterator;
  }

  public async function textAsync(): Awaitable<string> {
    $text = '';
    foreach ($this->body() await as $chunk) {
      $text .= $chunk;
    }
    return $text;
  }

  public async function jsonAsync(): Awaitable<mixed> {
    $text = await $this->textAsync();
    return \json_decode($text);
  }
}

type RequestOptions = shape(
  ?'method' => string,
  ?'body' => ?string,
  ?'headers' => dict<string, string>,
);

async function fetch_async(
  string $url,
  RequestOptions $options =
    shape('method' => 'GET', 'body' => null, 'headers' => dict[]),
): Awaitable<Response> {
  $stream_async = async () ==> {
    $ch = \curl_init($url);

    if (Shapes::idx($options, 'method') === 'POST') {
      \curl_setopt($ch, \CURLOPT_POST, 1);
    }

    $headers = Shapes::idx($options, 'headers');
    if ($headers !== null) {
      $headers_list = vec(
        \HH\Lib\Dict\map_with_key(
          $headers,
          ($key, $value) ==> $key.': '.$value,
        ),
      );
      \curl_setopt($ch, \CURLOPT_HTTPHEADER, $headers_list);
    }

    $body = Shapes::idx($options, 'body');
    if ($body !== null) {
      \curl_setopt($ch, \CURLOPT_POSTFIELDS, $body);
    }

    $result = new \HH\Lib\Ref('');
    \curl_setopt($ch, \CURLOPT_RETURNTRANSFER, true);
    \curl_setopt($ch, \CURLOPT_WRITEFUNCTION, ($_ch, $chunk) ==> {
      $result->set($result->get().$chunk);
      return \strlen($chunk);
    });

    $mh = \curl_multi_init();
    \curl_multi_add_handle($mh, $ch);

    do {
      $active = 1;
      do {
        $status = \curl_multi_exec($mh, inout $active);
      } while ($status === \CURLM_CALL_MULTI_PERFORM);
      if (!\HH\Lib\Str\is_empty($result->get())) {
        yield $result->get();
        $result->set('');
      }
      if (!$active) {
        break;
      }
      // HHAST_IGNORE_ERROR[DontAwaitInALoop]
      await \curl_multi_await($mh);
    } while ($status === \CURLM_OK);

    \curl_multi_remove_handle($mh, $ch);
    \curl_close($ch);
    \curl_multi_close($mh);
  };

  $responses = $stream_async();
  $firstResponse = null;
  foreach ($responses await as $response) {
    $firstResponse = $response;
    break;
  }

  $iterator = async () ==> {
    if ($firstResponse) {
      yield $firstResponse;
    }
    foreach ($responses await as $response) {
      yield $response;
    }
  };

  return new AsyncResponse($iterator());
}
