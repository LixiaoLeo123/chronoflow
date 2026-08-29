from __future__ import annotations

from typing import Literal

from pydantic import BaseModel, Field, field_validator


BlockKind = Literal["focus", "shortBreak", "longBreak"]
BlockStatus = Literal["active", "completed", "cancelled"]


class Credentials(BaseModel):
    username: str = Field(min_length=3, max_length=40, pattern=r"^[a-zA-Z0-9_.-]+$")
    password: str = Field(min_length=10, max_length=256)


class Registration(Credentials):
    invitationCode: str = Field(min_length=1, max_length=128)


class RefreshRequest(BaseModel):
    refreshToken: str


class ActivitySync(BaseModel):
    id: str = Field(min_length=16, max_length=64)
    accountId: str
    name: str = Field(min_length=1, max_length=80)
    color: int = Field(ge=0, le=0xFFFFFFFF)
    archived: bool
    deleted: bool
    createdAt: str
    updatedAt: str


class TimeBlockSync(BaseModel):
    id: str = Field(min_length=16, max_length=64)
    accountId: str
    activityId: str
    kind: BlockKind
    start: str
    end: str
    status: BlockStatus
    deleted: bool
    createdAt: str
    updatedAt: str


class SyncRequest(BaseModel):
    since: str | None = None
    activities: list[ActivitySync] = Field(default_factory=list)
    timeBlocks: list[TimeBlockSync] = Field(default_factory=list)
