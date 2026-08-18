from datetime import datetime

from pydantic import BaseModel, Field, field_validator


class GradeCreate(BaseModel):
    student_id: int
    classroom_id: int | None = None
    subject: str = Field(min_length=1, max_length=100)
    value: str = Field(min_length=1, max_length=20)

    @field_validator("subject", "value")
    @classmethod
    def not_blank(cls, v: str) -> str:
        if not v.strip():
            raise ValueError("must not be blank")
        return v.strip()


class GradeOut(BaseModel):
    id: int
    subject: str
    value: str
    created_at: datetime
    teacher_name: str
    classroom_name: str | None = None
    student_name: str | None = None
