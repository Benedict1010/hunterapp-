import json
import openai
from openai import OpenAI
from app.services.ai.base import AIProvider
from app.services.ai.schemas import (
    AIAnalysisRequest,
    AIAnalysisResponse,
    AITailoringRequest,
    AITailoringResponse
)
from app.services.ai.exceptions import (
    AIConfigurationError,
    AIResponseError,
    AIProviderUnavailableError,
    AIRateLimitError,
    AITimeoutError
)

class OpenAIProvider(AIProvider):
    def __init__(self, api_key: str, model: str):
        if not api_key:
            raise AIConfigurationError("OpenAI API key is missing.")
        self.client = OpenAI(api_key=api_key)
        self.model = model

    def analyze_job_resume(self, request: AIAnalysisRequest) -> AIAnalysisResponse:
        system_prompt = (
            "You are an expert career advisor and technical recruiter. "
            "Analyze the provided resume against the job description. "
            "Identify evidence-supported strengths, missing or insufficiently demonstrated skills, "
            "and provide practical recommendations. Do not invent experience. "
            "Return the analysis as a JSON object with the following keys: "
            "'summary' (string), 'strengths' (list of strings), 'missing_skills' (list of strings), "
            "'recommendations' (list of strings), and 'raw_score' (optional float between 0 and 100)."
        )

        user_content = (
            f"JOB DESCRIPTION:\n{request.job_description}\n\n"
            f"RESUME CONTENT:\n{request.resume_text}"
        )

        try:
            response = self.client.chat.completions.create(
                model=self.model,
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": user_content}
                ],
                response_format={"type": "json_object"},
                temperature=0.2
            )

            content = response.choices[0].message.content
            if not content:
                raise AIResponseError("Empty response from OpenAI.")

            data = json.loads(content)
            return AIAnalysisResponse(**data)

        except openai.RateLimitError:
            raise AIRateLimitError("OpenAI rate limit exceeded.")
        except openai.APITimeoutError:
            raise AITimeoutError("OpenAI request timed out.")
        except openai.APIConnectionError:
            raise AIProviderUnavailableError("Could not connect to OpenAI.")
        except (json.JSONDecodeError, KeyError, TypeError) as e:
            raise AIResponseError(f"Malformed AI response: {str(e)}")
        except Exception as e:
            raise AIResponseError(f"Unexpected OpenAI provider error: {str(e)}")

    def tailor_resume(self, request: AITailoringRequest) -> AITailoringResponse:
        # Implementation for Phase 3E.3.3
        raise NotImplementedError("Tailoring is not implemented in this phase.")
