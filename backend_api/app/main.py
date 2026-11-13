from fastapi import FastAPI

app = FastAPI()

@app.get("/")
async def read_root():
    return {"Hello": "Привет Даня"}

@app.post("/register")
async def reg(login: str, password: str):
    return {"Hello": "Привет Даня"}

@app.get("/items/{item_id}")
async def read_item(item_id: int, q: str | None = None):
    return {"item_id": item_id, "q": q}