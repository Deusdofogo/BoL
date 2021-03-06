--[[

	Shadow Vayne Script by Aroc

	For Functions & Changelog, check the Thread on the BoL Forums:
	http://botoflegends.com/forum/topic/18939-shadow-vayne-the-mighty-hunter/
	]]
--if myHero.charName ~= 'Vayne' then return end
class "ScriptUpdate"
function ScriptUpdate:__init(LocalVersion, Host, VersionPath, ScriptPath, SavePath, CallbackUpdate, CallbackNoUpdate, CallbackNewVersion)
    self.LocalVersion = LocalVersion
    self.Host = Host
    self.VersionPath = '/BoL/TCPUpdater/GetScript2.php?script='..self:Base64Encode(self.Host..VersionPath)..'&rand='..math.random(99999999)
    self.ScriptPath = '/BoL/TCPUpdater/GetScript2.php?script='..self:Base64Encode(self.Host..ScriptPath)..'&rand='..math.random(99999999)
    self.SavePath = SavePath
    self.CallbackUpdate = CallbackUpdate
    self.CallbackNoUpdate = CallbackNoUpdate
    self.CallbackNewVersion = CallbackNewVersion
    self.LuaSocket = require("socket")
    self.Socket = self.LuaSocket.connect('sx-bol.eu', 80)
    self.Socket:send("GET "..self.VersionPath.." HTTP/1.0\r\nHost: sx-bol.eu\r\n\r\n")
    self.Socket:settimeout(0, 'b')
    self.Socket:settimeout(99999999, 't')
    self.LastPrint = ""
    self.File = ""
    AddTickCallback(function() self:GetOnlineVersion() end)
end

function ScriptUpdate:Base64Encode(data)
    local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    return ((data:gsub('.', function(x)
        local r,b='',x:byte()
        for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
        return r;
    end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
        if (#x < 6) then return '' end
        local c=0
        for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
        return b:sub(c+1,c+1)
    end)..({ '', '==', '=' })[#data%3+1])
end

function ScriptUpdate:GetOnlineVersion()
    if self.Status == 'closed' then return end
    self.Receive, self.Status, self.Snipped = self.Socket:receive(1024)

    if self.Receive then
        if self.LastPrint ~= self.Receive then
            self.LastPrint = self.Receive
            self.File = self.File .. self.Receive
        end
    end

    if self.Snipped ~= "" and self.Snipped then
        self.File = self.File .. self.Snipped
    end
    if self.Status == 'closed' then
        local HeaderEnd, ContentStart = self.File:find('\r\n\r\n')
        if HeaderEnd and ContentStart then
            self.OnlineVersion = tonumber(self.File:sub(ContentStart + 1))
            if self.OnlineVersion > self.LocalVersion then
                if self.CallbackNewVersion and type(self.CallbackNewVersion) == 'function' then
                    self.CallbackNewVersion(self.OnlineVersion,self.LocalVersion)
                end
                self.DownloadSocket = self.LuaSocket.connect('sx-bol.eu', 80)
                self.DownloadSocket:send("GET "..self.ScriptPath.." HTTP/1.0\r\nHost: sx-bol.eu\r\n\r\n")
                self.DownloadSocket:settimeout(0, 'b')
                self.DownloadSocket:settimeout(99999999, 't')
                self.LastPrint = ""
                self.File = ""
                AddTickCallback(function() self:DownloadUpdate() end)
            else
                if self.CallbackNoUpdate and type(self.CallbackNoUpdate) == 'function' then
                    self.CallbackNoUpdate(self.LocalVersion)
                end
            end
        else
            print('Error: Could not get end of Header')
        end
    end
end

function ScriptUpdate:DownloadUpdate()
    if self.DownloadStatus == 'closed' then return end
    self.DownloadReceive, self.DownloadStatus, self.DownloadSnipped = self.DownloadSocket:receive(1024)

    if self.DownloadReceive then
        if self.LastPrint ~= self.DownloadReceive then
            self.LastPrint = self.DownloadReceive
            self.File = self.File .. self.DownloadReceive
        end
    end

    if self.DownloadSnipped ~= "" and self.DownloadSnipped then
        self.File = self.File .. self.DownloadSnipped
    end

    if self.DownloadStatus == 'closed' then
        local HeaderEnd, ContentStart = self.File:find('\r\n\r\n')
        if HeaderEnd and ContentStart then
            local ScriptFileOpen = io.open(self.SavePath, "w+")
            ScriptFileOpen:write(self.File:sub(ContentStart + 1))
            ScriptFileOpen:close()
            if self.CallbackUpdate and type(self.CallbackUpdate) == 'function' then
                self.CallbackUpdate(self.OnlineVersion,self.LocalVersion)
            end
        end
    end
end

------------------------
------ LoadScript ------
------------------------

function OnLoad()
    require 'SxOrbWalk'
    require 'VPrediction'
    VP = VPrediction()
    DelayAction(function()
        if not SxOrb or not SxOrb.Version or SxOrb.Version < 2.29 then print('<font color=\'#F0Ff8d\'><b>ShadowVayne:</b></font> <font color=\'#FF0F0F\'>Loading Failed. Please Update SxOrbWalk to newest Version</font>') return end
        if not VP or not VP.version or VP.version < 2.863 then print('<font color=\'#F0Ff8d\'><b>ShadowVayne:</b></font> <font color=\'#FF0F0F\'>Loading Failed. Please Update VPrediction to newest Version</font>') return end
        ShadowVayne()
    end,0.1)
end

------------------------
------ ShadowVayne -----
------------------------
class 'ShadowVayne'
function ShadowVayne:__init()
    self.version = 5.17
    self.LastTarget = nil
    self.LastLevelCheck = 0
    self.Items = {}
    self.MapIndex = GetGame().map.index
    print('<font color=\'#F0Ff8d\'><b>ShadowVayne:</b></font> <font color=\'#FF0F0F\'>Version '..self.version..' loaded</font>')
    local ToUpdate = {}
    ToUpdate.Version = self.version
    ToUpdate.Host = "raw.githubusercontent.com"
    ToUpdate.VersionPath = "/Superx321/BoL/master/ShadowVayne.Version"
    ToUpdate.ScriptPath = "/Superx321/BoL/master/ShadowVayne.lua"
    ToUpdate.SavePath = SCRIPT_PATH.."ShadowVayne.lua"
    ToUpdate.CallbackUpdate = function(NewVersion,OldVersion) print("<font color=\"#F0Ff8d\"><b>ShadowVayne: </b></font> <font color=\"#FF0F0F\">Updated to "..NewVersion..". Please Reload with 2x F9</b></font>") end
    ToUpdate.CallbackNoUpdate = function(OldVersion) print("<font color=\"#F0Ff8d\"><b>ShadowVayne: </b></font> <font color=\"#FF0F0F\">No Updates Found</b></font>") end
    ToUpdate.CallbackNewVersion = function(NewVersion) print("<font color=\"#F0Ff8d\"><b>ShadowVayne: </b></font> <font color=\"#FF0F0F\">New Version found ("..NewVersion.."). Please wait until its downloaded</b></font>") end
    ScriptUpdate(ToUpdate.Version, ToUpdate.Host, ToUpdate.VersionPath, ToUpdate.ScriptPath, ToUpdate.SavePath, ToUpdate.CallbackUpdate,ToUpdate.CallbackNoUpdate, ToUpdate.CallbackNewVersion)
    self:GenerateTables()
    self:GetOrbWalkers()
--    self:LevelSpell(_W)
end

function ShadowVayne:GenerateTables()
    self.isAGapcloserUnitTarget = {
        ['AkaliShadowDance']		= {true, Champ = 'Akali', 		spellKey = 'R'},
        ['Headbutt']     			= {true, Champ = 'Alistar', 	spellKey = 'W'},
        ['DianaTeleport']       	= {true, Champ = 'Diana', 		spellKey = 'R'},
        ['IreliaGatotsu']     		= {true, Champ = 'Irelia',		spellKey = 'Q'},
        ['JaxLeapStrike']         	= {true, Champ = 'Jax', 		spellKey = 'Q'},
        ['JayceToTheSkies']       	= {true, Champ = 'Jayce',		spellKey = 'Q'},
        ['MaokaiUnstableGrowth']    = {true, Champ = 'Maokai',		spellKey = 'W'},
        ['MonkeyKingNimbus']  		= {true, Champ = 'MonkeyKing',	spellKey = 'E'},
        ['Pantheon_LeapBash']   	= {true, Champ = 'Pantheon',	spellKey = 'W'},
        ['PoppyHeroicCharge']       = {true, Champ = 'Poppy',		spellKey = 'E'},
        ['QuinnE']       			= {true, Champ = 'Quinn',		spellKey = 'E'},
        ['XenZhaoSweep']     		= {true, Champ = 'XinZhao',		spellKey = 'E'},
        ['blindmonkqtwo']	    	= {true, Champ = 'LeeSin',		spellKey = 'Q'},
        ['FizzPiercingStrike']	    = {true, Champ = 'Fizz',		spellKey = 'Q'},
        ['RengarLeap']	    		= {true, Champ = 'Rengar',		spellKey = 'Q/R'},
    }

    self.isAGapcloserUnitNoTarget = {
        ['AatroxQ']					= {true, Champ = 'Aatrox', 		range = 1000,  	projSpeed = 1200, spellKey = 'Q'},
        ['GragasE']					= {true, Champ = 'Gragas', 		range = 600,   	projSpeed = 2000, spellKey = 'E'},
        ['GravesMove']				= {true, Champ = 'Graves', 		range = 425,   	projSpeed = 2000, spellKey = 'E'},
        ['HecarimUlt']				= {true, Champ = 'Hecarim', 	range = 1000,   projSpeed = 1200, spellKey = 'R'},
        ['JarvanIVDragonStrike']	= {true, Champ = 'JarvanIV',	range = 770,   	projSpeed = 2000, spellKey = 'Q'},
        ['JarvanIVCataclysm']		= {true, Champ = 'JarvanIV', 	range = 650,   	projSpeed = 2000, spellKey = 'R'},
        ['KhazixE']					= {true, Champ = 'Khazix', 		range = 900,   	projSpeed = 2000, spellKey = 'E'},
        ['khazixelong']				= {true, Champ = 'Khazix', 		range = 900,   	projSpeed = 2000, spellKey = 'E'},
        ['LeblancSlide']			= {true, Champ = 'Leblanc', 	range = 600,   	projSpeed = 2000, spellKey = 'W'},
        ['LeblancSlideM']			= {true, Champ = 'Leblanc', 	range = 600,   	projSpeed = 2000, spellKey = 'WMimic'},
        ['LeonaZenithBlade']		= {true, Champ = 'Leona', 		range = 900,  	projSpeed = 2000, spellKey = 'E'},
        ['UFSlash']					= {true, Champ = 'Malphite', 	range = 1000,  	projSpeed = 1800, spellKey = 'R'},
        ['RenektonSliceAndDice']	= {true, Champ = 'Renekton', 	range = 450,  	projSpeed = 2000, spellKey = 'E'},
        ['SejuaniArcticAssault']	= {true, Champ = 'Sejuani', 	range = 650,  	projSpeed = 2000, spellKey = 'Q'},
        ['ShenShadowDash']			= {true, Champ = 'Shen', 		range = 575,  	projSpeed = 2000, spellKey = 'E'},
        ['RocketJump']				= {true, Champ = 'Tristana', 	range = 900,  	projSpeed = 2000, spellKey = 'W'},
        ['slashCast']				= {true, Champ = 'Tryndamere', 	range = 650,  	projSpeed = 1450, spellKey = 'E'},
    }

    self.isAChampToInterrupt = {
        ['KatarinaR']					= {true, Champ = 'Katarina',	spellKey = 'R'},
        ['GalioIdolOfDurand']			= {true, Champ = 'Galio',		spellKey = 'R'},
        ['Crowstorm']					= {true, Champ = 'FiddleSticks',spellKey = 'R'},
        ['Drain']						= {true, Champ = 'FiddleSticks',spellKey = 'W'},
        ['AbsoluteZero']				= {true, Champ = 'Nunu',		spellKey = 'R'},
        ['ShenStandUnited']				= {true, Champ = 'Shen',		spellKey = 'R'},
        ['UrgotSwap2']					= {true, Champ = 'Urgot',		spellKey = 'R'},
        ['AlZaharNetherGrasp']			= {true, Champ = 'Malzahar',	spellKey = 'R'},
        ['FallenOne']					= {true, Champ = 'Karthus',		spellKey = 'R'},
        ['Pantheon_GrandSkyfall_Jump']	= {true, Champ = 'Pantheon',	spellKey = 'R'},
        ['VarusQ']						= {true, Champ = 'Varus',		spellKey = 'Q'},
        ['CaitlynAceintheHole']			= {true, Champ = 'Caitlyn',		spellKey = 'R'},
        ['MissFortuneBulletTime']		= {true, Champ = 'MissFortune',	spellKey = 'R'},
        ['InfiniteDuress']				= {true, Champ = 'Warwick',		spellKey = 'R'},
        ['LucianR']						= {true, Champ = 'Lucian',		spellKey = 'R'}
    }

    self.AutoLevelSpellTable = {
        ['SpellOrder']	= {'QWE', 'QEW', 'WQE', 'WEQ', 'EQW', 'EWQ'},
        ['QWE']	= {_Q,_W,_E,_Q,_Q,_R,_Q,_W,_Q,_W,_R,_W,_W,_E,_E,_R,_E,_E},
        ['QEW']	= {_Q,_E,_W,_Q,_Q,_R,_Q,_E,_Q,_E,_R,_E,_E,_W,_W,_R,_W,_W},
        ['WQE']	= {_W,_Q,_E,_W,_W,_R,_W,_Q,_W,_Q,_R,_Q,_Q,_E,_E,_R,_E,_E},
        ['WEQ']	= {_W,_E,_Q,_W,_W,_R,_W,_E,_W,_E,_R,_E,_E,_Q,_Q,_R,_Q,_Q},
        ['EQW']	= {_E,_Q,_W,_E,_E,_R,_E,_Q,_E,_Q,_R,_Q,_Q,_W,_W,_R,_W,_W},
        ['EWQ']	= {_E,_W,_Q,_E,_E,_R,_E,_W,_E,_W,_R,_W,_W,_Q,_Q,_R,_Q,_Q}
    }

    self.Color = { Red = ARGB(0xFF,0xFF,0,0),Green = ARGB(0xFF,0,0xFF,0),Blue = ARGB(0xFF,0,0,0xFF), White = ARGB(0xFF,0xFF,0xFF,0xFF), Black = ARGB(0xFF, 0x00, 0x00, 0x00) }
end

function ShadowVayne:GetOrbWalkers()
    self.OrbWalkers = {}
    table.insert(self.OrbWalkers, 'SxOrb')

    if _G.MMA_Loaded then
        table.insert(self.OrbWalkers, 'MMA')
    end

    if _G.RebornScriptName then
        table.insert(self.OrbWalkers, 'SAC:Reborn')
        print('<font color=\'#F0Ff8d\'><b>ShadowVayne:</b></font> <font color=\'#FF0F0F\'>Waiting for SAC:Reborn Auth</font>')
        AddTickCallback(function() self:WaitForReborn() end)
    else
        self:LoadMenu()
    end
end

function ShadowVayne:WaitForReborn()
    if self.Loaded then return end
    if _G.AutoCarry then
        self:LoadMenu()
    end
end

function ShadowVayne:LoadMenu()
    self.Menu = scriptConfig('ShadowVayne', 'SV_MAIN')
    self.Menu:addSubMenu('[Condemn]: AntiGapCloser Settings', 'anticapcloser')
    self.Menu:addSubMenu('[Condemn]: AutoStun Settings', 'autostunn')
    self.Menu:addSubMenu('[Condemn]: AutoStun Targets', 'targets')
    self.Menu:addSubMenu('[Condemn]: Interrupt Settings', 'interrupt')
    self.Menu:addSubMenu('[Tumble]: Settings', 'tumble')
    self.Menu:addSubMenu('[Misc]: Key Settings', 'keysetting')
    self.Menu:addSubMenu('[Misc]: AutoLevelSpells Settings', 'autolevel')
    self.Menu:addSubMenu('[Misc]: Draw Settings', 'draw')
    self.Menu:addSubMenu('[BotRK]: Settings', 'botrk')
    self.Menu:addSubMenu('[Bilgewater]: Settings', 'bilgewater')
    self.Menu:addSubMenu('[Youmuu\'s]: Settings', 'youmuus')

    -- KeySetting Menu
    self.Menu.keysetting:addParam('nil','Basic Key Settings', SCRIPT_PARAM_INFO, '')
    self.Menu.keysetting:addParam('AfterAACondemn','Condemn on next BasicAttack:', SCRIPT_PARAM_ONKEYTOGGLE, false, string.byte( 'E' ))
    self.Menu.keysetting:addParam('OrbWalker', 'Choose the Orbwalker: ', SCRIPT_PARAM_LIST, 1, self.OrbWalkers)

    for index, param in pairs(self.Menu.keysetting._param) do
        if param['var'] == 'OrbWalker' then
            self.StartListParam = index
        end
    end
    if self.Menu.keysetting._param[self.StartListParam].listTable[self.Menu.keysetting.OrbWalker] == nil then self.Menu.keysetting.OrbWalker = 1 end

    -- GapCloser
    local FoundAGapCloser = false
    for index, data in pairs(self.isAGapcloserUnitTarget) do
        for index2, enemy in ipairs(GetEnemyHeroes()) do
            if data['Champ'] == enemy.charName then
                self.Menu.anticapcloser:addSubMenu(enemy.charName..' '..data.spellKey, enemy.charName)
                self.Menu.anticapcloser[enemy.charName]:addParam('fap', 'Pushback '..enemy.charName..' '..data.spellKey..'...', SCRIPT_PARAM_INFO, '')
                self.Menu.anticapcloser[enemy.charName]:addParam('FightMode', 'in FightMode', SCRIPT_PARAM_ONOFF, true)
                self.Menu.anticapcloser[enemy.charName]:addParam('HarassMode', 'in HarassMode', SCRIPT_PARAM_ONOFF, true)
                self.Menu.anticapcloser[enemy.charName]:addParam('LaneClear', 'in LaneClear', SCRIPT_PARAM_ONOFF, false)
                self.Menu.anticapcloser[enemy.charName]:addParam('LastHit', 'in LastHit', SCRIPT_PARAM_ONOFF, false)
                self.Menu.anticapcloser[enemy.charName]:addParam('Always', 'Always', SCRIPT_PARAM_ONOFF, false)
                FoundAGapCloser = true
            end
        end
    end
    for index, data in pairs(self.isAGapcloserUnitNoTarget) do
        for index2, enemy in ipairs(GetEnemyHeroes()) do
            if data['Champ'] == enemy.charName then
                self.Menu.anticapcloser:addSubMenu(enemy.charName..' '..data.spellKey, enemy.charName)
                self.Menu.anticapcloser[enemy.charName]:addParam('fap', 'Pushback '..enemy.charName..' '..data.spellKey..'...', SCRIPT_PARAM_INFO, '')
                self.Menu.anticapcloser[enemy.charName]:addParam('FightMode', 'in FightMode', SCRIPT_PARAM_ONOFF, true)
                self.Menu.anticapcloser[enemy.charName]:addParam('HarassMode', 'in HarassMode', SCRIPT_PARAM_ONOFF, true)
                self.Menu.anticapcloser[enemy.charName]:addParam('LaneClear', 'in LaneClear', SCRIPT_PARAM_ONOFF, false)
                self.Menu.anticapcloser[enemy.charName]:addParam('LastHit', 'in LastHit', SCRIPT_PARAM_ONOFF, false)
                self.Menu.anticapcloser[enemy.charName]:addParam('Always', 'Always', SCRIPT_PARAM_ONOFF, false)
                FoundAGapCloser = true
            end
        end
    end
    if not FoundAGapCloser then self.Menu.anticapcloser:addParam('nil','No Enemy Gapclosers found', SCRIPT_PARAM_INFO, '') end

    -- StunTargets
    local FoundStunTarget = false
    for index, enemy in ipairs(GetEnemyHeroes()) do
        self.Menu.targets:addSubMenu(enemy.charName, enemy.charName)
        self.Menu.targets[enemy.charName]:addParam('fap', 'Stun '..enemy.charName..'...', SCRIPT_PARAM_INFO, '')
        self.Menu.targets[enemy.charName]:addParam('FightMode', 'in FightMode', SCRIPT_PARAM_ONOFF, true)
        self.Menu.targets[enemy.charName]:addParam('HarassMode', 'in HarassMode', SCRIPT_PARAM_ONOFF, false)
        self.Menu.targets[enemy.charName]:addParam('LaneClear', 'in LaneClear', SCRIPT_PARAM_ONOFF, false)
        self.Menu.targets[enemy.charName]:addParam('LastHit', 'in LastHit', SCRIPT_PARAM_ONOFF, false)
        self.Menu.targets[enemy.charName]:addParam('Always', 'Always', SCRIPT_PARAM_ONOFF, false)
        FoundStunTarget = true
    end
    if not FoundStunTarget then self.Menu.targets:addParam('nil','No Enemies to Stun found', SCRIPT_PARAM_INFO, '') end

    -- Interrupt
    local Foundinterrupt = false
    for index, data in pairs(self.isAChampToInterrupt) do
        for index, enemy in ipairs(GetEnemyHeroes()) do
            if data['Champ'] == enemy.charName then
                self.Menu.interrupt:addSubMenu(enemy.charName..' '..data.spellKey..'...', enemy.charName)
                self.Menu.interrupt[enemy.charName]:addParam('fap', 'Interrupt '..enemy.charName..' '..data.spellKey, SCRIPT_PARAM_INFO, '')
                self.Menu.interrupt[enemy.charName]:addParam('FightMode', 'in FightMode', SCRIPT_PARAM_ONOFF, true)
                self.Menu.interrupt[enemy.charName]:addParam('HarassMode', 'in HarassMode', SCRIPT_PARAM_ONOFF, true)
                self.Menu.interrupt[enemy.charName]:addParam('LaneClear', 'in LaneClear', SCRIPT_PARAM_ONOFF, true)
                self.Menu.interrupt[enemy.charName]:addParam('LastHit', 'in LastHit', SCRIPT_PARAM_ONOFF, true)
                self.Menu.interrupt[enemy.charName]:addParam('Always', 'Always', SCRIPT_PARAM_ONOFF, true)
                Foundinterrupt = true
            end
        end
    end
    if not Foundinterrupt then self.Menu.interrupt:addParam('nil','No Enemies to Interrupt found', SCRIPT_PARAM_INFO, '') end

    -- StunSettings
    self.Menu.autostunn:addParam('PushDistance', 'Push Distance', SCRIPT_PARAM_SLICE, 390, 0, 450, 0)
    self.Menu.autostunn:addParam('TowerStun', 'Stun if Enemy lands unter a Tower', SCRIPT_PARAM_ONOFF, false)
    self.Menu.autostunn:addParam('Trinket', 'Use Auto-Trinket Bush', SCRIPT_PARAM_ONOFF, true)
    self.Menu.autostunn:addParam('Target', 'Stun only Current Target', SCRIPT_PARAM_ONOFF, true)

    -- Draw
    self.Menu.draw:addParam('ERange', 'Draw E Range', SCRIPT_PARAM_ONOFF, true)
    self.Menu.draw:addParam('EColor', 'E Range Color', SCRIPT_PARAM_COLOR, {141, 124, 4, 4})

    -- AutoLevel
    self.Menu.autolevel:addParam('UseAutoLevelFirst', 'Use AutoLevelSpells Level 1-3', SCRIPT_PARAM_ONOFF, false)
    self.Menu.autolevel:addParam('UseAutoLevelRest', 'Use AutoLevelSpells Level 4-18', SCRIPT_PARAM_ONOFF, false)
    self.Menu.autolevel:addParam('First3Level', 'Level 1-3:', SCRIPT_PARAM_LIST, 1, { 'Q-W-E', 'Q-E-W', 'W-Q-E', 'W-E-Q', 'E-Q-W', 'E-W-Q' })
    self.Menu.autolevel:addParam('RestLevel', 'Level 4-18:', SCRIPT_PARAM_LIST, 1, { 'Q-W-E', 'Q-E-W', 'W-Q-E', 'W-E-Q', 'E-Q-W', 'E-W-Q' })
    self.Menu.autolevel:addParam('fap', '', SCRIPT_PARAM_INFO, '','' )
    self.Menu.autolevel:addParam('fap', 'You can Click on the \'Q-W-E\'', SCRIPT_PARAM_INFO, '','' )
    self.Menu.autolevel:addParam('fap', 'to change the AutoLevelOrder', SCRIPT_PARAM_INFO, '','' )

    -- BotRK
    self.Menu.botrk:addParam('FightMode', 'Use BotRK in FightMode', SCRIPT_PARAM_ONOFF, true)
    self.Menu.botrk:addParam('HarassMode', 'Use BotRK in HarassMode', SCRIPT_PARAM_ONOFF, false)
    self.Menu.botrk:addParam('LaneClear', 'Use BotRK in LaneClear', SCRIPT_PARAM_ONOFF, false)
    self.Menu.botrk:addParam('LastHit', 'Use BotRK in LastHit', SCRIPT_PARAM_ONOFF, false)
    self.Menu.botrk:addParam('Always', 'Use BotRK Always', SCRIPT_PARAM_ONOFF, false)
    self.Menu.botrk:addParam('MaxOwnHealth', 'Max Own Health Percent', SCRIPT_PARAM_SLICE, 50, 1, 100, 0)
    self.Menu.botrk:addParam('MinEnemyHealth', 'Min Enemy Health Percent', SCRIPT_PARAM_SLICE, 20, 1, 100, 0)

    -- Bilgewater
    self.Menu.bilgewater:addParam('FightMode', 'Use BilgeWater Cutlass in FightMode', SCRIPT_PARAM_ONOFF, true)
    self.Menu.bilgewater:addParam('HarassMode', 'Use BilgeWater Cutlass in HarassMode', SCRIPT_PARAM_ONOFF, false)
    self.Menu.bilgewater:addParam('LaneClear', 'Use BilgeWater Cutlass in LaneClear', SCRIPT_PARAM_ONOFF, false)
    self.Menu.bilgewater:addParam('LastHit', 'Use BilgeWater Cutlass in LastHit', SCRIPT_PARAM_ONOFF, false)
    self.Menu.bilgewater:addParam('Always', 'Use BilgeWater Cutlass Always', SCRIPT_PARAM_ONOFF, false)
    self.Menu.bilgewater:addParam('MaxOwnHealth', 'Max Own Health Percent', SCRIPT_PARAM_SLICE, 50, 1, 100, 0)
    self.Menu.bilgewater:addParam('MinEnemyHealth', 'Min Enemy Health Percent', SCRIPT_PARAM_SLICE, 20, 1, 100, 0)

    -- Yomuus
    self.Menu.youmuus:addParam('FightMode', 'Use Youmuus Ghostblade in FightMode', SCRIPT_PARAM_ONOFF, true)
    self.Menu.youmuus:addParam('HarassMode', 'Use Youmuus Ghostblade in HarassMode', SCRIPT_PARAM_ONOFF, false)
    self.Menu.youmuus:addParam('LaneClear', 'Use Youmuus Ghostblade in LaneClear', SCRIPT_PARAM_ONOFF, false)
    self.Menu.youmuus:addParam('LastHit', 'Use Youmuus Ghostblade in LastHit', SCRIPT_PARAM_ONOFF, false)
    self.Menu.youmuus:addParam('Always', 'Use Youmuus Ghostblade Always', SCRIPT_PARAM_ONOFF, false)

    -- Tumble
    self.Menu.tumble:addParam('FightMode', 'Use Tumble in FightMode', SCRIPT_PARAM_ONOFF, true)
    self.Menu.tumble:addParam('HarassMode', 'Use Tumble in HarassMode', SCRIPT_PARAM_ONOFF, false)
    self.Menu.tumble:addParam('LaneClear', 'Use Tumble in LaneClear', SCRIPT_PARAM_ONOFF, false)
    self.Menu.tumble:addParam('LastHit', 'Use Tumble in LastHit', SCRIPT_PARAM_ONOFF, false)
    self.Menu.tumble:addParam('Always', 'Use Tumble Always', SCRIPT_PARAM_ONOFF, false)
    self.Menu.tumble:addParam('fap', '', SCRIPT_PARAM_INFO, '','' )
    self.Menu.tumble:addParam('ManaFightMode', 'Min Mana to use Q in FightMode', SCRIPT_PARAM_SLICE, 0, 0, 100, 0)
    self.Menu.tumble:addParam('ManaHarassMode', 'Min Mana to use Q in HarassMode', SCRIPT_PARAM_SLICE, 50, 0, 100, 0)
    self.Menu.tumble:addParam('ManaLaneClear', 'Min Mana to use Q in LaneClear', SCRIPT_PARAM_SLICE, 50, 0, 100, 0)
    self.Menu.tumble:addParam('ManaLastHit', 'Min Mana to use Q in LastHit', SCRIPT_PARAM_SLICE, 50, 0, 100, 0)

    self:MenuLoaded()
end

function ShadowVayne:MenuLoaded()
    self.Loaded = true
    SxOrb:LoadToMenu(nil)
    AddTickCallback(function() self:CheckLevelChange() end)
    AddTickCallback(function() self:CheckItems() end)
    AddTickCallback(function() self:ActivateModes() end)
    AddTickCallback(function() self:BotRK() end)
    AddTickCallback(function() self:BilgeWater() end)
    AddTickCallback(function() self:CondemnStun() end)

    AddDrawCallback(function() self:OnDraw() end)
    AddProcessSpellCallback(function(unit, spell) self:OnProcessSpell(unit, spell) end)
end

function ShadowVayne:ActivateModes()
    self.SelectedOrbWalker  = self.Menu.keysetting.OrbWalker
    if self.SelectedOrbWalker ~= 1 then
        _G.SxOrb.Deactivate = true
    else
        _G.SxOrb.Deactivate = false
    end
    if self.SelectedOrbWalker then
        self.IsFight = _G.SxOrb.IsFight
        self.IsHarass = _G.SxOrb.IsHarass
        self.IsLaneClear = _G.SxOrb.IsLaneClear
        self.IsLastHit = _G.SxOrb.IsLastHit
    else
        self.IsFight = _G.AutoCarry.Keys.AutoCarry
        self.IsHarass = _G.AutoCarry.Keys.MixedMode
        self.IsLaneClear = _G.AutoCarry.Keys.LaneClear
        self.IsLastHit = _G.AutoCarry.Keys.LastHit
    end
end

function ShadowVayne:CheckModesActive(Menu)
    if Menu.FightMode and self.IsFight then
        return true
    elseif Menu.HarassMode and self.IsHarass then
        return true
    elseif Menu.LaneClear and self.IsLaneClear then
        return true
    elseif Menu.LastHit and self.IsLastHit then
        return true
    elseif Menu.Always then
        return true
    else
        return false
    end
end

function ShadowVayne:CheckLevelChange()
    if self.LastLevelCheck + 250 < GetTickCount() then
        if self.MapIndex == 8 and myHero.level < 4 and self.Menu.autolevel.UseAutoLevelFirst then
            self:LevelSpell(_Q)
            self:LevelSpell(_W)
            self:LevelSpell(_E)
        end

        self.LastLevelCheck = GetTickCount()
        if myHero.level ~= self.LastHeroLevel then
            DelayAction(function() self:LevelUpSpell() end, 0.25)
            self.LastHeroLevel = myHero.level
        end
    end
end

function ShadowVayne:LevelUpSpell()
    if self.Menu.autolevel.UseAutoLevelFirst and myHero.level < 4 then
        self:LevelSpell(self.AutoLevelSpellTable[self.AutoLevelSpellTable['SpellOrder'][self.Menu.autolevel.First3Level]][myHero.level])
    end

    if self.Menu.autolevel.UseAutoLevelRest and myHero.level > 3 then
        self:LevelSpell(self.AutoLevelSpellTable[self.AutoLevelSpellTable['SpellOrder'][self.Menu.autolevel.RestLevel]][myHero.level])
    end
end

function ShadowVayne:CheckItems()
    if (self.LastItemCheck or 0) + 250 < GetTickCount() then
        self.LastItemCheck = GetTickCount()
        self.Items.BotRK = GetInventorySlotItem(3153)
        self.Items.BilgeWater = GetInventorySlotItem(3144)
        self.Items.Youmuus = GetInventorySlotItem(3142)
    end
end

function ShadowVayne:BotRK()
    if self.Items.BotRK and self:CheckModesActive(self.Menu.botrk) then
        if (math.floor(myHero.health / myHero.maxHealth * 100)) <= self.Menu.botrk.MaxOwnHealth then
            local Target = self:GetTarget()
            if Target and ValidTarget(Target, 510) then
                if (math.floor(Target.health / Target.maxHealth * 100)) >= self.Menu.botrk.MinEnemyHealth then
                    if myHero:CanUseSpell(self.Items.BotRK) == 0 then
                        CastSpell(self.Items.BotRK, Target)
                    end
                end
            end
        end
    end
end

function ShadowVayne:BilgeWater()
    if self.Items.BilgeWater and self:CheckModesActive(self.Menu.bilgewater) then
        if (math.floor(myHero.health / myHero.maxHealth * 100)) <= self.Menu.bilgewater.MaxOwnHealth then
            local Target = self:GetTarget()
            if Target and ValidTarget(Target, 450) then
                if (math.floor(Target.health / Target.maxHealth * 100)) >= self.Menu.bilgewater.MinEnemyHealth then
                    if myHero:CanUseSpell(self.Items.BilgeWater) == 0 then
                        CastSpell(self.Items.BilgeWater, Target)
                    end
                end
            end
        end
    end
end

function ShadowVayne:Youmuus()
    if self.Items.Youmuus and self:CheckModesActive(self.Menu.youmuus) then
        if myHero:CanUseSpell(self.Items.Youmuus) == 0 then
            CastSpell(self.Items.Youmuus)
        end
    end
end

function ShadowVayne:OnProcessSpell(unit, spell)
    if unit.team ~= myHero.team then
        if self.isAGapcloserUnitTarget[spell.name] then
            if spell.target and spell.target.networkID == myHero.networkID then
                if self:CheckModesActive(self.Menu.anticapcloser[unit.charName]) then CastSpell(_E, unit) end
            end
        end

        if self.isAChampToInterrupt[spell.name] and GetDistanceSqr(unit) <= 715*715 then
            if self:CheckModesActive(self.Menu.interrupt[unit.charName]) then CastSpell(_E, unit) end
        end

        if self.isAGapcloserUnitNoTarget[spell.name] and GetDistanceSqr(unit) <= 2000*2000 and (spell.target == nil or (spell.target and spell.target.isMe)) then
            if self:CheckModesActive(self.Menu.anticapcloser[unit.charName]) then
                SpellInfo = {
                    Source = unit,
                    CastTime = os.clock(),
                    --~ 					Direction = (spell.endPos - spell.startPos):normalized(),
                    StartPos = Point(unit.pos.x, unit.pos.z),
                    Range = self.isAGapcloserUnitNoTarget[spell.name].range,
                    Speed = self.isAGapcloserUnitNoTarget[spell.name].projSpeed,
                }
                --                self:CondemnGapCloser(SpellInfo)
            end
        end
    end

    if unit.isMe and spell.name:lower():find('attack') then
        DelayAction(function() self:Youmuus() end, spell.windUpTime)
        if spell.target then self.LastTarget = spell.target end
        if self.Menu.keysetting.AfterAACondemn and self.LastTarget.type == myHero.type then
            DelayAction(function() CastSpell(_E, self.LastTarget) end, spell.windUpTime + GetLatency()/2000)
            self.Menu.keysetting.AfterAACondemn = false
        else
            DelayAction(function() self:Tumble(self.LastTarget) end, spell.windUpTime + GetLatency()/2000)
        end
    end
end

function ShadowVayne:CondemnGapCloser(SpellInfo)
    if (os.clock() - SpellInfo.CastTime) <= (SpellInfo.Range/SpellInfo.Speed) and myHero:CanUseSpell(_E) == READY then
        local EndPosition = Vector(SpellInfo.StartPos) + (Vector(SpellInfo.StartPos) - SpellInfo.EndPos):normalized()*(SpellInfo.Range)
        local StartPosition = SpellInfo.StartPos + SpellInfo.Direction
        local EndPosition   = SpellInfo.StartPos + (SpellInfo.Direction * SpellInfo.Range)
        local MyPosition = Point(myHero.x, myHero.z)
        local SkillShot = LineSegment(Point(StartPosition.x, StartPosition.y), Point(EndPosition.x, EndPosition.y))
        if GetDistanceSqr(MyPosition,SkillShot) <= 400*400 then
            self.CondemnTarget = SpellInfo.Source
        else
            DelayAction(function() self:CondemnGapCloser(SpellInfo) end)
        end
    end
end

function ShadowVayne:Tumble(Target)
    if Target and Target.type ~= 'obj_AI_Turret' then
        local ManaCalc = 100/myHero.maxMana*myHero.mana
        if  (self.Menu.tumble.FightMode and self.IsFight and (ManaCalc > self.Menu.tumble.ManaFightMode)) or
                (self.Menu.tumble.HarassMode and self.IsHarass and (ManaCalc > self.Menu.tumble.ManaHarassMode)) or
                (self.Menu.tumble.LaneClear and self.IsLaneClear and (ManaCalc > self.Menu.tumble.ManaLaneClear)) or
                (self.Menu.tumble.LastHit and  self.IsLastHit and (ManaCalc > self.Menu.tumble.ManaLastHit)) or
                (self.Menu.tumble.Always) then
            local AfterTumblePos = myHero + (Vector(mousePos) - myHero):normalized() * 300
            local DistanceAfterTumble = GetDistanceSqr(AfterTumblePos, Target)
            if  DistanceAfterTumble < 630*630 and DistanceAfterTumble > 100*100 then
                CastSpell(_Q, mousePos.x, mousePos.z)
                --                SendChat("/l")
                --                myHero:Attack(Target)
            end
            if GetDistanceSqr(Target) > 630*630 and DistanceAfterTumble < 630*630 then
                CastSpell(_Q, mousePos.x, mousePos.z)
                --                SendChat("/l")
                --                myHero:Attack(Target)
            end
        end
    end
end

function ShadowVayne:OnDraw()
    if self.Menu.draw.ERange then
        self:CircleDraw(myHero.x, myHero.y, myHero.z, 710, ARGB(self.Menu.draw.EColor[1], self.Menu.draw.EColor[2],self.Menu.draw.EColor[3],self.Menu.draw.EColor[4]))
    end
    if self.CastEDraw then
        DrawCircle(self.CastEDraw.x, self.CastEDraw.y, self.CastEDraw.z, 150, ARGB(0xFF,0xFF,0xFF,0xFF))
    end

    if self.Menu.keysetting.AfterAACondemn then
        local myPos = WorldToScreen(D3DXVECTOR3(myHero.x, myHero.y, myHero.z))
        DrawText("Auto-Condemn After Next AA is on!!",15, myPos.x, myPos.y, self.Color.Red)
    end


end

function ShadowVayne:CheckWallStun(Target)
    local Pos, Hitchance, PredictPos = VP:GetLineCastPosition(Target, 0.350, 0, 600, 2200, myHero, false)
    if Hitchance > 1 then
        local checks = 30
        local CheckD = math.ceil(self.Menu.autostunn.PushDistance / checks)
        local FoundGrass = false
        for i = 1, checks  do
            local CheckWallPos = Vector(PredictPos) + Vector(Vector(PredictPos) - Vector(myHero)):normalized()*(CheckD*i)
            if not FoundGrass and IsWallOfGrass(D3DXVECTOR3(CheckWallPos.x, CheckWallPos.y, CheckWallPos.z)) then
                FoundGrass = CheckWallPos
            end
            local WallPoint = IsWall(D3DXVECTOR3(CheckWallPos.x, CheckWallPos.y, CheckWallPos.z))
            --            local Distance = GetDistanceSqr(WallPoint.endPath, CheckWallPos)
            if WallPoint then
                self.CastEDraw = CheckWallPos
                --                print('CastSpell E:' ..math.sqrt(Distance))
                if UnderTurret(CheckWallPos, true) then
                    if self.Menu.autostunn.TowerStun then
                        CastSpell(_E, Target)
                        break
                    end
                else
                    CastSpell(_E, Target)
                    if FoundGrass then DelayAction(function() CastSpell(ITEM_7) end, 0.25) end
                    break
                end
            end
        end
    end
end

function ShadowVayne:CondemnStun()
    if myHero:CanUseSpell(_E) == READY then
        if self.Menu.autostunn.Target then
            local Target = self:GetTarget()
            if Target and Target.type == myHero.type and ValidTarget(Target, 710) and self:CheckModesActive(self.Menu.targets[Target.charName]) then
                self:CheckWallStun(Target)
            end
        else
            for i, enemy in ipairs(GetEnemyHeroes()) do
                if enemy and ValidTarget(enemy, 710) and self:CheckModesActive(self.Menu.targets[enemy.charName]) then
                    self:CheckWallStun(enemy)
                end
            end
        end
    end
end

function ShadowVayne:DrawCircleNextLvl(x, y, z, radius, width, color, chordlength)
    radius = radius or 300
    quality = math.max(8,math.floor(180/math.deg((math.asin((chordlength/(2*radius)))))))
    quality = 2 * math.pi / quality
    radius = radius*.92
    local points = {}
    for theta = 0, 2 * math.pi + quality, quality do
        local c = WorldToScreen(D3DXVECTOR3(x + radius * math.cos(theta), y, z - radius * math.sin(theta)))
        points[#points + 1] = D3DXVECTOR2(c.x, c.y)
    end
    DrawLines2(points, width or 1, color or 4294967295)
end

function ShadowVayne:DrawCircle2(x, y, z, radius, color)
    local vPos1 = Vector(x, y, z)
    local vPos2 = Vector(cameraPos.x, cameraPos.y, cameraPos.z)
    local tPos = vPos1 - (vPos1 - vPos2):normalized() * radius
    local sPos = WorldToScreen(D3DXVECTOR3(tPos.x, tPos.y, tPos.z))
    if OnScreen({ x = sPos.x, y = sPos.y }, { x = sPos.x, y = sPos.y })  then
        self:DrawCircleNextLvl(x, y, z, radius, 1, color, 75)
    end
end

function ShadowVayne:CircleDraw(x,y,z,radius, color)
    self:DrawCircle2(x, y, z, radius, color)
end

function ShadowVayne:GetTarget()
    if self.IsFight then
        if self.FightModeOrbText == 'MMA' then return _G.MMA_ConsideredTarget() end
        if self.FightModeOrbText == 'SAC:Reborn' then return _G.AutoCarry.Crosshair:GetTarget() end
        if self.FightModeOrbText == 'SxOrb' then return SxOrb:GetTarget() end
    elseif self.IsHarass then
        if self.HarassModeOrbText == 'MMA' then return _G.MMA_ConsideredTarget() end
        if self.HarassModeOrbText == 'SAC:Reborn' then return _G.AutoCarry.Crosshair:GetTarget() end
        if self.HarassModeOrbText == 'SxOrb' then return SxOrb:GetTarget() end
    elseif self.IsLastHit then
        if self.LastHitOrbText == 'MMA' then return _G.MMA_ConsideredTarget() end
        if self.LastHitOrbText == 'SAC:Reborn' then return _G.AutoCarry.Crosshair:GetTarget() end
        if self.LastHitOrbText == 'SxOrb' then return SxOrb:GetTarget() end
    elseif self.IsLaneClear then
        if self.LaneClearOrbText == 'MMA' then return _G.MMA_ConsideredTarget() end
        if self.LaneClearOrbText == 'SAC:Reborn' then return _G.AutoCarry.Crosshair:GetTarget() end
        if self.LaneClearOrbText == 'SxOrb' then return SxOrb:GetTarget() end
    end
end

function ShadowVayne:LevelSpell(Spell)
	if VIP_USER then
        local packet = CLoLPacket(0x009A)
        packet.vTable = 0xF246E0
        packet:EncodeF(myHero.networkID)
        packet:Encode4(0x5A5A5A5A)
        packet:Encode1(0x46)
        packet:Encode4(0xD5D5D5D5)
        packet:Encode1(Spell == _Q and 0x83 or Spell == _W and 0x08 or Spell == _E and 0xB5 or Spell == _R and 0xEC)
        packet:Encode4(0x07070707)
        packet:Encode1(Spell == _Q and 0x2C or Spell == _W and 0xB0 or Spell == _E and 0xC3 or Spell == _R and 0x31)
        packet:Encode1(Spell == _Q and 0xC1 or Spell == _W and 0xC3 or Spell == _E and 0xC6 or Spell == _R and 0xC8)
        packet:Encode1(0x31)
        packet:Encode1(0x1F)
        SendPacket(packet)
        end
end
