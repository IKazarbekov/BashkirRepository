from fastapi import FastAPI

app = FastAPI()

users = {}

@app.get("/users")
async def read_root():
    return users

@app.post("/register")
async def reg(login: str, password: str):
    if login in users:
        return {"status": "login_existing"}
    users[login] = password
    return {"status": "ok"}

@app.post("/login")
async def log(login: str, password: str):
    if login in users and users[login] == password:
        return {"status": "ok"}
    return {"status": "error"}

@app.get("/items/{item_id}")
async def read_item(item_id: int, q: str | None = None):
    return {"item_id": item_id, "q": q}