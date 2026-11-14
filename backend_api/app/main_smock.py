from contextlib import asynccontextmanager

from fastapi import FastAPI, Depends
from sqlalchemy.orm import Session

from database import init_db, get_db
from crud import get_all_users, get_user_by_login, create_user


@asynccontextmanager
async def lifespan(app: FastAPI):
    init_db()      # создаём таблицы при старте
    yield

app = FastAPI(lifespan=lifespan)


@app.get("/users")
def read_users(db: Session = Depends(get_db)):
    users = get_all_users(db)
    # пароли не отдаём наружу
    return [{"id": u.id, "login": u.login} for u in users]


@app.post("/register")
def reg(login: str, password: str, db: Session = Depends(get_db)):
    if get_user_by_login(db, login) is not None:
        return {"status": "login_existing"}
    create_user(db, login, password)
    return {"status": "ok"}


@app.post("/login")
def log(login: str, password: str, db: Session = Depends(get_db)):
    user = get_user_by_login(db, login)
    if user is not None and user.password == password:
        return {"status": "ok"}
    return {"status": "error"}