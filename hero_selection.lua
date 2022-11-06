function Think()
    for playerID = 0, 4, 1 do
        if GetSelectedHeroName(playerID) == "" then
            SelectHero(playerID, "npc_dota_hero_skeleton_king")
        end
    end
end
