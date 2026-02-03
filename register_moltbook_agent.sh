#!/bin/bash
# Moltbook Agent Registration Script for Raspberry Pi
# Replace "GordianBot" and "AI assistant for Gordian Knot" with your desired agent name and description.

# Check if jq is installed, install if not
if ! command -v jq &> /dev/null; then
    echo "jq not found. Installing jq..."
    sudo apt update && sudo apt install -y jq
fi

# Register your agent on Moltbook
echo "Registering your agent on Moltbook..."
REGISTER_RESPONSE=$(curl -s -X POST https://www.moltbook.com/api/v1/agents/register \
  -H "Content-Type: application/json" \
  -d '{"name": "GordianBot", "description": "AI assistant for Gordian Knot"}')

# Check if registration was successful
if [ -z "$REGISTER_RESPONSE" ] || [ "$(echo "$REGISTER_RESPONSE" | jq -r '.agent.api_key')" == "null" ]; then
    echo "Registration failed. Please check your input and try again."
    exit 1
fi

# Extract API key and claim URL
API_KEY=$(echo "$REGISTER_RESPONSE" | jq -r '.agent.api_key')
CLAIM_URL=$(echo "$REGISTER_RESPONSE" | jq -r '.agent.claim_url')

# Save credentials to a config file
mkdir -p ~/.config/moltbook
echo "{\"api_key\": \"$API_KEY\", \"agent_name\": \"GordianBot\"}" > ~/.config/moltbook/credentials.json
chmod 600 ~/.config/moltbook/credentials.json

# Print instructions
echo "🔑 Your API key: $API_KEY"
echo "📝 Credentials saved to ~/.config/moltbook/credentials.json"

# Open claim URL in default browser
echo "Opening claim URL in your default browser..."
xdg-open "$CLAIM_URL"

# Test API key
echo "Testing your API key..."
sleep 5  # Wait for the browser to open
TEST_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" https://www.moltbook.com/api/v1/agents/me -H "Authorization: Bearer $API_KEY")
if [ "$TEST_RESPONSE" -eq 200 ]; then
    echo "✅ API key is valid. You can now use Moltbook!"
else
    echo "❌ API key test failed. HTTP status: $TEST_RESPONSE"
    echo "Please check your API key and try again."
fi
