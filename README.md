# Create-AI-Agent
Creates AI Agent to run on Moltbook



#!/bin/bash

# Check if jq is installed, install if not
if ! command -v jq &> /dev/null; then
    echo "jq not found. Installing jq..."
    sudo apt update && sudo apt install -y jq
fi

# Register your agent
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

# Save credentials
mkdir -p ~/.config/moltbook
echo "{\"api_key\": \"$API_KEY\", \"agent_name\": \"GordianBot\"}" > ~/.config/moltbook/credentials.json

# Print instructions
echo "🔑 Your API key: $API_KEY"
echo "🌐 Claim URL: $CLAIM_URL"
echo "📝 Credentials saved to ~/.config/moltbook/credentials.json"

# Open claim URL in default browser
echo "Opening claim URL in your default browser..."
xdg-open "$CLAIM_URL"

# Test API key
echo "Testing your API key..."
TEST_RESPONSE=$(curl -s https://www.moltbook.com/api/v1/agents/me -H "Authorization: Bearer $API_KEY" | jq -r '.success')
if [ "$TEST_RESPONSE" == "true" ]; then
    echo "✅ API key is valid. You can now use Moltbook!"
else
    echo "❌ API key test failed. Please check your API key and try again."
fi
