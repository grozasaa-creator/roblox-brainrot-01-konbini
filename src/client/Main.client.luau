-- Client entry: connects the server's state feed to the HUD and starts the guidance and feedback layers.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)

local Client = script.Parent
local ClientState = require(Client.ClientState)
local HudController = require(Client.HudController)
local CodexUi = require(Client.CodexUi)
local Guide = require(Client.Guide)
local LabelBillboard = require(Client.LabelBillboard)
local PromptGate = require(Client.PromptGate)
local CarryInput = require(Client.CarryInput)
local Effects = require(Client.Effects)

local remotes = Remotes.client()

local function sendAction(name)
	remotes.Action:FireServer(name)
end

remotes.State.OnClientEvent:Connect(ClientState.setSnapshot)

CodexUi.start()
HudController.start(sendAction, CodexUi.toggle)
Effects.start(remotes)
LabelBillboard.start()
PromptGate.start()
CarryInput.start(sendAction, CodexUi.toggle)
Guide.start()
