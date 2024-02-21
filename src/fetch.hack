namespace Yello\HackFetch;

interface Response {
  public function headers(): dict<string, string>;
  public function status(): int;
  public function ok(): bool;
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
  private string $buffered_output = '';
  private ?string $first_response = null;
  private int $status = -1;
  private dict<string, string> $headers = dict[];

  public function __construct(string $url, RequestOptions $options) {
    $this->curl_handle = \curl_init($url);
    $this->initializeOptions($options);

    $this->multi_handle = \curl_multi_init();
    \curl_multi_add_handle($this->multi_handle, $this->curl_handle);
  }

  public async function consumeFirstResponseAsync(): Awaitable<void> {
    foreach ($this->consumeResponses() await as $response) {
      $this->first_response = $response;
      break;
    }
  }

  public async function body(): AsyncIterator<string> {
    if ($this->first_response) {
      yield $this->first_response;
    }
    foreach ($this->consumeResponses() await as $response) {
      yield $response;
    }
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

  public function headers(): dict<string, string> {
    return $this->headers;
  }

  public function status(): int {
    return $this->status;
  }

  public function ok(): bool {
    return $this->status >= 200 && $this->status < 300;
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
      ($ch, $chunk) ==> {
        $this->buffered_output .= $chunk;
        $this->status = \curl_getinfo($ch, \CURLINFO_RESPONSE_CODE);
        return \strlen($chunk);
      },
    );

    \curl_setopt(
      $this->curl_handle,
      \CURLOPT_HEADERFUNCTION,
      ($_ch, $header) ==> {
        $key_value = \explode(':', $header, 2);
        if (\count($key_value) === 2) {
          $this->headers[\strtolower(\trim($key_value[0]))] = \trim($key_value[1]);
        }
        return \strlen($header);
      },
    );
  }

  private async function consumeResponses(): AsyncIterator<string> {
    do {
      $active = 1;
      do {
        $status = \curl_multi_exec($this->multi_handle, inout $active);
      } while ($status === \CURLM_CALL_MULTI_PERFORM);

      $buffered_output = $this->buffered_output;
      if (!\HH\Lib\Str\is_empty($buffered_output)) {
        $this->buffered_output = '';
        yield $buffered_output;
      }

      if (!$active) {
        break;
      }

      // HHAST_IGNORE_ERROR[DontAwaitInALoop]
      await \curl_multi_await($this->multi_handle);
    } while ($status === \CURLM_OK);

    $this->status = \curl_getinfo($this->curl_handle, \CURLINFO_RESPONSE_CODE);
    $error = \curl_error($this->curl_handle);

    $this->close();

    if ($error) {
      $error_code = \curl_errno($this->curl_handle);
      throw new \Exception($error, $error_code);
    }
  }
}

async function fetch_async(
  string $url,
  RequestOptions $options =
    shape('method' => 'GET', 'body' => null, 'headers' => dict[]),
): Awaitable<Response> {
  $client = new Client($url, $options);
  await $client->consumeFirstResponseAsync();
  return $client;
}
