from pydantic_settings import BaseSettings, SettingsConfigDict
from pydantic import Field

class Settings(BaseSettings):
    DATABASE_URL: str = Field(default=None)
    SECRET_KEY:str = Field(default=None)

    # --- Add your OpenSearch environment mappings ---
    OPENSEARCH_HOST: str = "localhost"
    OPENSEARCH_PORT: int = 9200
    OPENSEARCH_USER: str = "admin"
    OPENSEARCH_PASSWORD: str = Field(default=None)

    # 📧 Email Configurations
    SMTP_SERVER: str
    SMTP_PORT: int
    TEST_SENDER_EMAIL: str
    TEST_SENDER_PASSWORD: str
    TEST_RECEIVER_EMAIL: str

    # Modern Pydantic configuration
    model_config = SettingsConfigDict(
        env_file=".env",
        extra="ignore"  
        # Keeps things clean by ignoring unrelated keys in your .env
    )

#    class Config:
#        env_file = ".env"

# single global instance used by your app
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
