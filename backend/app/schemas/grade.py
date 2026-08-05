from datetime import datetime

from pydantic import BaseModel, Field


class GradeCreate(BaseModel):
    student_id: int
    classroom_id: int | None = None
    subject: str = Field(max_length=100)
    value: str = Field(max_length=20)


class GradeOut(BaseModel):
    id: int
    subject: str
    value: str
    created_at: datetime
    teacher_name: str
    classroom_name: str | None = None
    student_name: str | None = None
