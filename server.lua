local RSGCore = exports['rsg-core']:GetCoreObject()

RegisterServerEvent('disposebody:payplayer')
AddEventHandler('disposebody:payplayer', function(payAmount)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if Player then
        Player.Functions.AddMoney('cash', payAmount)
        TriggerClientEvent('RSGCore:Notify', src, 'You received $' .. payAmount .. ' for disposing of the body', 'success')
    end
end)