Add-Type -AssemblyName System.Drawing

$logoPath = "v:\Projects\lost-n-found\logo.png"
$srcImg = [System.Drawing.Image]::FromFile($logoPath)

$sizes = @{
    'mipmap-mdpi' = 48
    'mipmap-hdpi' = 72
    'mipmap-xhdpi' = 96
    'mipmap-xxhdpi' = 144
    'mipmap-xxxhdpi' = 192
}

foreach ($entry in $sizes.GetEnumerator()) {
    $dir = $entry.Key
    $s = $entry.Value
    $targetBmp = New-Object System.Drawing.Bitmap($s, $s)
    $g = [System.Drawing.Graphics]::FromImage($targetBmp)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.Clear([System.Drawing.Color]::Transparent)
    $g.DrawImage($srcImg, 0, 0, $s, $s)
    $g.Dispose()

    $targetDir = "v:\Projects\lost-n-found\frontend\android\app\src\main\res\$dir"
    if (-not (Test-Path $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    }
    $outPath = "$targetDir\ic_launcher.png"
    $targetBmp.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $targetBmp.Dispose()
    Write-Host "Generated $outPath ($s x $s)"
}

# Also generate Windows app_icon.ico
$icoPath = "v:\Projects\lost-n-found\frontend\windows\runner\resources\app_icon.ico"
$icoBmp = New-Object System.Drawing.Bitmap($srcImg, 256, 256)
$hIcon = $icoBmp.GetHicon()
$icon = [System.Drawing.Icon]::FromHandle($hIcon)
$fileStream = New-Object System.IO.FileStream($icoPath, [System.IO.FileMode]::Create)
$icon.Save($fileStream)
$fileStream.Close()
$icoBmp.Dispose()
Write-Host "Generated $icoPath"

$srcImg.Dispose()
