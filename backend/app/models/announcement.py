from datetime import datetime

from sqlalchemy import Column, DateTime, ForeignKey, Table, Text, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base_class import Base

announcement_classrooms = Table(
    "announcement_classrooms",
    Base.metadata,
    Column("announcement_id", ForeignKey("announcements.id", ondelete="CASCADE"), primary_key=True),
    Column("classroom_id", ForeignKey("classrooms.id", ondelete="CASCADE"), primary_key=True),
)


class Announcement(Base):
    __tablename__ = "announcements"

    id: Mapped[int] = mapped_column(primary_key=True)
    teacher_id: Mapped[int] = mapped_column(ForeignKey("teacher_profiles.id", ondelete="CASCADE"), nullable=False)
    text: Mapped[str] = mapped_column(Text, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

    teacher: Mapped["TeacherProfile"] = relationship(back_populates="announcements")
    classrooms: Mapped[list["Classroom"]] = relationship(
        secondary=announcement_classrooms, back_populates="announcements"
    )
