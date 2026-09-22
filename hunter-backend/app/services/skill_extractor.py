import re
from app.services.skill_vocabulary import SKILL_VOCABULARY

def extract_skills_from_text(text: str) -> set[str]:
    """
    Deterministically extract recognized skills from text.
    Uses regex for word boundaries to avoid unsafe substring matches.
    """
    if not text:
        return set()

    found_skills = set()
    # Sort keys by length descending to match longer multi-word skills first
    sorted_skill_keys = sorted(SKILL_VOCABULARY.keys(), key=len, reverse=True)

    text_lower = text.lower()

    for key in sorted_skill_keys:
        # Use simpler boundaries or non-alphanumeric checks without variable-width lookbehinds
        # \b handles most cases. For tech with dots/chars, we can check surrounding chars manually or use specific patterns.

        if '.' in key or '#' in key or '+' in key:
            # For special chars like Next.js, C#, C++, we check if it's surrounded by non-alphanumerics or start/end
            # We escape the key for literal matching
            escaped_key = re.escape(key)
            # Use a pattern that avoids variable width lookbehind issues
            # We match the key and check its context
            pattern = f"(?:^|[^a-zA-Z0-9]){escaped_key}(?=[^a-zA-Z0-9]|$)"
        else:
            # Standard word boundary
            pattern = r'\b' + re.escape(key) + r'\b'

        if re.search(pattern, text_lower):
            found_skills.add(SKILL_VOCABULARY[key])

    return found_skills
