# Apply CORS to Firebase Storage bucket for local testing
# Requires: Google Cloud SDK (gsutil) installed and authenticated
# Usage: Open PowerShell and run this script

$bucket = 'medpass3.appspot.com'
$cwd = Split-Path -Parent $MyInvocation.MyCommand.Definition
Push-Location $cwd
try {
    Write-Host "Applying CORS from cors.json to gs://$bucket"
    gsutil cors set ..\cors.json gs://$bucket
    Write-Host "CORS applied to gs://$bucket"
} catch {
    Write-Error "Failed to apply CORS: $_"
} finally {
    Pop-Location
}
