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
    ?'headers' => vec<string>) $options = shape('method' => 'GET', 'body' => null, 'headers' => vec[]))
: Awaitable<Response> {
  $ch = \curl_init();

  \curl_setopt($ch, \CURLOPT_URL, $url);
  \curl_setopt($ch, \CURLOPT_RETURNTRANSFER, 1);

  if (Shapes::idx($options, 'method') === 'POST') {
    \curl_setopt($ch, \CURLOPT_POST, 1);
  }

  $headers = Shapes::idx($options, 'headers');
  if ($headers !== null) {
    \curl_setopt($ch, \CURLOPT_HTTPHEADER, $headers);
  }

  $body = Shapes::idx($options, 'body');
  if ($body !== null) {
    \curl_setopt($ch, \CURLOPT_POSTFIELDS, $body);
  }

  $result = await \HH\Asio\curl_exec($ch);

  \curl_close($ch);

  return new RawResponse($result);
}
