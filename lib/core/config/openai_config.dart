/// Chave OpenAI via `--dart-define=OPENAI_API_KEY=...` (nunca no repositório).
const String _openAiApiKey = String.fromEnvironment('OPENAI_API_KEY');

/// Modelo opcional, ex.: `gpt-4o`, `gpt-4o-mini`.
const String _openAiChatModel = String.fromEnvironment('OPENAI_CHAT_MODEL', defaultValue: 'gpt-4o');

bool get isOpenAiConfigured => _openAiApiKey.isNotEmpty;

String get openAiApiKey => _openAiApiKey;

String get openAiChatModel => _openAiChatModel;
