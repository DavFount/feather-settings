local Menu = exports['feather-menu'].initiate()
local settingsMenu = Menu:RegisterMenu('feather-settings:main', {
    top='50%', left='50%', ['720width']='400px', ['1080width']='450px',
    ['2kwidth']='500px', ['4kwidth']='600px', draggable=true, canclose=true
})
local mainPage = settingsMenu:RegisterPage('feather-settings:main:page')
local languagePage = settingsMenu:RegisterPage('feather-settings:language')

local function Translate(key)
    local result = exports['feather-core']:TranslateLocale(0, key)
    return type(result) == 'table' and result.ok and result.value or key
end
local function PvpState()
    local ok, state = pcall(function() return exports['feather-pvp']:GetState() end)
    return ok and type(state) == 'table' and state.enabled == true
end
local header = mainPage:RegisterElement('header', { value='Settings', slot='header' })
local pvpToggle
pvpToggle = mainPage:RegisterElement('toggle', { label='PVP', start=PvpState(), persist=true }, function()
    local ok, enabled = pcall(function() return exports['feather-pvp']:Toggle() end)
    if ok then pvpToggle:update({ value=enabled, label=enabled and 'PVP: On' or 'PVP: Off' }) end
end)
local languageButton = mainPage:RegisterElement('button', { label='Language', slot='content' }, function()
    languagePage:RouteTo()
end)
for code, label in pairs(Config.Languages) do
    languagePage:RegisterElement('button', { label=label, slot='content' }, function()
        local updated = exports['feather-core']:CallRPCAsync('core.account.settings.update.v1', { locale=code })
        if type(updated) == 'table' and updated.ok then
            exports['feather-core']:SetClientLocale(updated.value.locale)
            languageButton:update({ label=('%s: %s'):format(Translate('ui_settings_locale_title'), label) })
            header:update({ value=Translate('ui_settings_title') })
        end
        mainPage:RouteTo()
    end)
end
languagePage:RegisterElement('bottomline', { slot='footer' })
languagePage:RegisterElement('button', { label='Back', slot='footer' }, function() mainPage:RouteTo() end)

local function ToggleMenu()
    if Menu.activeMenu and Menu.activeMenu.menuID == 'feather-settings:main' then settingsMenu:Close(); return end
    settingsMenu:Open({ startupPage=mainPage })
    header:update({ value=Translate('ui_settings_title') })
    local enabled = PvpState()
    pvpToggle:update({ value=enabled, label=enabled and 'PVP: On' or 'PVP: Off' })
    local current = exports['feather-core']:CallRPCAsync('core.account.settings.get.v1', {})
    local locale = type(current) == 'table' and current.ok and current.value.locale or Config.DefaultLocale
    languageButton:update({ label=('%s: %s'):format(Translate('ui_settings_locale_title'), Config.Languages[locale] or locale) })
end
CreateThread(function()
    while true do
        Wait(0)
        if Citizen.InvokeNative(0x580417101DDB492F, 0, Config.Hotkey)
            or Citizen.InvokeNative(0x91AEF906BCA88877, 0, Config.Hotkey) then ToggleMenu() end
    end
end)
RegisterCommand('SettingsClientSmokeTest', function()
    local pvp = PvpState()
    local settings = exports['feather-core']:CallRPCAsync('core.account.settings.get.v1', {})
    print(('[SettingsClientSmokeTest] pvp provider            %s'):format(type(pvp) == 'boolean' and 'PASS' or 'FAIL'))
    print(('[SettingsClientSmokeTest] account settings route  %s'):format(type(settings) == 'table' and settings.ok and 'PASS' or 'FAIL'))
end, false)
