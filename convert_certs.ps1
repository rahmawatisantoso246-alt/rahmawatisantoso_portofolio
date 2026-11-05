Add-Type -AssemblyName System.Runtime.WindowsRuntime
$null = [Windows.Storage.StorageFile, Windows.Storage, ContentType = WindowsRuntime]
$null = [Windows.Data.Pdf.PdfDocument, Windows.Data.Pdf, ContentType = WindowsRuntime]
$null = [Windows.Data.Pdf.PdfPageRenderOptions, Windows.Data.Pdf, ContentType = WindowsRuntime]
$null = [Windows.Storage.Streams.IRandomAccessStream, Windows.Storage.Streams, ContentType = WindowsRuntime]

$asTaskGeneric = ([System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object { 
    $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1' 
})[0]

function AwaitOperation($op, $type) {
    $task = $asTaskGeneric.MakeGenericMethod($type).Invoke($null, @($op))
    $task.Wait()
    return $task.Result
}

$asTaskAction = ([System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object { 
    $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncAction' 
})[0]

function AwaitAction($act) {
    $task = $asTaskAction.Invoke($null, @($act))
    $task.Wait()
}

$certDir = "d:\DOKUMEN KULIAH RAHMA\PORTOFOLIO\Sertifikat"
$outDir = "d:\DOKUMEN KULIAH RAHMA\PORTOFOLIO\cert_images"
if (!(Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir | Out-Null }

$pdfs = Get-ChildItem -Path $certDir -Filter *.pdf
foreach ($p in $pdfs) {
    $pdfPath = $p.FullName
    $baseName = $p.BaseName
    $pngPath = Join-Path $outDir "$baseName.png"
    Write-Host "Converting $baseName..."
    
    $file = AwaitOperation ([Windows.Storage.StorageFile]::GetFileFromPathAsync($pdfPath)) ([Windows.Storage.StorageFile])
    $doc = AwaitOperation ([Windows.Data.Pdf.PdfDocument]::LoadFromFileAsync($file)) ([Windows.Data.Pdf.PdfDocument])
    
    $page = $doc.GetPage(0)
    if (Test-Path $pngPath) { Remove-Item $pngPath -Force }
    New-Item -ItemType File -Path $pngPath -Force | Out-Null
    $outFile = AwaitOperation ([Windows.Storage.StorageFile]::GetFileFromPathAsync($pngPath)) ([Windows.Storage.StorageFile])
    $stream = AwaitOperation ($outFile.OpenAsync([Windows.Storage.FileAccessMode]::ReadWrite)) ([Windows.Storage.Streams.IRandomAccessStream])
    
    $renderOpt = New-Object Windows.Data.Pdf.PdfPageRenderOptions
    $renderOpt.DestinationWidth = 1400
    AwaitAction ($page.RenderToStreamAsync($stream, $renderOpt))
    $stream.Dispose()
    Write-Host "Saved: $pngPath"
}
