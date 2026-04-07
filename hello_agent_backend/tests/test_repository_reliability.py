import pytest
import aiosqlite

from app.db.repository import DatabaseRepository


@pytest.fixture
async def repo(tmp_path):
    db_path = tmp_path / "game_state.db"
    repository = DatabaseRepository(str(db_path))
    await repository.initialize()
    return repository


@pytest.mark.asyncio
async def test_transactional_update_commits_all_operations(repo):
    await repo.create_player("player_tx", "Transactional Player", 100)

    ops = [
        ("UPDATE players SET gold = ? WHERE id = ?", (250, "player_tx")),
        ("INSERT INTO world_state_history (season, day, year, time_of_day, weather, temperature) "
         "VALUES (?, ?, ?, ?, ?, ?)", ("spring", 1, 1, "morning", "sunny", 20.0)),
    ]

    await repo.transactional_update(ops)

    player = await repo.get_player("player_tx")
    assert player is not None
    assert player["gold"] == 250


@pytest.mark.asyncio
async def test_transactional_update_rolls_back_on_failure(repo):
    await repo.create_player("player_fail", "Rollback Player", 100)

    ops = [
        ("UPDATE players SET gold = ? WHERE id = ?", (999, "player_fail")),
        ("INSERT INTO table_does_not_exist (id) VALUES (?)", (1,)),
    ]

    with pytest.raises(aiosqlite.Error):
        await repo.transactional_update(ops)

    player = await repo.get_player("player_fail")
    assert player is not None
    assert player["gold"] == 100


@pytest.mark.asyncio
async def test_migrate_v1_to_v2_is_idempotent(repo):
    migrated = await repo.migrate_v1_to_v2()
    assert migrated is True

    # Running twice should still succeed without duplicate-column errors.
    migrated_again = await repo.migrate_v1_to_v2()
    assert migrated_again is True

    async with aiosqlite.connect(repo.db_path) as db:
        async with db.execute("PRAGMA table_info(quests)") as cursor:
            columns = [row[1] for row in await cursor.fetchall()]

    assert "objectives" in columns
    assert "prerequisites" in columns
    assert "deadline" in columns


@pytest.mark.asyncio
async def test_backup_and_restore_database(repo, tmp_path):
    await repo.create_player("player_backup", "Backup Player", 300)

    backup_path = tmp_path / "backup.db"
    created_backup = await repo.backup_database(str(backup_path))
    assert created_backup == str(backup_path)

    # Mutate data after backup, then restore.
    await repo.update_player_gold("player_backup", 10)
    changed_player = await repo.get_player("player_backup")
    assert changed_player is not None
    assert changed_player["gold"] == 10

    restored = await repo.restore_database(str(backup_path))
    assert restored is True

    restored_player = await repo.get_player("player_backup")
    assert restored_player is not None
    assert restored_player["gold"] == 300
