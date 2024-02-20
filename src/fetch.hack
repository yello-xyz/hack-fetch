namespace Yello\HackFetch;

interface Response {
  public function textAsync(): Awaitable<string>;
  public function jsonAsync(): Awaitable<mixed>;
}

final class RawResponse implements Response {
  private string $raw_response;

  public function __construct(string $raw_response) {
    $this->raw_response = $raw_response;
  }

  public async function textAsync(): Awaitable<string> {
    return $this->raw_response;
  }

  public async function jsonAsync(): Awaitable<mixed> {
    return \json_decode($this->raw_response);
  }
}

async function fetch_async(
  string $url,
  shape(
    ?'method' => string,
    ?'body' => ?string,
    ?'headers' => dict<string, string>,
  ) $options = shape('method' => 'GET', 'body' => null, 'headers' => dict[]),
): Awaitable<Response> {
  $ch = \curl_init();

  \curl_setopt($ch, \CURLOPT_URL, $url);
  \curl_setopt($ch, \CURLOPT_RETURNTRANSFER, true);

  if (Shapes::idx($options, 'method') === 'POST') {
    \curl_setopt($ch, \CURLOPT_POST, 1);
  }

  $headers = Shapes::idx($options, 'headers');
  if ($headers !== null) {
    $headers_list = vec(
      \HH\Lib\Dict\map_with_key($headers, ($key, $value) ==> $key.': '.$value),
    );
    \curl_setopt($ch, \CURLOPT_HTTPHEADER, $headers_list);
  }

  $body = Shapes::idx($options, 'body');
  if ($body !== null) {
    \curl_setopt($ch, \CURLOPT_POSTFIELDS, $body);
  }

  $result = new \HH\Lib\Ref('');
  \curl_setopt($ch, \CURLOPT_WRITEFUNCTION, function(
    $ch,
    $chunk,
  ) use ($result) {
    $result->set($result->get().$chunk);
    return \strlen($chunk);
  });

  \curl_exec($ch);
  \curl_close($ch);

  return new RawResponse($result->get());
}

async function stream_async(
  string $url,
  shape(
    ?'method' => string,
    ?'body' => ?string,
    ?'headers' => dict<string, string>,
  ) $options = shape('method' => 'GET', 'body' => null, 'headers' => dict[]),
): AsyncIterator<string> {
  $ch = \curl_init();

  \curl_setopt($ch, \CURLOPT_URL, $url);
  \curl_setopt($ch, \CURLOPT_RETURNTRANSFER, true);

  if (Shapes::idx($options, 'method') === 'POST') {
    \curl_setopt($ch, \CURLOPT_POST, 1);
  }

  $headers = Shapes::idx($options, 'headers');
  if ($headers !== null) {
    $headers_list = vec(
      \HH\Lib\Dict\map_with_key($headers, ($key, $value) ==> $key.': '.$value),
    );
    \curl_setopt($ch, \CURLOPT_HTTPHEADER, $headers_list);
  }

  $body = Shapes::idx($options, 'body');
  if ($body !== null) {
    \curl_setopt($ch, \CURLOPT_POSTFIELDS, $body);
  }

  $result = new \HH\Lib\Ref('');
  \curl_setopt($ch, \CURLOPT_WRITEFUNCTION, function(
    $ch,
    $chunk,
  ) use ($result) {
    $result->set($result->get().$chunk);
    return \strlen($chunk);
  });

  $mh = \curl_multi_init();
  \curl_multi_add_handle($mh, $ch);

  do {
    $active = 1;
    do {
      $status = \curl_multi_exec($mh, inout $active);
    } while ($status == \CURLM_CALL_MULTI_PERFORM);
    if (!\HH\Lib\Str\is_empty($result->get())) {
      yield $result->get();
      $result->set('');
    }
    if (!$active) break;
    await \curl_multi_await($mh);
  } while ($status === \CURLM_OK);

  \curl_multi_remove_handle($mh, $ch);
  \curl_close($ch);
  \curl_multi_close($mh);
}
