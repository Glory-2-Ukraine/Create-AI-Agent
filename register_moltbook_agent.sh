#!/bin/bash
# Moltbook Agent Registration Script
# Customize AGENT_NAME and AGENT_DESCRIPTION during execution.
# This script guides you through registering, claiming, and verifying your Moltbook agent.

# Enable detailed logging
LOG_FILE="moltbook_registration_$(date +%Y%m%d_%H%M%S).log"
echo "=== Moltbook Agent Registration Log ===" | tee "$LOG_FILE"
echo "Script started at: $(date)" | tee -a "$LOG_FILE"
exec > >(tee -a "$LOG_FILE") 2>&1

# Check if jq is installed
echo "--- Checking for jq ---"
if ! command -v jq &> /dev/null; then
    echo "jq not found. Installing jq..." | tee -a "$LOG_FILE"
    sudo apt update && sudo apt install -y jq
    if ! command -v jq &> /dev/null; then
        echo "❌ Failed to install jq. Exiting." | tee -a "$LOG_FILE"
        exit 1
    fi
    echo "✅ jq installed successfully." | tee -a "$LOG_FILE"
else
    echo "✅ jq is already installed." | tee -a "$LOG_FILE"
fi

# Prompt user for agent details
read -p "Enter your agent name (e.g., MyAgentBot): " AGENT_NAME
read -p "Enter your agent description (e.g., 'AI assistant for my project'): " AGENT_DESCRIPTION

# Register the agent on Moltbook
echo "--- Registering agent on Moltbook ---"
echo "Agent name: $AGENT_NAME" | tee -a "$LOG_FILE"
echo "Agent description: $AGENT_DESCRIPTION" | tee -a "$LOG_FILE"

REGISTER_RESPONSE=$(curl -s -X POST https://www.moltbook.com/api/v1/agents/register \
  -H "Content-Type: application/json" \
  -d "{\"name\": \"$AGENT_NAME\", \"description\": \"$AGENT_DESCRIPTION\"}")

echo "Raw API response: $REGISTER_RESPONSE" | tee -a "$LOG_FILE"

# Check for errors
SUCCESS=$(echo "$REGISTER_RESPONSE" | jq -r '.success')
ERROR_MESSAGE=$(echo "$REGISTER_RESPONSE" | jq -r '.error')

if [ "$SUCCESS" == "false" ]; then
    echo "❌ Registration failed. Error: $ERROR_MESSAGE" | tee -a "$LOG_FILE"
    exit 1
fi

# Extract API key and claim URL
API_KEY=$(echo "$REGISTER_RESPONSE" | jq -r '.agent.api_key')
CLAIM_URL=$(echo "$REGISTER_RESPONSE" | jq -r '.agent.claim_url')
VERIFICATION_CODE=$(echo "$REGISTER_RESPONSE" | jq -r '.agent.verification_code')

if [ -z "$API_KEY" ] || [ "$API_KEY" == "null" ]; then
    echo "❌ No API key found in the response. Check the log file for details." | tee -a "$LOG_FILE"
    exit 1
fi

if [ -z "$CLAIM_URL" ] || [ "$CLAIM_URL" == "null" ]; then
    echo "❌ No claim URL found in the response. Check the log file for details." | tee -a "$LOG_FILE"
    exit 1
fi

echo "✅ Registration successful!" | tee -a "$LOG_FILE"
echo "🔑 Your API key: $API_KEY" | tee -a "$LOG_FILE"
echo "🌐 Claim URL: $CLAIM_URL" | tee -a "$LOG_FILE"

# Save credentials
echo "--- Saving credentials ---"
mkdir -p ~/.config/moltbook
CREDENTIALS_FILE=~/.config/moltbook/credentials.json
echo "{\"api_key\": \"$API_KEY\", \"agent_name\": \"$AGENT_NAME\"}" > "$CREDENTIALS_FILE"
chmod 600 "$CREDENTIALS_FILE"
echo "📝 Credentials saved to $CREDENTIALS_FILE" | tee -a "$LOG_FILE"

# Step 1: Tweet the verification code
echo "--- Step 1: Tweet the Verification Code ---"
echo "Post the following tweet from the Twitter account you want to associate with this agent:"
echo ""
echo "  I'm claiming my AI agent \"$AGENT_NAME\" on @moltbook 🦞"
echo ""
echo "  Verification: $VERIFICATION_CODE"
echo ""
read -p "Have you posted the tweet? (y/n): " TWEET_CONFIRMATION
if [ "$TWEET_CONFIRMATION" != "y" ]; then
    echo "Please post the tweet and rerun this script." | tee -a "$LOG_FILE"
    exit 0
fi

# Step 2: Enter the tweet URL
read -p "Enter the URL of your tweet (e.g., https://twitter.com/yourhandle/status/123456789): " TWEET_URL
echo "Tweet URL: $TWEET_URL" | tee -a "$LOG_FILE"

# Step 3: Open the claim URL
echo "--- Step 2: Open the Claim URL ---"
xdg-open "$CLAIM_URL"
echo "🌐 Claim URL opened in your default browser. Follow the instructions to verify your agent." | tee -a "$LOG_FILE"
read -p "Have you completed the claim process on Moltbook? (y/n): " CLAIM_CONFIRMATION
if [ "$CLAIM_CONFIRMATION" != "y" ]; then
    echo "Please complete the claim process and rerun this script." | tee -a "$LOG_FILE"
    exit 0
fi

# Step 4: Verify agent status
echo "--- Step 3: Verify Agent Status ---"
STATUS_RESPONSE=$(curl -s https://www.moltbook.com/api/v1/agents/status -H "Authorization: Bearer $API_KEY" | jq)
echo "Agent status response: $STATUS_RESPONSE" | tee -a "$LOG_FILE"

STATUS=$(echo "$STATUS_RESPONSE" | jq -r '.status')
if [ "$STATUS" == "claimed" ]; then
    echo "✅ Agent is claimed and ready to use!" | tee -a "$LOG_FILE"
else
    echo "⚠️ Agent is not yet claimed. Status: $STATUS" | tee -a "$LOG_FILE"
    echo "Please wait a few minutes and check again." | tee -a "$LOG_FILE"
    exit 0
fi

# Step 5: Test the API key
echo "--- Step 4: Test the API Key ---"
TEST_RESPONSE=$(curl -s https://www.moltbook.com/api/v1/agents/me -H "Authorization: Bearer $API_KEY" | jq)
echo "Agent details response: $TEST_RESPONSE" | tee -a "$LOG_FILE"

# Step 6: Next steps
echo "--- Next Steps ---"
echo "1. Set up a heartbeat for your agent to stay active. See: https://moltbook.com/heartbeat.md" | tee -a "$LOG_FILE"
echo "2. Use the following command to interact with Moltbook:" | tee -a "$LOG_FILE"
echo "   curl -s https://www.moltbook.com/api/v1/agents/me -H \"Authorization: Bearer $API_KEY\" | jq" | tee -a "$LOG_FILE"
echo "3. Check the log file for any issues: $LOG_FILE" | tee -a "$LOG_FILE"

echo "--- Script completed at: $(date) ---" | tee -a "$LOG_FILE"
