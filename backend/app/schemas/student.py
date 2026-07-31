from pydantic import BaseModel, EmailStr


class StudentProfileOut(BaseModel):
    id: int
    student_code: str
    name: str
    surname: str
    school_id: str
    email: EmailStr


class TeacherCodeRequest(BaseModel):
    code: str


class TeacherCodeResponse(BaseModel):
    teacher_name: str
    classrooms: list[str]
