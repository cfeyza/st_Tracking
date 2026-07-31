from sqlalchemy import Column, DateTime, ForeignKey, String, Table, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base_class import Base

parent_students = Table(
    "parent_students",
    Base.metadata,
    Column("parent_id", ForeignKey("parent_profiles.id", ondelete="CASCADE"), primary_key=True),
    Column("student_id", ForeignKey("student_profiles.id", ondelete="CASCADE"), primary_key=True),
    Column("created_at", DateTime(timezone=True), server_default=func.now()),
)


class ParentProfile(Base):
    __tablename__ = "parent_profiles"

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), unique=True, nullable=False)
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    surname: Mapped[str] = mapped_column(String(100), nullable=False)

    user: Mapped["User"] = relationship(back_populates="parent_profile")
    students: Mapped[list["StudentProfile"]] = relationship(
        secondary=parent_students, back_populates="parents"
    )
