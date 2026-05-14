$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add('http://127.0.0.1:8080/')
$listener.Prefixes.Add('http://localhost:8080/')
$listener.Start()
function Get-Mime([string]$ext) {
  switch ($ext.ToLower()) {
    '.html' { return 'text/html; charset=utf-8' }
    '.htm'  { return 'text/html; charset=utf-8' }
    '.mp4'  { return 'video/mp4' }
    '.css'  { return 'text/css; charset=utf-8' }
    '.js'   { return 'application/javascript; charset=utf-8' }
    '.json' { return 'application/json; charset=utf-8' }
    '.png'  { return 'image/png' }
    '.jpg'  { return 'image/jpeg' }
    '.jpeg' { return 'image/jpeg' }
    '.ico'  { return 'image/x-icon' }
    '.svg'  { return 'image/svg+xml' }
    default { return 'application/octet-stream' }
  }
}
Write-Host "Serving $root at http://localhost:8080/"
while ($listener.IsListening) {
  $ctx = $listener.GetContext()
  $req = $ctx.Request
  $res = $ctx.Response
  try {
    $path = [Uri]::UnescapeDataString($req.Url.AbsolutePath)
    if ($path -eq '' -or $path -eq '/') { $path = '/index.html' }
    $rel = $path.TrimStart('/').Replace('/', [IO.Path]::DirectorySeparatorChar)
    $local = Join-Path $root $rel
    $full = [IO.Path]::GetFullPath($local)
    $rootFull = [IO.Path]::GetFullPath($root)
    if (-not $full.StartsWith($rootFull, [StringComparison]::OrdinalIgnoreCase)) {
      $res.StatusCode = 403
      continue
    }
    if (-not (Test-Path -LiteralPath $full -PathType Leaf)) {
      $res.StatusCode = 404
      continue
    }
    $ext = [IO.Path]::GetExtension($full)
    $res.ContentType = Get-Mime $ext
    $len = (Get-Item -LiteralPath $full).Length
    $res.ContentLength64 = $len
    if ($req.HttpMethod -eq 'HEAD') { continue }
    $bytes = [IO.File]::ReadAllBytes($full)
    $res.OutputStream.Write($bytes, 0, $bytes.Length)
  }
  catch { $res.StatusCode = 500 }
  finally { $res.Close() }
}
