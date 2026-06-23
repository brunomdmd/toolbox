$dias_expiracao = 21 # Definir o número de dias antes da expiração da senha para enviar o e-mail de aviso
$log_path = "C:\script\logs\"
$log_file = "$log_path\$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss')_ad-email-senha.log"

if (-not (Test-Path $log_path)) {
    New-Item -ItemType Directory -Path $log_path | Out-Null
}

Start-Transcript -Path $log_file -Append

$usuarios = Get-ADUser -Filter {Enabled -eq $True -and PasswordNeverExpires -eq $False} `
    -Properties "DisplayName", "msDS-UserPasswordExpiryTimeComputed", "mail" `
| Where-Object { $_.mail -ne $null } `
| Select-Object -Property "DisplayName", `
    @{Name="ExpiryDate";Expression={[datetime]::FromFileTime($_."msDS-UserPasswordExpiryTimeComputed")}}, `
    "Mail", "SamAccountName" `
| Where-Object { $_.ExpiryDate -lt (Get-Date).AddDays($dias_expiracao) -and $_.ExpiryDate -gt (Get-Date) }

# Definir remetente, servidor SMTP e porta
$de   = "noreply@SEUDOMINIO.com.br"
$smtpserver = "SMTPSERVER"
$smtpport = SMTPPORT

foreach ($usuario in $usuarios) {
    $dias          = (([DateTime]$usuario.ExpiryDate) - (Get-Date)).Days
    $para          = $usuario.Mail
    $nomeExibicao  = $usuario.DisplayName
    $samAccount    = $usuario.SamAccountName
    $dominio       = (Get-ADDomain).Forest
    $assunto       = "Sua senha expira em $dias dias!"
    $dataFormatada = ([DateTime]$usuario.ExpiryDate).ToString('dd/MM/yyyy')
    $mensagem = @"
<html>
<body style="font-family: Arial, sans-serif; font-size: 14px; color: #333;">

  <p>Olá, <strong>$nomeExibicao</strong>!</p>

  <p>
    A senha da sua conta <strong>$dominio\$samAccountName</strong> irá expirar em 
    <strong style="color: #cc0000;">$dias dias</strong> 
    (<strong>$dataFormatada</strong>).
  </p>

  <hr style="border: none; border-top: 1px solid #ddd; margin: 20px 0;" />
  <p style="font-size: 12px; color: #888;">
    <strong>Segurança da Informação</strong><br/>
    Esta é uma mensagem automática, não responda este e-mail. 
  </p>

</body>
</html>
"@

    Write-Host "Enviando para: $para | $nomeExibicao | $dias dias restantes"
    Write-Host ('*' * 80)

    Send-MailMessage -Body $mensagem -BodyAsHtml -Encoding UTF8 -From $de -SmtpServer $smtpserver -Port $smtpport -Subject $assunto -To $para
}

Stop-Transcript