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
    is_read: bool
    read_at: datetime | None = None


class AcknowledgeOut(BaseModel):
    read_at: datetime


class StudentReaderInfo(BaseModel):
    id: int
    name: str
    surname: str
    read_at: datetime | None = None


class AnnouncementReadersOut(BaseModel):
    announcement_id: int
    readers: list[StudentReaderInfo]
    non_readers: list[StudentReaderInfo]


class ParentAnnouncementOut(BaseModel):
    id: int
    text: str
    created_at: datetime
    teacher_name: str
    classrooms: list[str]
    student_name: str
