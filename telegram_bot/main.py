import asyncio
import os

from aiogram import Bot, Dispatcher, F
from aiogram.filters import Command, CommandStart
from aiogram.fsm.context import FSMContext
from aiogram.fsm.state import State, StatesGroup
from aiogram.types import (
    BufferedInputFile,
    CallbackQuery,
    InlineKeyboardButton,
    InlineKeyboardMarkup,
    KeyboardButton,
    Message,
    ReplyKeyboardMarkup,
    ReplyKeyboardRemove,
)
from dotenv import load_dotenv

load_dotenv()

from bot.services import auth_api, images_api, lessons_api  # после load_dotenv, чтобы подхватить .env

bot = Bot(token=os.getenv("BOT_TOKEN"))
dp = Dispatcher()

# telegram_id -> {"username", "token", "user_id", "step", "history"}
sessions: dict[int, dict] = {}

# Если True, при пропуске бот вызывает create_answer, чтобы бэкенд перешёл к следующему шагу
SKIP_MARKS_BACKEND = True

# ---------- клавиатуры ----------
# не вошёл
guest_kb = ReplyKeyboardMarkup(
    keyboard=[[KeyboardButton(text="📝 Регистрация"), KeyboardButton(text="🔑 Вход")]],
    resize_keyboard=True,
)
# вошёл, ничего не решает
menu_kb = ReplyKeyboardMarkup(
    keyboard=[
        [KeyboardButton(text="📚 Задание"), KeyboardButton(text="📖 История")],
        [KeyboardButton(text="👤 Кто я"), KeyboardButton(text="🚪 Выйти")],
    ],
    resize_keyboard=True,
)
# решает задание
task_kb = ReplyKeyboardMarkup(
    keyboard=[[KeyboardButton(text="⏭ Пропустить")]],
    resize_keyboard=True,
)


def main_kb(user_id: int) -> ReplyKeyboardMarkup:
    return menu_kb if user_id in sessions else guest_kb


# ---------- состояния ----------
class Reg(StatesGroup):
    username = State()
    password = State()
    email = State()

class Login(StatesGroup):
    username = State()
    password = State()


class TaskState(StatesGroup):
    waiting_answer = State()


# ---------- старт ----------
@dp.message(CommandStart())
async def start(message: Message, state: FSMContext):
    await state.clear()
    await message.answer(
        "Сәләм! Я бот для изучения башкирского языка.\n\n"
        "Пользуйся кнопками внизу или командами:\n"
        "/register, /login, /me, /task, /history, /logout",
        reply_markup=main_kb(message.from_user.id),
    )

# ---------- регистрация ----------
@dp.message(Command("register"))
@dp.message(F.text == "📝 Регистрация")
async def reg_start(message: Message, state: FSMContext):
    if message.from_user.id in sessions:
        await message.answer("Ты уже вошёл в аккаунт. Чтобы создать новый, сначала выйди: /logout",
                             reply_markup=menu_kb)
        return
    await state.clear()
    await state.set_state(Reg.username)
    # пока вводишь данные, кнопки прячем
    await message.answer("Придумай имя пользователя:", reply_markup=ReplyKeyboardRemove())


@dp.message(Reg.username, F.text, ~F.text.startswith("/"))
async def reg_username(message: Message, state: FSMContext):
    await state.update_data(username=message.text.strip())
    await state.set_state(Reg.password)
    await message.answer("Теперь придумай пароль (минимум 6 символов):")


@dp.message(Reg.password, F.text, ~F.text.startswith("/"))
async def reg_password(message: Message, state: FSMContext):
    password = message.text
    await message.delete()  # удаляем сообщение с паролем из чата

    if len(password) < 6:
        await message.answer("Слишком короткий пароль, попробуй ещё раз:")
        return

    await state.update_data(password=password)
    await state.set_state(Reg.email)
    await message.answer("Теперь напиши свою почту:")


@dp.message(Reg.email, F.text, ~F.text.startswith("/"))
async def reg_email(message: Message, state: FSMContext):
    email = message.text.strip()
    if "@" not in email or "." not in email.split("@")[-1]:
        await message.answer("Это не похоже на почту, попробуй ещё раз:")
        return

    data = await state.get_data()
    await state.clear()
    ok, info = await auth_api.register(data["username"], data["password"], email, message.from_user.id)
    if ok:
        await message.answer("Аккаунт создан! Теперь нажми «Вход».", reply_markup=guest_kb)
    else:
        await message.answer(f"{info}", reply_markup=guest_kb)


# ---------- вход ----------
@dp.message(Command("login"))
@dp.message(F.text == "🔑 Вход")
async def login_start(message: Message, state: FSMContext):
    if message.from_user.id in sessions:
        await message.answer("Ты уже вошёл в аккаунт. Чтобы войти в другой, сначала выйди: /logout",
                             reply_markup=menu_kb)
        return
    await state.clear()
    await state.set_state(Login.username)
    await message.answer("Введи имя пользователя:", reply_markup=ReplyKeyboardRemove())


@dp.message(Login.username, F.text, ~F.text.startswith("/"))
async def login_username(message: Message, state: FSMContext):
    await state.update_data(username=message.text.strip())
    await state.set_state(Login.password)
    await message.answer("Введи пароль:")


@dp.message(Login.password, F.text, ~F.text.startswith("/"))
async def login_password(message: Message, state: FSMContext):
    password = message.text
    await message.delete()

    data = await state.get_data()
    await state.clear()
    ok, info = await auth_api.login(data["username"], password, message.from_user.id)
    if ok:
        user_id = auth_api.extract_user_id(info)
        if user_id is None:
            user_id = await auth_api.find_user_id(data["username"])
        sessions[message.from_user.id] = {
            "username": data["username"],
            "token": info,
            "user_id": user_id,
            "step": None,      # {"id", "answered", "data"}
            "history": [],     # пройденные и пропущенные задания
        }
        await message.answer(f"Ты вошёл как {data['username']}", reply_markup=menu_kb)
    else:
        await message.answer(f"{info}", reply_markup=guest_kb)


# ---------- прочее ----------
@dp.message(Command("me"))
@dp.message(F.text == "👤 Кто я")
async def me(message: Message):
    session = sessions.get(message.from_user.id)
    if session:
        await message.answer(f"Ты авторизован, твоё имя пользователя: {session['username']}")
    else:
        await message.answer("Ты не вошёл. Нажми «Вход».", reply_markup=guest_kb)


@dp.message(Command("logout"))
@dp.message(F.text == "🚪 Выйти")
async def logout(message: Message, state: FSMContext):
    sessions.pop(message.from_user.id, None)
    await state.clear()
    await message.answer("Ты вышел из аккаунта.", reply_markup=guest_kb)


# ---------- задания ----------
def normalize(text: str) -> str:
    cleaned = "".join(ch for ch in text.lower() if ch.isalnum() or ch.isspace())
    return " ".join(cleaned.split())


def finish_step(session: dict, status: str):
    """Помечает текущий шаг завершённым и кладёт в историю."""
    current = session["step"]
    current["answered"] = True
    entry = {"id": current["id"], "data": current["data"], "status": status}
    for i, item in enumerate(session["history"]):
        if item["id"] == entry["id"]:
            session["history"][i] = entry
            return
    session["history"].append(entry)


async def send_step(message: Message, step: dict, header: str = "", markup=None):
    question = step.get("subtitle")
    text = f"{header}{step.get('title', 'Задание')}\n\n{question}"

    photo_id = step.get("photo")
    if photo_id:
        data, img_error = await images_api.get_image(photo_id)
        if data:
            await message.answer_photo(
                BufferedInputFile(data, filename="task.jpg"),
                caption=text,
                reply_markup=markup,
            )
            return
        text += f"\n\n(картинку загрузить не удалось: {img_error})"
    await message.answer(text, reply_markup=markup)


async def send_next_task(message: Message, state: FSMContext, session: dict):
    """Берёт новое задание у бэкенда и сразу показывает его."""
    step, error = await lessons_api.get_current_step(session["user_id"])
    if error:
        await state.clear()
        await message.answer(f"{error}", reply_markup=menu_kb)
        return

    session["step"] = {"id": step["step_id"], "answered": False, "data": step}
    await state.set_state(TaskState.waiting_answer)
    await send_step(message, step, markup=task_kb)  # во время задания видна только «Пропустить»


@dp.message(Command("task"))
@dp.message(F.text == "📚 Задание")
async def task(message: Message, state: FSMContext):
    session = sessions.get(message.from_user.id)
    if not session:
        await message.answer("Сначала войди в аккаунт.", reply_markup=guest_kb)
        return
    if session["user_id"] is None:
        await message.answer("Не удалось определить id из ответа /login.")
        return

    current = session["step"]
    if current and not current["answered"]:
        # ещё не ответил, показываем то же задание
        await message.answer("Ты ещё не ответил на это задание:")
        await state.set_state(TaskState.waiting_answer)
        await send_step(message, current["data"], markup=task_kb)
    else:
        await send_next_task(message, state, session)


@dp.message(Command("skip"))
@dp.message(F.text == "⏭ Пропустить")
async def skip(message: Message, state: FSMContext):
    session = sessions.get(message.from_user.id)
    if not session:
        await message.answer("Сначала войди в аккаунт.", reply_markup=guest_kb)
        return

    current = session["step"]
    if not current or current["answered"]:
        await message.answer("Сейчас нечего пропускать.", reply_markup=menu_kb)
        return

    if SKIP_MARKS_BACKEND:
        ok, error = await lessons_api.create_answer(session["user_id"], current["id"])
        if not ok:
            await message.answer(f"Не удалось пропустить ({error}). Попробуй ещё раз.")
            return

    finish_step(session, "skipped")
    await send_next_task(message, state, session)  # сразу новый вопрос, без лишних сообщений


@dp.message(TaskState.waiting_answer, F.text, ~F.text.startswith("/"))
async def task_answer(message: Message, state: FSMContext):
    session = sessions.get(message.from_user.id)
    if not session or not session["step"]:
        await state.clear()
        return

    step = session["step"]
    ok, error = await lessons_api.create_answer(session["user_id"], step["id"])
    if not ok:
        await message.answer(f"Не удалось сохранить ответ ({error}). Отправь ответ ещё раз.")
        return

    finish_step(session, "answered")
    await state.clear()

    right = step["data"].get("answer_text", "")
    if not right:
        result = "Ответ принят."
    elif normalize(message.text) == normalize(right):
        result = "Верно!"
    else:
        result = f"Не совсем. Правильный ответ: {right}"

    # задание закончилось, возвращаем главное меню
    await message.answer(result, reply_markup=menu_kb)


# ---------- история ----------
def history_kb(index: int, total: int) -> InlineKeyboardMarkup:
    row = []
    if index > 0:
        row.append(InlineKeyboardButton(text="◀️ Назад", callback_data=f"hist:{index - 1}"))
    row.append(InlineKeyboardButton(text=f"{index + 1}/{total}", callback_data="noop"))
    if index < total - 1:
        row.append(InlineKeyboardButton(text="Вперёд ▶️", callback_data=f"hist:{index + 1}"))
    return InlineKeyboardMarkup(inline_keyboard=[row])


async def show_history(message: Message, history: list, index: int):
    item = history[index]
    mark = "Пройдено" if item["status"] == "answered" else "⏭ Пропущено"
    await send_step(message, item["data"], header=f"{mark}\n\n",
                    markup=history_kb(index, len(history)))


@dp.message(Command("history"))
@dp.message(F.text == "📖 История")
async def history_cmd(message: Message):
    session = sessions.get(message.from_user.id)
    if not session:
        await message.answer("Сначала войди в аккаунт.", reply_markup=guest_kb)
        return
    if not session["history"]:
        await message.answer("История пуста. Пройди или пропусти хотя бы одно задание.")
        return
    await show_history(message, session["history"], len(session["history"]) - 1)


@dp.callback_query(F.data.startswith("hist:"))
async def history_nav(callback: CallbackQuery):
    session = sessions.get(callback.from_user.id)
    if not session or not session["history"]:
        await callback.answer("История пуста", show_alert=True)
        return
    index = int(callback.data.split(":")[1])
    if not 0 <= index < len(session["history"]):
        await callback.answer()
        return
    await callback.answer()
    await callback.message.delete()
    await show_history(callback.message, session["history"], index)


@dp.callback_query(F.data == "noop")
async def noop(callback: CallbackQuery):
    await callback.answer()


# ---------- запуск ----------
async def main():
    await dp.start_polling(bot)


if __name__ == "__main__":
    asyncio.run(main())