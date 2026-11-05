import os
from pathlib import Path

from dotenv import load_dotenv
from supabase import create_client, Client

# Load .env file from the backend folder
ENV_PATH = Path(__file__).resolve().parent / ".env"
load_dotenv(dotenv_path=ENV_PATH)

# Get Supabase credentials
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_ANON_KEY = os.getenv("SUPABASE_ANON_KEY")

# Check required environment variables
if not SUPABASE_URL or not SUPABASE_ANON_KEY:
    raise RuntimeError(
        "SUPABASE_URL or SUPABASE_ANON_KEY missing in backend/.env"
    )

# Create Supabase client
supabase: Client = create_client(
    SUPABASE_URL,
    SUPABASE_ANON_KEY
)