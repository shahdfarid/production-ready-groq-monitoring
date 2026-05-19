# C3 mixed load test: 15 success, 4 local API failures, 1 backup global error workflow failure.
# Before Phase 1: keep Groq model as llama-3.1-8b-instant and Google Sheets success gid correct.
# Before Phase 2: temporarily change model to wrong-model-test, then publish.
# Before Phase 3: restore model, temporarily change Google Sheets Append Success sheet gid to 999999, then publish.

$WEBHOOK_URL="https://YOUR_N8N_DOMAIN/webhook/c3-deepseek-monitoring"

Write-Host "PHASE 1: 15 success requests"
$successTests = @(
  @{message="Success case 01: Explain what this workflow does."; source="case-01-success-overview"},
  @{message="Success case 02: Explain success logging."; source="case-02-success-logging"},
  @{message="Success case 03: Explain failure logging."; source="case-03-failure-logging"},
  @{message="Success case 04: Explain retry mechanism."; source="case-04-retry"},
  @{message="Success case 05: Explain Telegram alerting."; source="case-05-telegram"},
  @{message="Success case 06: Explain monitoring dashboard."; source="case-06-dashboard"},
  @{message="Success case 07: What is production readiness?"; source="case-07-production-readiness"},
  @{message="Success case 08: What is an API failure?"; source="case-08-api-failure"},
  @{message="Success case 09: What is a webhook?"; source="case-09-webhook"},
  @{message="Success case 10: Give a short answer about n8n."; source="case-10-n8n"},
  @{message="Success case 11: Explain Google Sheets logging."; source="case-11-google-sheets"},
  @{message="Success case 12: Explain runtime duration."; source="case-12-runtime-duration"},
  @{message="Success case 13: Explain backup error workflow."; source="case-13-backup-error"},
  @{message="Success case 14: Reply in 2 bullet points."; source="case-14-formatting"},
  @{message="Success case 15: Confirm the workflow is running end to end."; source="case-15-end-to-end"}
)
foreach ($test in $successTests) {
  $body = $test | ConvertTo-Json -Compress
  Write-Host "Sending $($test.source)..."
  try {
    $response = Invoke-RestMethod -Method Post -Uri $WEBHOOK_URL -ContentType "application/json" -Body $body
    Write-Host "SUCCESS:" $test.source "Request ID:" $response.request_id
  } catch {
    Write-Host "UNEXPECTED FAILURE:" $test.source
    Write-Host $_.Exception.Message
  }
  Start-Sleep -Milliseconds 700
}

Write-Host "PHASE 2: change model to wrong-model-test in n8n, publish, then run 4 local failures."
$failureTests = @(
  @{message="Failure case 16: invalid model configuration test."; source="case-16-local-failure-invalid-model"},
  @{message="Failure case 17: API provider error handling test."; source="case-17-local-failure-api-provider"},
  @{message="Failure case 18: retry then failure logging test."; source="case-18-local-failure-retry"},
  @{message="Failure case 19: Telegram local failure alert test."; source="case-19-local-failure-telegram"}
)
foreach ($test in $failureTests) {
  $body = $test | ConvertTo-Json -Compress
  Write-Host "Sending $($test.source)..."
  try {
    $response = Invoke-RestMethod -Method Post -Uri $WEBHOOK_URL -ContentType "application/json" -Body $body
    Write-Host "LOCAL FAILURE HANDLED:" $test.source "Request ID:" $response.request_id
  } catch {
    Write-Host "EXPECTED LOCAL FAILURE RETURN:" $test.source
    Write-Host $_.Exception.Message
  }
  Start-Sleep -Milliseconds 700
}

Write-Host "PHASE 3: restore model, break Google Sheets success gid to 999999, publish, run backup global error case."
try {
  Invoke-RestMethod -Method Post -Uri $WEBHOOK_URL -ContentType "application/json" -Body '{"message":"Failure case 20: backup global error workflow test.","source":"case-20-backup-error-workflow"}'
} catch {
  Write-Host "EXPECTED BACKUP ERROR WORKFLOW FAILURE:"
  Write-Host $_.Exception.Message
}
Write-Host "After Phase 3, immediately restore Google Sheets Success gid and publish."
