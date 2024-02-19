namespace Yello\HackFetch;

interface Response {
  public function text(): Awaitable<string>;
  public function json(): Awaitable<mixed>;
}

class RawResponse implements Response {
  private string $raw_response;

  public function __construct(string $raw_response) {
     $this->raw_response = $raw_response;
  }

  public async function text(): Awaitable<string> {
    return $this->raw_response;
  }

  public async function json(): Awaitable<mixed> {
    return \json_decode($this->raw_response);
  }
}

async function fetch_async(
  string $url,
  shape(?'method' => string) $options = shape('method' => 'GET'))
: Awaitable<Response> {
  $ch = \curl_init();

  \curl_setopt($ch, \CURLOPT_URL, $url);
  \curl_setopt($ch, \CURLOPT_RETURNTRANSFER, 1);

  if (Shapes::idx($options, 'method') === 'POST') {
    \curl_setopt($ch, \CURLOPT_POST, 1);
  }

  $result = await \HH\Asio\curl_exec($ch);
  \curl_close($ch);
  return new RawResponse($result);
}

async function post_json_async(
  string $url,
  vec<string> $headers = vec[],
  mixed $payload = dict[],
): Awaitable<string> {
  $ch = \curl_init();
  \curl_setopt($ch, \CURLOPT_POST, 1);
  \curl_setopt($ch, \CURLOPT_URL, $url);
  $headers[] = 'content-type: application/json';
  \curl_setopt($ch, \CURLOPT_HTTPHEADER, $headers);
  \curl_setopt($ch, \CURLOPT_POSTFIELDS, \json_encode($payload));
  \curl_setopt($ch, \CURLOPT_RETURNTRANSFER, 1);
  $result = await \HH\Asio\curl_exec($ch);
  \curl_close($ch);
  return $result;
}
