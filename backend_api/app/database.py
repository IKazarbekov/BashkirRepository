# Импорты
import os
from sqlalchemy import create_engine
from sqlalchemy.ext.automap import automap_base
from sqlalchemy.orm import Session
from sqlalchemy import select
from sqlalchemy.orm import (
    sessionmaker,
    DeclarativeBase,
)

# Формат: postgresql+psycopg://USER:PASSWORD@HOST:PORT/DBNAME
# Значения по умолчанию — для локального Postgres, переопределяются через env
DB_USER = os.getenv("DB_USER", "duolingo")
DB_PASSWORD = os.getenv("DB_PASSWORD", "1234")
DB_HOST = os.getenv("DB_HOST", "10.136.202.167")
DB_PORT = os.getenv("DB_PORT", "5432")
DB_NAME = os.getenv("DB_NAME", "postgres")
SQLALCHEMY_DATABASE_URL = (f"postgresql+psycopg://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}")
engine = create_engine(SQLALCHEMY_DATABASE_URL)
Base = automap_base()
Base.prepare(autoload_with=engine)
User = Base.classes.users
Step = Base.classes.step
Answer = Base.classes.user_answer
with Session(engine) as session:
    users = session.query(User).all()
    for user in users:
        print(user.user_id, user.login)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
class Base(DeclarativeBase):
    pass

# ---------- Инициализация ----------
def init_db() -> None:
    Base.metadata.create_all(bind=engine)

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# ---------- CRUD ----------
def get_all_users(db: Session) -> list[User]:
    return db.execute(select(User)).scalars().all()

def get_user_by_login(db: Session, login: str) -> User | None:
    return db.execute(select(User).where(User.login == login)).scalar_one_or_none()

def create_user(db: Session, login: str, password: str, email: str) -> User:
    user = User(login=login, password_hash=password, email = email, role_id=1)
    db.add(user)
    db.commit()
    db.refresh(user)
    return user

def get_all_steps(db: Session) -> list[Step]:
    return db.execute(select(Step)).scalars().all()

def create_answer(db: Session, user_id: int, step_id: int, text: int):
    answer = Answer(user_id = user_id, step_id = step_id, user_text = text)
    db.add(answer)
    db.commit()
    db.refresh(answer)
    return answer

def get_all_answer(db: Session) -> list[Answer]:
    return db.execute(select(Answer)).scalars().all()

def get_last_answer(db: Session, user_id: int) -> Answer | None:
    return db.execute(
        select(Answer)
        .where(Answer.user_id == user_id)
        .order_by(Answer.user_answer_id.desc())     # ← имя PK-колонки!
        .limit(1)
    ).scalar_one_or_none()

def get_step_by_id(db: Session, id: int) -> Step | None:
    return db.execute(select(Step).where(Step.step_id == id)).scalar_one_or_none()
