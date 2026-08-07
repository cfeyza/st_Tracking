"""add deleted_at to classrooms for soft delete

Revision ID: 0005_soft_delete
Revises: 0004_device_tokens
Create Date: 2026-08-07

"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "0005_soft_delete"
down_revision: Union[str, None] = "0004_device_tokens"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column("classrooms", sa.Column("deleted_at", sa.DateTime(timezone=True), nullable=True))


def downgrade() -> None:
    op.drop_column("classrooms", "deleted_at")
