[CmdletBinding()]
param(
    [ValidateSet('auto', 'local', 'dev', 'test')]
    [string]$Environment = 'auto',

    [ValidateSet('direct', 'gateway')]
    [string]$Route = 'direct',

    [string]$ServicePrefix = '/scm',

    [ValidateSet('GET', 'POST', 'PUT', 'PATCH', 'DELETE')]
    [string]$Method = 'GET',

    [string]$Path,
    [string]$Body,

    [string]$BaseUrl = $env:CT_TEST_BASE_URL,
    [string]$AuthUrl = $env:CT_TEST_AUTH_URL,
    [string]$ScmUrl = $env:CT_TEST_SCM_URL,

    [string]$Username = $env:CT_TEST_USERNAME,
    [string]$Password = $env:CT_TEST_PASSWORD,
    [string]$Token = $env:CT_TEST_TOKEN,

    [int]$TokenTtlMinutes = 10,
    [switch]$RefreshToken,
    [switch]$LoginOnly,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

function Test-LocalPort {
    param([int]$Port)

    $client = [System.Net.Sockets.TcpClient]::new()
    try {
        $async = $client.BeginConnect('127.0.0.1', $Port, $null, $null)
        if (-not $async.AsyncWaitHandle.WaitOne(300)) {
            return $false
        }
        $client.EndConnect($async)
        return $true
    }
    catch {
        return $false
    }
    finally {
        $client.Close()
    }
}

function Resolve-EnvironmentName {
    if ($Environment -ne 'auto') {
        return $Environment
    }

    if ($env:CT_TEST_ENV -in @('local', 'dev', 'test')) {
        return $env:CT_TEST_ENV
    }

    $candidate = "$BaseUrl`n$AuthUrl`n$ScmUrl`n$Path"

    # 环境识别用的主机名：默认占位符，请替换为你的真实域名，
    # 或用 CT_DEV_HOST / CT_TEST_HOST 环境变量覆盖（推荐，避免域名入库）。
    $devHost = if ($env:CT_DEV_HOST) { [regex]::Escape($env:CT_DEV_HOST) } else { 'dev\.__CT_HOST__' }
    $testHost = if ($env:CT_TEST_HOST) { [regex]::Escape($env:CT_TEST_HOST) } else { 'test\.__CT_HOST__' }

    if ($candidate -match $devHost) {
        return 'dev'
    }
    if ($candidate -match $testHost) {
        return 'test'
    }
    if ($candidate -match '(127\.0\.0\.1|localhost)') {
        return 'local'
    }
    if ((Test-LocalPort 19200) -and (Test-LocalPort 19204)) {
        return 'local'
    }

    # 无法判断时按 skill 约定默认本地环境
    return 'local'
}

function Resolve-Endpoints {
    param([string]$Name)

    $map = @{
        local = @{
            Base = 'http://127.0.0.1:18080'
            Auth = 'http://127.0.0.1:19200'
            Scm  = 'http://127.0.0.1:19204'
        }
        dev = @{
            Base = 'https://__CT_DEV_HOST__/api'
            Auth = 'https://__CT_DEV_HOST__/api/auth'
            Scm  = 'https://__CT_DEV_HOST__/api/scm'
        }
        test = @{
            Base = 'https://__CT_TEST_HOST__/api'
            Auth = 'https://__CT_TEST_HOST__/api/auth'
            Scm  = 'https://__CT_TEST_HOST__/api/scm'
        }
    }

    $resolved = $map[$Name]
    if (-not $resolved) {
        throw "不支持的环境: $Name"
    }

    if ($BaseUrl) { $resolved.Base = $BaseUrl }
    if ($AuthUrl) { $resolved.Auth = $AuthUrl }
    if ($ScmUrl) { $resolved.Scm = $ScmUrl }

    return $resolved
}

$scriptHasBody = $PSBoundParameters.ContainsKey('Body')

$environmentName = Resolve-EnvironmentName
$endpoints = Resolve-Endpoints $environmentName
$tokenFile = if ($env:CT_TEST_TOKEN_FILE) { $env:CT_TEST_TOKEN_FILE } else { Join-Path $env:TEMP "ct-test-token-$environmentName.json" }

function Read-CachedToken {
    if (-not (Test-Path -LiteralPath $tokenFile)) {
        return $null
    }

    try {
        $cache = Get-Content -LiteralPath $tokenFile -Raw | ConvertFrom-Json
        if ($cache.token -and [datetime]$cache.expiresAt -gt (Get-Date)) {
            return [string]$cache.token
        }
    }
    catch {
    }

    Remove-Item -LiteralPath $tokenFile -ErrorAction SilentlyContinue
    return $null
}

function Save-CachedToken {
    param([string]$Value)

    $cache = [ordered]@{
        token     = $Value
        expiresAt = (Get-Date).AddMinutes($TokenTtlMinutes).ToString('o')
    } | ConvertTo-Json -Compress

    [System.IO.File]::WriteAllText($tokenFile, $cache, [System.Text.UTF8Encoding]::new($false))
}

function Get-AccessToken {
    param([switch]$ForceLogin)

    if ($Token -and -not $ForceLogin) {
        return $Token
    }

    if (-not $ForceLogin) {
        $cached = Read-CachedToken
        if ($cached) {
            return $cached
        }
    }

    if (-not $Username -or -not $Password) {
        throw '缺少可用 Token，且未设置 CT_TEST_USERNAME / CT_TEST_PASSWORD。'
    }

    $loginBody = @{
        username = $Username
        password = $Password
        code     = ''
        uuid     = ''
    } | ConvertTo-Json

    $loginUri = $endpoints.Auth.TrimEnd('/') + '/login'
    $login = Invoke-RestMethod -Uri $loginUri -Method Post -ContentType 'application/json' -Body $loginBody
    $accessToken = [string]$login.data.access_token

    if (-not $accessToken) {
        throw "登录失败: $($login | ConvertTo-Json -Compress)"
    }

    Save-CachedToken $accessToken
    return $accessToken
}

function Resolve-RequestUri {
    if (-not $Path) {
        return @{
            BaseUrl     = if ($Route -eq 'gateway') { $endpoints.Base } else { $endpoints.Scm }
            RequestPath = '/'
        }
    }

    $baseUrl = if ($Route -eq 'gateway') { $endpoints.Base } else { $endpoints.Scm }
    $requestPath = $Path

    if ($Route -eq 'gateway') {
        if ($requestPath.StartsWith('/auth')) {
            $baseUrl = $endpoints.Base
        }
        elseif ($ServicePrefix -and -not $requestPath.StartsWith($ServicePrefix)) {
            $requestPath = $ServicePrefix + $requestPath
        }
    }

    return @{
        BaseUrl     = $baseUrl
        RequestPath = $requestPath
    }
}

function Invoke-TestRequest {
    param([string]$AccessToken)

    if (-not $Path) {
        throw '调用 API 时必须提供 -Path。'
    }

    $resolvedUri = Resolve-RequestUri
    $uri = $resolvedUri.BaseUrl.TrimEnd('/') + '/' + $resolvedUri.RequestPath.TrimStart('/')
    $request = @{
        Uri                = $uri
        Method             = $Method
        Headers            = @{ Authorization = "Bearer $AccessToken" }
        SkipHttpErrorCheck = $true
    }

    if ($scriptHasBody) {
        $request.ContentType = 'application/json'
        $request.Body = $Body
    }

    $response = Invoke-WebRequest @request

    if ([int]$response.StatusCode -eq 401 -and $Username -and $Password) {
        Remove-Item -LiteralPath $tokenFile -ErrorAction SilentlyContinue
        $newToken = Get-AccessToken -ForceLogin
        $request.Headers = @{ Authorization = "Bearer $newToken" }
        $response = Invoke-WebRequest @request
        $AccessToken = $newToken
    }

    $json = $null
    try {
        $json = $response.Content | ConvertFrom-Json
    }
    catch {
    }

    [pscustomobject]@{
        environment = $environmentName
        ok          = ([int]$response.StatusCode -ge 200 -and [int]$response.StatusCode -lt 300)
        statusCode  = [int]$response.StatusCode
        uri         = $uri
        json        = $json
        raw         = $response.Content
    } | ConvertTo-Json -Depth 12
}

if ($DryRun) {
    $resolvedUri = Resolve-RequestUri
    $requestUri = $resolvedUri.BaseUrl.TrimEnd('/') + '/' + $resolvedUri.RequestPath.TrimStart('/')
    [pscustomobject]@{
        environment = $environmentName
        route       = $Route
        authUrl     = $endpoints.Auth
        baseUrl     = $resolvedUri.BaseUrl
        requestUri  = $requestUri
        dryRun      = $true
    } | ConvertTo-Json -Compress
    exit 0
}

$accessToken = Get-AccessToken -ForceLogin:$RefreshToken

if ($LoginOnly) {
    [pscustomobject]@{
        environment = $environmentName
        authUrl     = $endpoints.Auth
        ok          = $true
        hasToken    = [bool]$accessToken
        tokenLength = $accessToken.Length
        tokenFile   = $tokenFile
    } | ConvertTo-Json -Compress
    exit 0
}

Invoke-TestRequest -AccessToken $accessToken