namespace Yello\HackFetch;

interface Response {
  public function body(): AsyncIterator<string>;
  public function textAsync(): Awaitable<string>;
  public function jsonAsync(): Awaitable<mixed>;
}

type RequestOptions = shape(
  ?'method' => string,
  ?'body' => ?string,
  ?'headers' => dict<string, string>,
);

final class Client implements Response {
  private resource $curl_handle;
  private resource $multi_handle;
  private bool $active = false;
  private string $buffered_output = '';

  public function body(): AsyncIterator<string> {
    return $this->consume();
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

  public function __construct(string $url, RequestOptions $options) {
    $this->curl_handle = \curl_init($url);
    $this->initializeOptions($options);

    $this->multi_handle = \curl_multi_init();
    \curl_multi_add_handle($this->multi_handle, $this->curl_handle);
  }

  public async function initializeAsync(): Awaitable<void> {
    $this->execOnce();
  }

  public function __dispose(): void {
    $this->close();
  }

  private function close(): void {
    \curl_multi_remove_handle($this->multi_handle, $this->curl_handle);
    \curl_close($this->curl_handle);
    \curl_multi_close($this->multi_handle);
  }

  private function initializeOptions(RequestOptions $options): void {
    if (Shapes::idx($options, 'method') === 'POST') {
      \curl_setopt($this->curl_handle, \CURLOPT_POST, 1);
    }

    $headers = Shapes::idx($options, 'headers');
    if ($headers !== null) {
      $headers_list = vec(
        \HH\Lib\Dict\map_with_key(
          $headers,
          ($key, $value) ==> $key.': '.$value,
        ),
      );
      \curl_setopt($this->curl_handle, \CURLOPT_HTTPHEADER, $headers_list);
    }

    $body = Shapes::idx($options, 'body');
    if ($body !== null) {
      \curl_setopt($this->curl_handle, \CURLOPT_POSTFIELDS, $body);
    }

    \curl_setopt($this->curl_handle, \CURLOPT_RETURNTRANSFER, true);

    \curl_setopt(
      $this->curl_handle,
      \CURLOPT_WRITEFUNCTION,
      ($_ch, $chunk) ==> {
        $this->buffered_output .= $chunk;
        return \strlen($chunk);
      },
    );
  }

  private async function consume(): AsyncIterator<string> {
    do {
      if (!\HH\Lib\Str\is_empty($this->buffered_output)) {
        yield $this->buffered_output;
        $this->buffered_output = '';
      }
      if (!$this->active) {
        break;
      }
      // HHAST_IGNORE_ERROR[DontAwaitInALoop]
      await \curl_multi_await($this->multi_handle);
      $this->execOnce();
    } while (true);

    // $reponse_code = \curl_getinfo($this->curl_handle, \CURLINFO_RESPONSE_CODE);

    $this->close();
  }

  private function execOnce(): void {
    $active = 1;
    do {
      $status = \curl_multi_exec($this->multi_handle, inout $active);
    } while ($status === \CURLM_CALL_MULTI_PERFORM);
    $this->active = $active && $status === \CURLM_OK;
  }
}

async function fetch_async(
  string $url,
  RequestOptions $options =
    shape('method' => 'GET', 'body' => null, 'headers' => dict[]),
): Awaitable<Response> {
  $client = new Client($url, $options);
  await $client->initializeAsync();
  return $client;
}
