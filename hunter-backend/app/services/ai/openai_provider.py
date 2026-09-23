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
        system_prompt = (
            "You are an expert resume editor and career advisor.\n"
            "Your task is to tailor the candidate's resume for the target job while strictly adhering to anti-fabrication guidelines.\n\n"
            "STRICT ANTI-FABRICATION RULES:\n"
            "1. Do NOT invent or fabricate any employment history, internships, projects, education, certifications, or awards.\n"
            "2. Do NOT introduce new skills, tools, or technologies that are not demonstrated or present in the source resume.\n"
            "3. Do NOT invent metrics, numbers, user counts, percentages, dollar amounts, or performance claims.\n"
            "4. Do NOT invent dates, employers, or job titles.\n"
            "5. If the target job requests a skill that is absent from the source resume, DO NOT add it to the resume. Record it in the 'warnings' list.\n"
            "6. You MAY reorder sections/bullet points, improve wording and clarity, emphasize relevant existing skills, and remove irrelevant repetition.\n"
            "7. Preserve the factual meaning and true work history of the original resume.\n\n"
            "Return ONLY a JSON object with the following keys:\n"
            "- 'tailored_resume': string containing the full tailored resume text.\n"
            "- 'changes_made': list of strings describing high-level edits (e.g. 'Reworded summary for clarity', 'Emphasized React experience').\n"
            "- 'warnings': list of strings noting job requirements that could not be addressed because they are absent from the source resume."
        )

        user_content = (
            f"TARGET JOB:\n{request.job_description}\n\n"
            f"SOURCE RESUME:\n{request.resume_text}"
        )
        if request.instructions:
            user_content += f"\n\nEXTRA INSTRUCTIONS:\n{request.instructions}"

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
            return AITailoringResponse(**data)

        except openai.RateLimitError:
            raise AIRateLimitError("OpenAI rate limit exceeded.")
        except openai.APITimeoutError:
            raise AITimeoutError("OpenAI request timed out.")
        except openai.APIConnectionError:
            raise AIProviderUnavailableError("Could not connect to OpenAI.")
        except (json.JSONDecodeError, KeyError, TypeError, ValueError) as e:
            raise AIResponseError(f"Malformed AI response: {str(e)}")
        except AIError:
            raise
        except Exception as e:
            raise AIResponseError(f"Unexpected OpenAI provider error: {str(e)}")
