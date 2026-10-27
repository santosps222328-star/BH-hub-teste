-- GameAPI.lua
-- NÃO implementado por padrão. Este módulo é o CONTRATO entre a automação e o
-- seu jogo. Substitua cada função por uma chamada à lógica legítima do seu jogo.
-- Se uma função não existir, o serviço correspondente se auto-desativa e emite
-- um aviso no cliente — nada quebra.

local GameAPI = {}

-- Combate
-- attack(targetModel: Model): boolean  -- aplica o dano do SEU sistema de combate
function GameAPI.attack(_targetModel) return false end

-- Retorna a vida/energia atuais do personagem (0..1 cada).
function GameAPI.getResources(_player) return { health = 1, energy = 1 } end

-- Coleta
-- Retorna lista { {id=string, model=BasePart, position=Vector3} }
function GameAPI.listCollectibles(_player) return {} end
function GameAPI.tryCollect(_player, _itemId) return false end

-- Raids
-- Retorna lista { {id=string, name=string, cost=number, minLevel=number, steps=number} }
function GameAPI.listRaids(_player) return {} end
function GameAPI.startRaid(_player, _raidId) return false end
function GameAPI.raidStatus(_player) return nil end  -- { wave, totalWaves, alive, done, failed }

-- Chefes
-- Retorna lista { {id, name, level, respawnAt (os.time unix ou nil), model} }
function GameAPI.listBosses(_player) return {} end

-- Maestria
-- Retorna { Sword = {level, xp, nextXp}, Melee = {...}, ... }
function GameAPI.getMastery(_player) return {} end
function GameAPI.equipCategory(_player, _category) return false end

-- Progressão
function GameAPI.getLevel(_player) return 1 end
function GameAPI.getXP(_player) return 0 end

-- Inventário (fonte da verdade: SERVIDOR)
-- Retorna { {id, name, rarity, category, qty} }
function GameAPI.getInventory(_player) return {} end
function GameAPI.inventorySpace(_player) return { used = 0, max = 50 } end

return GameAPI
