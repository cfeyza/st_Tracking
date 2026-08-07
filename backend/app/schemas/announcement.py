from datetime import datetime

from pydantic import BaseModel, Field


class AnnouncementCreate(BaseModel):
    text: str = Field(min_length=1, max_length=500)
    classroom_ids: list[int]


class AnnouncementOut(BaseModel):
    id: int
    text: str
    created_at: datetime
    classrooms: list[str]

    model_config = {"from_attributes": True}


class StudentAnnouncementOut(BaseModel):
    id: int
    text: str
    created_at: datetime
    teacher_name: str
    classrooms: list[str]


class ParentAnnouncementOut(BaseModel):
    id: int
    text: str
    created_at: datetime
    teacher_name: str
    classrooms: list[str]
    student_name: str
