# AI Service Layer

This directory contains a modular AI service layer for the Personal Coach application that integrates with OpenAI's GPT-4o API to provide intelligent goal creation and task prioritization.

## Architecture

The AI service layer is composed of several modular components:

### Core Services

- **`AiService`** - Main orchestrator that coordinates the entire AI workflow
- **`IntentRouter`** - Determines whether user input is for SMART goal generation or task prioritization
- **`ContextCompressor`** - Compresses recent user data into a 1000-token context window
- **`OpenAiClient`** - Handles OpenAI API calls with retry logic and error handling

### Prompt Templates

- **`PromptTemplates::SmartGoalPrompt`** - Builds structured prompts for SMART goal creation
- **`PromptTemplates::PrioritizationPrompt`** - Builds prompts for task prioritization

## Usage

### API Endpoint

```
POST /api/v1/ai
Content-Type: application/json
X-User-ID: <user_id>

{
  "input": "Create a goal to exercise more"
}
```

### Response Format

#### SMART Goal Response
```json
{
  "intent": "smart_goal",
  "response": {
    "specific": "Exercise for 30 minutes daily",
    "measurable": "Track workouts in fitness app",
    "achievable": "Start with 3 days per week",
    "relevant": "Improves overall health and energy",
    "time_bound": "Complete 30 workouts in 3 months"
  },
  "context_used": true
}
```

#### Task Prioritization Response
```json
{
  "intent": "prioritization",
  "response": [
    {
      "task": "exercise",
      "priority": 1,
      "rationale": "High impact on health",
      "recommended_action": "do"
    }
  ],
  "context_used": true
}
```

## Intent Detection

The system automatically detects user intent based on keywords:

### SMART Goal Keywords
- goal, objective, target, aim, achieve, accomplish, reach
- create/make/set/establish/define + goal/objective/target

### Prioritization Keywords
- prioritize, priority, order, rank, sort, organize, arrange
- task, todo, item, action, step + list/tasks/todo/items/actions

## Context Compression

The system automatically includes relevant user context:
- Up to 3 recent pending SMART goals
- Up to 5 recent incomplete tasks
- Context is compressed to fit within 1000 tokens

## Error Handling

- Retries up to 3 times with exponential backoff for API errors
- Graceful fallback for malformed responses
- Comprehensive error logging

## Configuration

Add your OpenAI API key to Rails credentials:

```bash
rails credentials:edit
```

Add:
```yaml
openai_api_key: your_api_key_here
```

## Testing

Run the test suite:

```bash
bundle exec rspec spec/services/ai/
bundle exec rspec spec/requests/api/v1/ai_controller_spec.rb
```

## Dependencies

- `ruby-openai` gem for OpenAI API integration
- RSpec for testing with comprehensive mocking 