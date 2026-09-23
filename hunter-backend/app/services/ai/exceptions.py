class AIError(Exception):
    """Base exception for AI provider errors."""
    pass

class AIConfigurationError(AIError):
    """Raised when AI provider is not correctly configured."""
    pass

class AIProviderUnavailableError(AIError):
    """Raised when the AI service is down or unreachable."""
    pass

class AIResponseError(AIError):
    """Raised when the AI provider returns an invalid or malformed response."""
    pass

class AITailoringValidationError(AIResponseError):
    """Raised when tailored resume output fails anti-fabrication safety validation."""
    pass

class AIRateLimitError(AIError):
    """Raised when the provider's rate limit is hit."""
    pass

class AITimeoutError(AIError):
    """Raised when the AI request times out."""
    pass
