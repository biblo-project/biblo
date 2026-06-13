from pydantic import BaseModel
from typing import List

class GenreSelection(BaseModel):
    genres: List[str]

    model_config = {"from_attributes": True}