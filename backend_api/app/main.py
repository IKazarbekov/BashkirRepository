from fastapi import FastAPI, Depends
from sqlalchemy.orm import Session
from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
import sequrity, os
from jose import JWTError
import database as db
from typing import Annotated
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
from pathlib import Path

app = FastAPI()
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
session_db = db.SessionLocal()
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/login")

@app.get("/user/getall")
def read_users():
    users = db.get_all_users(session_db)
    return [{"id": u.user_id, "login": u.login, "date": u.created_at, "password": {u.password_hash}} for u in users]

@app.post("/user/reg")
def reg(login: str, password: str, email: str):
    if db.get_user_by_login(session_db, login) is not None:
        return {"status": "login_existing"}
    db.create_user(session_db, login, password, email)
    return {"status": "ok"}

@app.post("/user/log")
def login(login: str, password: str):
    # ← было df.get_user_by_login — опечатка; и передавался только db, без логина
    user = db.get_user_by_login(session_db, login)
    if not user or not password or user.password_hash != password:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Неверный логин или пароль",
            headers={"WWW-Authenticate": "Bearer"},
        )

    access_token = sequrity.create_access_token(data={"sub": str(user.user_id)})
    return {"access_token": access_token, "token_type": "bearer"}

async def get_current_user(
    token: Annotated[str, Depends(oauth2_scheme)],
):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Не удалось проверить учётные данные",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = sequrity.decode_access_token(token)
        user_id_raw = payload.get("sub")
        if user_id_raw is None:
            raise credentials_exception
        user_id = int(user_id_raw)
    except (JWTError, ValueError):
        raise credentials_exception

    user = db.get_user_by_id(session_db, user_id)
    if user is None:
        raise credentials_exception
    return user

@app.get("/user/me")
def read_current_user_name(current_user=Depends(get_current_user)):
    return {"name": current_user.name}

# STEPS

@app.post("/step/get_all")
def read_steps():
    return db.get_all_steps(session_db)

@app.post("/step/get_by_current_step")
def get_current_step(user_id: int):
    answer = db.get_last_answer(session_db, user_id)
    if answer is None:
        return db.get_all_steps(session_db)[0]
    step_id = answer.step_id
    return db.get_step_by_id(session_db, step_id + 1)

# ANSWERS
@app.post("/answer/create_answer")
def create_answer(user_id: int, step_id: int):
    db.create_answer(session_db, user_id, step_id, None)
    return {"status": "ok"}

@app.get("/answer/get_all")
def get_all_answers():
    return db.get_all_answer(session_db);

# IMAGES
@app.get("/images/{image_id}")
async def get_image(image_id: int):
    file_path = Path("data") / f"{image_id}.png"
    print(file_path)
    if not file_path.exists():
        raise HTTPException(status_code=404, detail=f"Изображение {image_id} не найдено по пути {file_path}")
    return FileResponse(file_path, media_type="image/png")

# DEBUG
@app.get("/debug/cwd")
def cwd():
    return os.getcwd()