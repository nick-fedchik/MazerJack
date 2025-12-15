--[[
    Тип: ModuleScript
    Назва: GameConfig
    Версія: 1.2.0
    Розміщення: ReplicatedStorage/Config/GameConfig

    Призначення:
      Єдине джерело правди для глобальної конфігурації гри.
      Тут зберігається версія гри (GameVersion), назва гри, назви DataStore та версія схеми персистенсу.

    Загальна логіка:
      - MainServer читає GameName/GameVersion і логує їх ОДИН раз на Boot.
      - PersistenceService використовує DataStoreName/DataStoreKeyPrefix/PersistentSchemaVersion.
      - Усі інші скрипти НЕ повинні дублювати версію гри в логах.

    Контракти / правила:
      - Версія гри: Major.Minor.Patch
      - Патч-версії змінюють лише третю цифру.
--]]

local GameConfig = {}

----------------------------------------------------------------
-- Ідентифікація гри
----------------------------------------------------------------

GameConfig.GameName = "MazerJack"
GameConfig.GameVersion = "1.2.0"

----------------------------------------------------------------
-- DataStore (персистенс гравця)
----------------------------------------------------------------

GameConfig.DataStoreName = "MazerJack_PlayerState"
GameConfig.DataStoreKeyPrefix = "P_"

----------------------------------------------------------------
-- Версія схеми персистенсу (Major.Minor.Patch)
----------------------------------------------------------------

GameConfig.PersistentSchemaVersion = "1.2.0"

return GameConfig

----------------------------------------------------------------
-- End of script: GameConfig v1.2.0
----------------------------------------------------------------
