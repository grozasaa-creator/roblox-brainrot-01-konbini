-- クライアントの起動点。表示と入力だけを担当し、お金や所持の判断は全てサーバーに任せる。
local Players = game:GetService("Players")

local HudController = require(script.Parent.HudController)
local LabelBillboard = require(script.Parent.LabelBillboard)
local CarryInput = require(script.Parent.CarryInput)
local Effects = require(script.Parent.Effects)
local CodexUi = require(script.Parent.CodexUi)

local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

local hud = HudController.create(playerGui)
CodexUi.create(playerGui, hud)
LabelBillboard.start()
CarryInput.start(hud)
Effects.start(hud)
