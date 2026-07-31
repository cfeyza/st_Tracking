from sqlalchemy import ForeignKey, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base_class import Base
from app.models.parent import parent_students
from app.models.teacher import teacher_students


class StudentProfile(Base):
    __tablename__ = "student_profiles"

    id: Mapped[int] = mapped_column(primary_key=True)
    # Nullable: a row can exist as a teacher-imported roster placeholder before
    # the actual student ever registers an account (see app/services/roster.py).
    user_id: Mapped[int | None] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), unique=True, nullable=True)
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    surname: Mapped[str] = mapped_column(String(100), nullable=False)
    school_id: Mapped[str] = mapped_column(String(50), nullable=False)
    student_code: Mapped[str] = mapped_column(String(32), unique=True, index=True, nullable=False)

    user: Mapped["User | None"] = relationship(back_populates="student_profile")
    teachers: Mapped[list["TeacherProfile"]] = relationship(
        secondary=teacher_students, back_populates="students"
    )
    parents: Mapped[list["ParentProfile"]] = relationship(
        secondary=parent_students, back_populates="students"
    )
    classrooms: Mapped[list["Classroom"]] = relationship(
        secondary="classroom_students", back_populates="students"
    )
    grades: Mapped[list["Grade"]] = relationship(back_populates="student", cascade="all, delete-orphan")
