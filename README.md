# Production Ready Groq Monitoring Workflow

**Course Task:** Production Ready Workflow with Monitoring Dashboard  
**Repository:** `production-ready-groq-monitoring`

This repository contains the working n8n workflows, Google Sheets dashboard template, and PowerShell testing scripts for a production-ready AI chatbot monitoring system.

The original assignment mentions DeepSeek. During implementation, DeepSeek required paid API balance, so Groq was used as a free OpenAI-compatible API provider. The production design remains the same: AI HTTP request, retry handling, error handling, Telegram alerts, Google Sheets logging, dashboard monitoring, and load testing.

---

## 1. Repository Contents

```text
production-ready-groq-monitoring/
├── README.md
├── workflows/
│   ├── main-workflow-groq-real-duration.json
│   └── error-workflow-groq-backup.json
├── sheets/
│   └── C3_Professional_Monitoring_Dashboard_Template_and_Sample.xlsx
└── scripts/
    ├── final_success_test.ps1
    └── load_test_20_mixed_cases.ps1
```

### Files explanation

| File | Purpose |
|---|---|
| `workflows/main-workflow-groq-real-duration.json` | Main n8n chatbot workflow. Handles success, local API failures, real `duration_sec`, Google Sheets logging, and Telegram local failure alerts. |
| `workflows/error-workflow-groq-backup.json` | Separate n8n Error Trigger workflow. Used as a backup for unexpected unhandled workflow crashes. |
| `sheets/C3_Professional_Monitoring_Dashboard_Template_and_Sample.xlsx` | Google Sheets dashboard template with `executions` and `Dashboard` tabs. |
| `scripts/final_success_test.ps1` | Simple PowerShell script for one final success request. |
| `scripts/load_test_20_mixed_cases.ps1` | 20-request mixed test covering success cases, local API failure cases, and backup global error workflow case. |

---

## 2. System Architecture

```text
User / PowerShell / Client
        |
        v
n8n Webhook
        |
        v
Set - Start Context
        |
        v
IF - Message Exists
        | true
        v
HTTP Request - Groq Chat
        |
        v
IF - Groq Success
   | true                         | false
   v                              v
Set - Success Log Row        Set - Failure Log Row
   |                              |        
   v                              v
Google Sheets Success Log     Google Sheets Failure Log
   |                              |
   v                              v
Respond Success               Respond Failure
                                  |
                                  v
                           Telegram Failure Alert
```

Backup workflow:

```text
Unhandled n8n error
        |
        v
Error Trigger
        |
        v
Set - Error Details
        |----------------------|
        v                      v
Google Sheets Failure Log      Telegram Backup Alert
```

---

## 3. Prerequisites

You need:

1. n8n Cloud account or self-hosted n8n.
2. Groq API key.
3. Telegram bot token from BotFather.
4. Telegram chat ID for the alert receiver.
5. Google account with Google Sheets access.
6. PowerShell for testing on Windows.

No API keys or private tokens are stored in this repository.

---

## 4. Google Sheets Setup

1. Open Google Drive.
2. Upload:

```text
sheets/C3_Professional_Monitoring_Dashboard_Template_and_Sample.xlsx
```

3. Open it with Google Sheets.
4. Save it as a native Google Sheet if needed.
5. Open the `executions` tab.
6. Copy the Google Sheet ID from the URL:

```text
https://docs.google.com/spreadsheets/d/SHEET_ID_HERE/edit
```

7. Copy the `executions` tab `gid` from the URL:

```text
#gid=EXECUTIONS_GID_HERE
```

The `executions` tab must keep these headers:

```text
timestamp | request_id | workflow_name | status | duration_sec | node_name | error_message | input_message | client_source
```

---

## 5. n8n Import and Configuration

### 5.1 Import the workflows

In n8n:

1. Import `workflows/main-workflow-groq-real-duration.json`.
2. Import `workflows/error-workflow-groq-backup.json`.

### 5.2 Configure Groq credential

In the main workflow, open:

```text
HTTP Request - Groq Chat
```

Use these settings:

```text
Method: POST
URL: https://api.groq.com/openai/v1/chat/completions
Authentication: Generic Credential Type
Generic Auth Type: Header Auth
Header Name: Authorization
Header Value: Bearer YOUR_GROQ_API_KEY
```

The model in the JSON body should be:

```text
llama-3.1-8b-instant
```

### 5.3 Retry settings

In `HTTP Request - Groq Chat` -> Settings:

```text
Retry On Fail: ON
Max Tries: 3
Wait Between Tries: 1000 ms
On Error: Continue
```

`On Error: Continue` is used so local API failures can be logged with real duration.

### 5.4 Configure Google Sheets nodes

In the main workflow, update both Google Sheets nodes:

```text
Google Sheets - Append Success
Google Sheets - Append Failure Local
```

Set:

```text
Credential: Google Sheets OAuth2 API
Document: By ID
Document value: your Google Sheet ID
Sheet: By ID
Sheet value: executions tab gid
Mapping Column Mode: Map Each Column Manually
```

Map these columns:

```text
timestamp      = {{ $json.timestamp }}
request_id     = {{ $json.request_id }}
workflow_name  = {{ $json.workflow_name }}
status         = {{ $json.status }}
duration_sec   = {{ $json.duration_sec }}
node_name      = {{ $json.node_name }}
error_message  = {{ $json.error_message }}
input_message  = {{ $json.input_message }}
client_source  = {{ $json.client_source }}
```

In the backup error workflow, update:

```text
Google Sheets - Append Failure
```

with the same Sheet ID, gid, and mappings.

### 5.5 Configure Telegram nodes

In the main workflow, configure:

```text
Telegram - Send Local Failure Alert
```

In the backup error workflow, configure:

```text
Telegram - Send Failure Alert
```

Use your Telegram bot credential and chat ID.

### 5.6 Link the backup Error Workflow

In the main workflow:

```text
Settings -> Error Workflow -> select C3 Production Ready Groq Chatbot - Error Workflow Backup
```

Save the settings.

### 5.7 Publish workflows

1. Publish the backup error workflow.
2. Publish the main workflow.
3. If n8n reports webhook path conflict, deactivate the older duplicate workflow and publish the new one.

---

## 6. Webhook URL

The imported workflow uses this webhook path:

```text
/webhook/c3-deepseek-monitoring
```

Example production URL:

```text
https://YOUR_N8N_DOMAIN/webhook/c3-deepseek-monitoring
```

The path name still says `deepseek` because the original assignment was DeepSeek-based. The implementation uses Groq internally.

---

## 7. Quick Success Test

Edit the script:

```text
scripts/final_success_test.ps1
```

Replace:

```powershell
https://YOUR_N8N_DOMAIN/webhook/c3-deepseek-monitoring
```

with your actual production webhook URL.

Run:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/final_success_test.ps1
```

Expected result:

1. n8n execution succeeds.
2. Google Sheets gets a new row with `status = success`.
3. `duration_sec` is a real number.
4. `node_name = HTTP Request - Groq Chat`.
5. `client_source = final-production-check`.

---

## 8. Manual Test Payloads

### Success request

```powershell
$WEBHOOK_URL="https://YOUR_N8N_DOMAIN/webhook/c3-deepseek-monitoring"

Invoke-RestMethod -Method Post `
  -Uri $WEBHOOK_URL `
  -ContentType "application/json" `
  -Body '{"message":"Test normal success path.","source":"manual-success-test"}'
```

Expected:

```text
status = success
error_message = empty
duration_sec = real number
```

### Local API failure request

To test local failure handling:

1. In n8n, open `HTTP Request - Groq Chat`.
2. Temporarily change the model from:

```text
llama-3.1-8b-instant
```

to:

```text
wrong-model-test
```

3. Publish the workflow.
4. Run:

```powershell
Invoke-RestMethod -Method Post `
  -Uri $WEBHOOK_URL `
  -ContentType "application/json" `
  -Body '{"message":"Test local API failure.","source":"manual-local-failure-test"}'
```

Expected:

```text
status = failure
node_name = HTTP Request - Groq Chat
error_message contains model_not_found
duration_sec = real number
Telegram alert is sent
```

After this test, restore the model to:

```text
llama-3.1-8b-instant
```

and publish again.

### Backup global error workflow request

To test the separate Error Workflow:

1. Make sure Groq model is correct.
2. In the main workflow, open `Google Sheets - Append Success`.
3. Temporarily change the Sheet ID or gid to:

```text
999999
```

4. Publish the workflow.
5. Run:

```powershell
Invoke-RestMethod -Method Post `
  -Uri $WEBHOOK_URL `
  -ContentType "application/json" `
  -Body '{"message":"Test backup global error workflow.","source":"manual-backup-error-test"}'
```

Expected:

```text
Main workflow fails at Google Sheets - Append Success
Backup Error Workflow executes
Google Sheets gets failure row with client_source = error-workflow
Telegram backup alert is sent
```

After this test, restore the correct Google Sheet gid and publish again.

---

## 9. 20-Request Mixed Load Test

Use:

```text
scripts/load_test_20_mixed_cases.ps1
```

Before running, replace:

```powershell
$WEBHOOK_URL="https://YOUR_N8N_DOMAIN/webhook/c3-deepseek-monitoring"
```

with your actual webhook URL.

The script is organized into three phases:

| Phase | Cases | Purpose |
|---|---:|---|
| Phase 1 | 1-15 | Normal success requests |
| Phase 2 | 16-19 | Local API failures using wrong Groq model |
| Phase 3 | 20 | Backup global error workflow test |

Expected final result from the 20-request test:

```text
15 success rows
4 local failure rows with real duration_sec
1 backup error workflow failure row
```

The dashboard should update automatically with:

```text
Total runs
Success count
Failure count
Success rate
Average runtime
Last failure
Success vs failure charts
```

---

## 10. Production Restore Checklist

After failure testing, always restore:

```text
Groq model = llama-3.1-8b-instant
Google Sheets Success gid = correct executions tab gid
Main workflow = Published
Backup Error Workflow = Published
```

Then run one final success test.

---

## 11. What This Project Proves

This project proves the C3 production monitoring requirements:

| Requirement | Implemented |
|---|---|
| Production workflow | Yes |
| AI API call | Yes, Groq OpenAI-compatible API |
| Retry strategy | Yes, 3 attempts with 1000 ms wait |
| Local error handling | Yes |
| Global backup Error Workflow | Yes |
| Telegram alerting | Yes |
| Google Sheets execution logging | Yes |
| Monitoring dashboard | Yes |
| 20-request load test | Yes |
| Deployment on n8n cloud | Yes |

---

## 12. Security Notes

Do not commit:

```text
Groq API key
Telegram bot token
Telegram chat ID if private
Google OAuth credentials
n8n credentials export
```

This repository contains only workflow templates, dashboard template, and test scripts.
