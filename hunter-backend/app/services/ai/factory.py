from app.core.config import settings
from app.services.ai.base import AIProvider
from app.services.ai.mock import MockAIProvider
from app.services.ai.exceptions import AIConfigurationError

def get_ai_provider() -> AIProvider:
    """
    Factory function to return the configured AI provider.
    """
    provider_name = settings.ai_provider.lower()

    if provider_name == "mock":
        return MockAIProvider()

    if provider_name == "openai":
        # Placeholder for OpenAI implementation
        # For now, we only support mock until Phase 3E.3.2
        if not settings.ai_api_key:
            raise AIConfigurationError("AI_API_KEY is required for OpenAI provider.")
        # return OpenAIProvider(api_key=settings.ai_api_key, model=settings.ai_model)
        raise AIConfigurationError("OpenAI provider implementation is pending Phase 3E.3.2.")

    raise AIConfigurationError(f"Unsupported AI provider: {provider_name}")
