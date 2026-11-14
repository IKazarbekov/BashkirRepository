from database import SessionLocal, get_all_users

def main() -> None:
    db = SessionLocal()
    try:
        users = get_all_users(db)
    finally:
        db.close()

    if not users:
        print("В базе нет ни одного пользователя.")
        return

    print(f"Всего пользователей: {len(users)}")
    print("-" * 40)
    for u in users:
        print(f"id={u.user_id:<4} login={u.login}, email={u.email}")
    print("-" * 40)


if __name__ == "__main__":
    main()