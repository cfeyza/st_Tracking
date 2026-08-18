"""add announcement_reads table for read confirmations

Revision ID: 0006_announcement_reads
Revises: 0005_soft_delete
Create Date: 2026-08-12

"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "0006_announcement_reads"
down_revision: Union[str, None] = "0005_soft_delete"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "announcement_reads",
        sa.Column("announcement_id", sa.Integer(), nullable=False),
        sa.Column("student_id", sa.Integer(), nullable=False),
        sa.Column(
            "read_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(["announcement_id"], ["announcements.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["student_id"], ["student_profiles.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("announcement_id", "student_id"),
    )


def downgrade() -> None:
    op.drop_table("announcement_reads")
