local InputService = game:GetService('UserInputService');
local TextService = game:GetService('TextService');
local CoreGui = game:GetService('CoreGui');
local Teams = game:GetService('Teams');
local Players = game:GetService('Players');
local RunService = game:GetService('RunService')
local TweenService = game:GetService('TweenService');
local Lighting = game:GetService('Lighting');
local RenderStepped = RunService.RenderStepped;
local LocalPlayer = Players.LocalPlayer;
local Mouse = LocalPlayer:GetMouse();

local ProtectGui = protectgui or (syn and syn.protect_gui) or (function() end);

local ScreenGui = Instance.new('ScreenGui');
ProtectGui(ScreenGui);
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global;
ScreenGui.Parent = CoreGui;

local Toggles = {};
local Options = {};

local function ForceLowerCase(Value)
    if type(Value) == 'string' then
        return string.lower(Value);
    end;
    return Value;
end;

getgenv().Toggles = Toggles;
getgenv().Options = Options;

local Library = {
    Registry = {};
    RegistryMap = {};

    HudRegistry = {};

    FontColor = Color3.fromRGB(235, 239, 246);
    MainColor = Color3.fromRGB(15, 17, 22);
    BackgroundColor = Color3.fromRGB(9, 11, 15);
    AccentColor = Color3.fromRGB(70, 116, 174);
    OutlineColor = Color3.fromRGB(39, 45, 55);
    RiskColor = Color3.fromRGB(255, 50, 50),

    Black = Color3.new(0, 0, 0);

    Font = Enum.Font.GothamRounded,
    FontSize = 14,

    OpenedFrames = {};
    DependencyBoxes = {};

    Signals = {};
    ScreenGui = ScreenGui;

    Toggled = false;
    WindowOpen = false;
    dpc = Color3.fromRGB(255, 255, 255);
    WireframeDrag = true;
    UseBlur = false;
    BlurSize = 15;

    KeybindMode = 'All';

    NotifyConfig = {
        Alignment = 'Left';
        BarSide   = 'Left';
        PositionX = 0;
        PositionY = 40;
    };
};

Library.KeyPickerList = {};

Library.BlurEffect = Instance.new("BlurEffect")
Library.BlurEffect.Name = "LinoriaBlur"
Library.BlurEffect.Size = 0
Library.BlurEffect.Enabled = false
pcall(function() Library.BlurEffect.Parent = Lighting end)

function Library:UpdateBlur()
    if Library.UseBlur then
        if Library.Toggled then
            Library.BlurEffect.Enabled = true
            TweenService:Create(Library.BlurEffect, TweenInfo.new(0.2, Enum.EasingStyle.Linear), {Size = Library.BlurSize}):Play()
        end
    else
        local tween = TweenService:Create(Library.BlurEffect, TweenInfo.new(0.2, Enum.EasingStyle.Linear), {Size = 0})
        tween:Play()
    
        task.delay(0.2, function()
            if not Library.UseBlur then
                Library.BlurEffect.Enabled = false
