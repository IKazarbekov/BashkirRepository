import asyncio
import os

from aiogram import Bot, Dispatcher
from aiogram.filters import Command, CommandStart
from aiogram.fsm.context import FSMContext
from aiogram.fsm.state import State, StatesGroup
from aiogram.types import Message
from dotenv import load_dotenv

load_dotenv()

from bot.services import auth_api  # после load_dotenv, чтобы подхватить .env

bot = Bot(token=os.getenv("BOT_TOKEN"))
dp = Dispatcher()

sessions: dict[int, str] = {}  # telegram_id -> токен (пока в памяти)


class Reg(StatesGroup):
    username = State()
    password = State()


class Login(StatesGroup):
    username = State()
    password = State()


@dp.message(CommandStart())
async def start(message: Message):
    await message.answer(
        "Сәләм! 👋 Я бот для изучения башкирского языка.\n\n"
        "/register — создать аккаунт\n"
        "/login — войти\n"
        "/me — кто я\n"
        "/logout — выйти"
    )


# ---------- регистрация ----------
@dp.message(Command("register"))
async def reg_start(message: Message, state: FSMContext):
    if message.from_user.id in sessions:
        await message.answer("Ты уже вошёл в аккаунт. Чтобы создать новый, сначала выйди: /logout")
        return
    await state.set_state(Reg.username)
    await message.answer("Придумай имя пользователя:")


@dp.message(Reg.username)
async def reg_username(message: Message, state: FSMContext):
    await state.update_data(username=message.text.strip())
    await state.set_state(Reg.password)
    await message.answer("Теперь придумай пароль (минимум 6 символов):")


@dp.message(Reg.password)
async def reg_password(message: Message, state: FSMContext):
    password = message.text
    await message.delete()  # удаляем сообщение с паролем из чата

    if len(password) < 6:
        await message.answer("Слишком короткий пароль, попробуй ещё раз:")
        return

    data = await state.get_data()
    await state.clear()
    ok, info = await auth_api.register(data["username"], password, message.from_user.id)
    if ok:
        await message.answer("✅ Аккаунт создан! Теперь войди через /login")
    else:
        await message.answer(f"❌ {info}")


# ---------- вход ----------
@dp.message(Command("login"))
async def login_start(message: Message, state: FSMContext):
    if message.from_user.id in sessions:
        await message.answer("Ты уже вошёл в аккаунт. Чтобы войти в другой, сначала выйди: /logout")
        return
    await state.set_state(Login.username)
    await message.answer("Введи имя пользователя:")


@dp.message(Login.username)
async def login_username(message: Message, state: FSMContext):
    await state.update_data(username=message.text.strip())
    await state.set_state(Login.password)
    await message.answer("Введи пароль:")


@dp.message(Login.password)
async def login_password(message: Message, state: FSMContext):
    password = message.text
    await message.delete()

    data = await state.get_data()
    await state.clear()
    ok, info = await auth_api.login(data["username"], password, message.from_user.id)
    if ok:
        sessions[message.from_user.id] = {"username": data["username"], "token": info}
        await message.answer(f"✅ Ты вошёл как {data['username']}")
    else:
        await message.answer(f"❌ {info}")


# ---------- прочее ----------
@dp.message(Command("me"))
async def me(message: Message):
    session = sessions.get(message.from_user.id)
    if session:
        await message.answer(f"Ты авторизован ✅, твоё имя пользователя: {session['username']}")
    else:
        await message.answer("Ты не вошёл. Используй /login")


@dp.message(Command("logout"))
async def logout(message: Message):
    sessions.pop(message.from_user.id, None)
    await message.answer("Ты вышел из аккаунта.")


async def main():
    await dp.start_polling(bot)


if __name__ == "__main__":
    asyncio.run(main())