SKILL_VOCABULARY = {
    "python": "Python",
    "java": "Java",
    "javascript": "JavaScript",
    "js": "JavaScript",
    "typescript": "TypeScript",
    "ts": "TypeScript",
    "dart": "Dart",
    "flutter": "Flutter",
    "react": "React",
    "next.js": "Next.js",
    "nextjs": "Next.js",
    "node.js": "Node.js",
    "nodejs": "Node.js",
    "node": "Node.js",
    "express": "Express",
    "fastapi": "FastAPI",
    "sql": "SQL",
    "postgresql": "PostgreSQL",
    "postgres": "PostgreSQL",
    "mysql": "MySQL",
    "mongodb": "MongoDB",
    "firebase": "Firebase",
    "docker": "Docker",
    "git": "Git",
    "github": "GitHub",
    "aws": "AWS",
    "azure": "Azure",
    "linux": "Linux",
    "html": "HTML",
    "css": "CSS",
    "tailwind": "Tailwind",
    "machine learning": "Machine Learning",
    "ml": "Machine Learning",
    "deep learning": "Deep Learning",
    "pytorch": "PyTorch",
    "tensorflow": "TensorFlow",
    "pandas": "Pandas",
    "numpy": "NumPy",
    "rest api": "REST API",
    "rest": "REST API",
}

def normalize_skill(skill_name: str) -> str | None:
    """Normalize a skill name using the vocabulary."""
    key = skill_name.strip().lower()
    return SKILL_VOCABULARY.get(key)

def get_all_normalized_skills() -> set[str]:
    """Return all unique canonical skill names."""
    return set(SKILL_VOCABULARY.values())
