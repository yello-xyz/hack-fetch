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
