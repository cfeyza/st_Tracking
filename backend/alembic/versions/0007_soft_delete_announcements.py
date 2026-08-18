"""add deleted_at to announcements for soft delete

Revision ID: 0007_soft_delete_announcements
Revises: 0006_announcement_reads
Create Date: 2026-08-12

"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "0007_soft_delete_announcements"
down_revision: Union[str, None] = "0006_announcement_reads"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column("announcements", sa.Column("deleted_at", sa.DateTime(timezone=True), nullable=True))


def downgrade() -> None:
    op.drop_column("announcements", "deleted_at")
