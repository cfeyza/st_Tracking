from pydantic import BaseModel, Field


class DeviceTokenRegister(BaseModel):
    token: str = Field(max_length=255)


class DeviceTokenOut(BaseModel):
    id: int
    token: str

    model_config = {"from_attributes": True}
