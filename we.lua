-- Load Rayfield library
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Create main window
local Window = Rayfield:CreateWindow({
    Name = "DioRUS HUB",
    Icon = 0,
    LoadingTitle = "Arm Wrestle Simulator",
    LoadingSubtitle = "by DiorEЯ",
    Theme = "Default",
    DisableRayfieldPrompts = true,
    ConfigurationSaving = {
        Enabled = true,
        FileName = "Big Hub",
    },
    KeySystem = true,
    KeySettings = {
        Title = "Untitled",
        Subtitle = "Key System",
        Note = "No method of obtaining the key is provided",
        FileName = "Key",
        SaveKey = true,
        Key = {"DiorTop"},
    },
})

local Tab = Window:CreateTab("Machines")

-- Initialize state variables
local ownedPetData = {}
local uniquePetNames = {}
local selectedPetName = nil
local selectedMutation = nil
local stopLoop = false
local PetDropdown

-- Fetch owned pets function
local function fetchOwnedPets()
    ownedPetData = {}
    uniquePetNames = {}

    local PetServiceRF = game:GetService("ReplicatedStorage").Packages.Knit.Services.PetService.RF:FindFirstChild("getOwned")

    if PetServiceRF and PetServiceRF:IsA("RemoteFunction") then
        local success, petData = pcall(PetServiceRF.InvokeServer, PetServiceRF)
        if success and type(petData) == "table" then
            for petId, petInfo in pairs(petData) do
                local displayName = petInfo.DisplayName or "Unknown"
                ownedPetData[displayName] = ownedPetData[displayName] or {}
                table.insert(ownedPetData[displayName], {
                    Id = petId,
                    Locked = petInfo.Locked,
                    Mutation = petInfo.Mutation or "No Mutation"
                })
            end

            -- Populate unique pet names
            for petName, petInstances in pairs(ownedPetData) do
                for _, petInfo in ipairs(petInstances) do
                    -- Debugging output to verify Locked status
                    print("Pet Name:", petName, "Locked:", petInfo.Locked) 
                    
                    if not petInfo.Locked and not table.find(uniquePetNames, petName) then
                        table.insert(uniquePetNames, petName)
                        break
                    end
                end
            end
            return true
        else
            warn("Failed to fetch pet data or received invalid data.")
        end
    else
        warn("PetServiceRF is not a valid RemoteFunction.")
    end
    return false
end

-- Function to create Pet Dropdown
local function createPetDropdown()
    if PetDropdown then
        PetDropdown:Destroy()
    end

    PetDropdown = Tab:CreateDropdown({
        Name = "Select Pet",
        Options = uniquePetNames,
        Callback = function(value)
            selectedPetName = value
        end,
    })
end

-- Create mutation selection dropdown
local MutationDropdown = Tab:CreateDropdown({
    Name = "Select Mutation",
    Options = { "Glowing", "Rainbow", "Ghost", "Cosmic" },
    Callback = function(value)
        selectedMutation = value
    end,
})

-- Create toggles for keeping certain pets
local KeepGhostToggle = Tab:CreateToggle({
    Name = "Keep Ghost Pets",
    Default = false,
})

local KeepCosmicToggle = Tab:CreateToggle({
    Name = "Keep Cosmic Pets",
    Default = false,
})

-- Placeholder function for auto mutation
local function autoCureThenMutateLoop()
    while not stopLoop do
        if selectedPetName then
            local petsToMutate = {}
            for _, petInfo in ipairs(ownedPetData[selectedPetName] or {}) do
                -- Debugging output to verify Locked status
                print("Checking pet for mutation:", petInfo.Id, "Locked:", petInfo.Locked)
                
                if not petInfo.Locked then
                    table.insert(petsToMutate, petInfo.Id)
                end
            end

            if #petsToMutate > 0 then
                local PetMutateFn = game:GetService("ReplicatedStorage").Packages.Knit.Services.PetCombineService.RF:FindFirstChild("mutate")
                if PetMutateFn then
                    for _, petId in ipairs(petsToMutate) do
                        local mutateArgs = { [1] = petId, [2] = { MutationType = selectedMutation } }
                        local success, err = pcall(PetMutateFn.InvokeServer, PetMutateFn, unpack(mutateArgs))
                        if not success then
                            warn("Mutation failed for pet ID:", petId, "Error:", err)
                        end
                    end
                    fetchOwnedPets()  -- Refresh pet data after mutation
                else
                    warn("Mutate function not found!")
                end
            else
                warn("No unlocked pets available for mutation.")
            end
        end
        wait(5)  -- Wait before the next iteration
    end
end

-- Create auto mutate toggle
local AutoMutateToggle = Tab:CreateToggle({
    Name = "Enable Auto Mutate Loop",
    Default = false,
    Callback = function(value)
        stopLoop = not value
        if value then
            autoCureThenMutateLoop()
        end
    end,
})

-- Create button for random mutation
Tab:CreateButton({
    Name = "Randomly Mutate Pets",
    Callback = function()
        if not selectedPetName then
            warn("Please select a pet name before using the mutation button.")
            return
        end

        local petsToMutate = {}
        for _, petInfo in ipairs(ownedPetData[selectedPetName] or {}) do
            -- Debugging output to verify Locked status
            print("Checking pet for random mutation:", petInfo.Id, "Locked:", petInfo.Locked)
            
            if not petInfo.Locked then
                table.insert(petsToMutate, petInfo.Id)
            end
        end

        if #petsToMutate == 0 then
            warn("No unlocked pets available for mutation.")
            return
        end

        local PetMutateFn = game:GetService("ReplicatedStorage").Packages.Knit.Services.PetCombineService.RF:FindFirstChild("mutate")
        if PetMutateFn then
            for _, petId in ipairs(petsToMutate) do
                local mutateArgs = { [1] = petId, [2] = { MutationType = selectedMutation } }
                local success, err = pcall(PetMutateFn.InvokeServer, PetMutateFn, unpack(mutateArgs))
                if not success then
                    warn("Mutation failed for pet ID:", petId, "Error:", err)
                end
            end
            fetchOwnedPets()  -- Refresh pet data after mutation
        else
            warn("Mutate function not found!")
        end
    end,
})

-- Initial fetch of pets and dropdown creation
if fetchOwnedPets() then
    createPetDropdown()
end

-- Update dropdown options periodically
spawn(function()
    while true do
        if fetchOwnedPets() then
            createPetDropdown()  -- Update dropdown with new options
        end
        wait(5)
    end
end)
