from pydantic import BaseModel, EmailStr


class TeacherProfileOut(BaseModel):
    id: int
    teacher_code: str
    name: str
    surname: str
    email: EmailStr


class TeacherDashboardOut(BaseModel):
    classroom_count: int
    student_count: int


class StudentListItem(BaseModel):
    id: int
    name: str
    surname: str
    school_id: int
    student_code: str
    classrooms: list[str]
    is_registered: bool
