from pydantic_settings import BaseSettings
from pydantic import Field

class Settings(BaseSettings):
    DATABASE_URL: str = Field(default=None)
    SECRET_KEY:str = Field(default=None)

    class Config:
        env_file = ".env"

settings = Settings()

'''
Added " = Field(default=None)" to clear up the IDE's warning that says that 
class Settings expects two arguments (DATABASE_URL, SECRET_KEY) but I'm not 
passing  them directly into the parentheses, because Pydantic knows to look 
at my class Config, find the .env file and automatically fill those parameters 
for me at runtime. 
'''

'''
Alternative approach to get rid of the warnings:
```
settings = Settings(_env_file=".env")
```
'''

'''
If your config file is in another folder then use this:
```
class Config:
        env_file = "../.env" 
        # Adjust path relative to where this script runs
```
'''