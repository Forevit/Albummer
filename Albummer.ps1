#Requires -Version 5.1
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$userAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/121.0"
$maxJobs   = 6
$delayMs   = 100

function Show-Banner {
    Clear-Host
    $w = $Host.UI.RawUI.WindowWidth
    $title = "ALBUMMER"
    $sub   = "Download de sessoes Alboompro em alta resolucao"
    Write-Host ""
    Write-Host (" " * [Math]::Max(0, ($w - $title.Length) / 2) + $title) -ForegroundColor Yellow
    Write-Host (" " * [Math]::Max(0, ($w - $sub.Length) / 2) + $sub) -ForegroundColor DarkGray
    Write-Host ""
    Write-Host ("=" * $w) -ForegroundColor DarkYellow
    Write-Host ""
}

function Get-Urls {
    $form               = New-Object System.Windows.Forms.Form
    $form.Text          = "Albummer"
    $form.Size          = New-Object System.Drawing.Size(620, 480)
    $form.StartPosition = "CenterScreen"
    $form.BackColor     = [System.Drawing.Color]::FromArgb(18, 18, 18)
    $form.ForeColor     = [System.Drawing.Color]::FromArgb(240, 220, 160)
    $form.TopMost       = $true
    $form.FormBorderStyle = "FixedDialog"
    $form.MaximizeBox   = $false

    $label           = New-Object System.Windows.Forms.Label
    $label.Text      = "Cole as URLs do Alboompro abaixo (uma por linha):"
    $label.Location  = New-Object System.Drawing.Point(16, 16)
    $label.Size      = New-Object System.Drawing.Size(570, 22)
    $label.Font      = New-Object System.Drawing.Font("Segoe UI", 10)
    $label.ForeColor = [System.Drawing.Color]::FromArgb(180, 160, 120)

    $textbox              = New-Object System.Windows.Forms.TextBox
    $textbox.Multiline    = $true
    $textbox.ScrollBars   = "Vertical"
    $textbox.Location     = New-Object System.Drawing.Point(16, 44)
    $textbox.Size         = New-Object System.Drawing.Size(570, 350)
    $textbox.Font         = New-Object System.Drawing.Font("Consolas", 9)
    $textbox.BackColor    = [System.Drawing.Color]::FromArgb(28, 26, 24)
    $textbox.ForeColor    = [System.Drawing.Color]::FromArgb(220, 200, 140)
    $textbox.BorderStyle  = "FixedSingle"

    $btn              = New-Object System.Windows.Forms.Button
    $btn.Text         = "Iniciar Download"
    $btn.Location     = New-Object System.Drawing.Point(430, 406)
    $btn.Size         = New-Object System.Drawing.Size(156, 34)
    $btn.Font         = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $btn.BackColor    = [System.Drawing.Color]::FromArgb(180, 140, 60)
    $btn.ForeColor    = [System.Drawing.Color]::FromArgb(18, 18, 18)
    $btn.FlatStyle    = "Flat"
    $btn.FlatAppearance.BorderSize = 0
    $btn.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $form.AcceptButton = $btn

    $form.Controls.AddRange(@($label, $textbox, $btn))
    $result = $form.ShowDialog()

    if ($result -ne [System.Windows.Forms.DialogResult]::OK -or [string]::IsNullOrWhiteSpace($textbox.Text)) {
        Write-Host " Nenhuma URL informada. Encerrando." -ForegroundColor Red
        exit
    }

    $urls = $textbox.Text -split "`r`n|`r|`n" |
        ForEach-Object { $_.Trim() } |
        Where-Object { $_ -match "images-proof\.alboompro\.com" }

    if ($urls.Count -eq 0) {
        Write-Host " Nenhuma URL valida do Alboompro encontrada." -ForegroundColor Red
        exit
    }

    return $urls
}

function Get-OutputFolder {
    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $dialog.Description = "Escolha a pasta onde as fotos serao salvas"
    $dialog.ShowNewFolderButton = $true
    $result = $dialog.ShowDialog()

    if ($result -ne [System.Windows.Forms.DialogResult]::OK) {
        Write-Host " Nenhuma pasta selecionada. Encerrando." -ForegroundColor Red
        exit
    }

    return $dialog.SelectedPath
}

function Convert-Url($url) {
    $url = $url -replace "/width/\d+/",  "/width/3840/"
    $url = $url -replace "/height/\d+/", "/height/3840/"
    return $url
}

function Show-Progress($done, $total, $active, $errors) {
    $w      = [Math]::Max(40, [Math]::Min($Host.UI.RawUI.WindowWidth - 2, 90))
    $pct    = [int](($done / $total) * 100)
    $barW   = [Math]::Max(1, $w - 22)
    $filled = [Math]::Max(0, [int](($pct / 100) * $barW))
    $empty  = [Math]::Max(0, $barW - $filled)

    $bar   = "[" + ("#" * $filled) + ("-" * $empty) + "]"
    $stats = "  $bar $pct%"
    $info  = "  Concluidas: $done/$total"
    if ($active -gt 0) { $info += "  |  Em andamento: $active" }
    if ($errors -gt 0) { $info += "  |  Falhas: $errors" }

    $pos = $Host.UI.RawUI.CursorPosition
    $Host.UI.RawUI.CursorPosition = New-Object System.Management.Automation.Host.Coordinates 0, $pos.Y

    Write-Host ($stats.PadRight($w)) -ForegroundColor Yellow -NoNewline
    Write-Host ""
    Write-Host ($info.PadRight($w)) -ForegroundColor DarkGray -NoNewline

    $Host.UI.RawUI.CursorPosition = New-Object System.Management.Automation.Host.Coordinates 0, $pos.Y
}

function Start-Download($urls, $outputDir) {
    if (!(Test-Path $outputDir)) {
        New-Item -ItemType Directory -Path $outputDir | Out-Null
    }

    $total     = $urls.Count
    $completed = 0
    $errCount  = 0
    $errors    = [System.Collections.Concurrent.ConcurrentBag[string]]::new()
    $lock      = [System.Object]::new()

    Write-Host "  $total fotos para baixar" -ForegroundColor Cyan
    Write-Host "  Pasta: $outputDir" -ForegroundColor DarkGray
    Write-Host "  Paralelismo: $maxJobs conexoes simultaneas" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "" # linha da barra
    Write-Host "" # linha dos stats

    $jobs = @{}

    $i = 0
    while ($completed -lt $total) {

        # Dispara novos jobs ate o limite
        while ($jobs.Count -lt $maxJobs -and $i -lt $total) {
            $index   = $i + 1
            $fname   = "{0:D4}.jpg" -f $index
            $outPath = Join-Path $outputDir $fname
            $url3840 = Convert-Url $urls[$i]

            if (Test-Path $outPath) {
                [System.Threading.Interlocked]::Increment([ref]$completed) | Out-Null
                $i++
                continue
            }

            $job = Start-Job -ScriptBlock {
                param($url, $outPath, $ua)
                try {
                    $wr = [System.Net.WebRequest]::Create($url)
                    $wr.UserAgent = $ua
                    $wr.AllowAutoRedirect = $true
                    $wr.Timeout = 30000

                    $resp   = $wr.GetResponse()
                    $stream = $resp.GetResponseStream()
                    $fs     = [System.IO.File]::Create($outPath)
                    $buf    = New-Object byte[] 16384
                    do {
                        $read = $stream.Read($buf, 0, $buf.Length)
                        if ($read -gt 0) { $fs.Write($buf, 0, $read) }
                    } while ($read -gt 0)
                    $fs.Close(); $stream.Close(); $resp.Close()

                    $size = (Get-Item $outPath).Length
                    if ($size -lt 10000) {
                        Remove-Item $outPath -Force
                        return "ERRO:arquivo muito pequeno"
                    }
                    return "OK"
                } catch {
                    if (Test-Path $outPath) { Remove-Item $outPath -Force }
                    return "ERRO:$($_.Exception.Message)"
                }
            } -ArgumentList $url3840, $outPath, $userAgent

            $jobs[$job.Id] = @{ Job = $job; Name = $fname }
            $i++
        }

        # Coleta jobs prontos
        $done = @($jobs.Values | Where-Object { $_.Job.State -in @("Completed","Failed") })
        foreach ($entry in $done) {
            $result = Receive-Job $entry.Job
            Remove-Job $entry.Job

            if ($result -like "ERRO:*") {
                $errors.Add("$($entry.Name) - $($result.Substring(5))")
                $errCount++
            }

            $completed++
            $jobs.Remove($entry.Job.Id)
        }

        Show-Progress $completed $total $jobs.Count $errCount
        Start-Sleep -Milliseconds $delayMs
    }

    Write-Host ""
    Write-Host ""
    return $errors
}

#  Main 

Show-Banner

Write-Host "  [1/2] Cole as URLs na janela que vai abrir..." -ForegroundColor Cyan
Write-Host ""
$urls = Get-Urls

Show-Banner
Write-Host "  $($urls.Count) URLs validas detectadas." -ForegroundColor Green
Write-Host ""
Write-Host "  [2/2] Escolha a pasta de destino..." -ForegroundColor Cyan
Write-Host ""
$outputDir = Get-OutputFolder

Show-Banner
$errors = Start-Download $urls $outputDir

if ($errors.Count -eq 0) {
    Write-Host "  OK  Download concluido!" -ForegroundColor Green
    Write-Host "  $($urls.Count) foto(s) salva(s) em: $outputDir" -ForegroundColor Yellow
} else {
    $ok = $urls.Count - $errors.Count
    Write-Host "  Concluido com falhas. $ok foto(s) salva(s), $($errors.Count) erro(s):" -ForegroundColor Yellow
    foreach ($e in $errors) {
        Write-Host "    - $e" -ForegroundColor Red
    }
    Write-Host ""
    Write-Host "  Pasta: $outputDir" -ForegroundColor DarkGray
}

Write-Host ""
Write-Host "  Pressione qualquer tecla para fechar..." -ForegroundColor DarkGray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")