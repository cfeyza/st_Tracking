from pydantic import BaseModel


class DeviceTokenRegister(BaseModel):
    token: str


class DeviceTokenOut(BaseModel):
    id: int
    token: str

    model_config = {"from_attributes": True}
