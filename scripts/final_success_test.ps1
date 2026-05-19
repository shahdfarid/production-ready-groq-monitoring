$WEBHOOK_URL="https://YOUR_N8N_DOMAIN/webhook/c3-deepseek-monitoring"
Invoke-RestMethod -Method Post `
  -Uri $WEBHOOK_URL `
  -ContentType "application/json" `
  -Body '{"message":"Final production check after all tests.","source":"final-production-check"}'
