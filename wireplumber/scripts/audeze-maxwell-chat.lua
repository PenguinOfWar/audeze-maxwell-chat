MAXWELL_VENDOR_ID  = "0x3329"
MAXWELL_PRODUCT_ID = "0x4b19"

log                = Log.open_topic("audeze-maxwell-chat")

game_node          = nil

function createGameSink(device, card_num)
    local alsa_path = "hw:" .. card_num .. ",1"
    log:info("Creating Audeze Maxwell Game sink on " .. alsa_path)

    local props = {
        ["device.id"]           = device["bound-id"],
        ["factory.name"]        = "api.alsa.pcm.sink",
        ["node.name"]           = "alsa_output.audeze-maxwell-game",
        ["node.description"]    = "Audeze Maxwell Game",
        ["node.nick"]           = "Audeze Maxwell Game",
        ["media.class"]         = "Audio/Sink",
        ["api.alsa.path"]       = alsa_path,
        ["api.alsa.pcm.card"]   = card_num,
        ["api.alsa.pcm.device"] = "1",
        ["api.alsa.pcm.stream"] = "playback",
        ["api.alsa.use-acp"]    = false,
        ["audio.channels"]      = "2",
        ["audio.position"]      = "[ FL, FR ]",
        ["node.pause-on-idle"]  = false,
        ["priority.driver"]     = 1000,
        ["priority.session"]    = 1000,
    }

    local node = Node("adapter", props)
    node:activate(Feature.Proxy.BOUND, function(n, err)
        if err then
            log:warning("Failed to create Audeze Maxwell Game sink: " .. tostring(err))
            game_node = nil
        else
            log:info("Audeze Maxwell Game sink created successfully")
        end
    end)

    return node
end

devices_om = ObjectManager {
    Interest {
        type = "device",
        Constraint { "device.api", "=", "alsa" },
    }
}

devices_om:connect("object-added", function(_, device)
    local props = device.properties

    if props["device.vendor.id"] ~= MAXWELL_VENDOR_ID or
        props["device.product.id"] ~= MAXWELL_PRODUCT_ID then
        return
    end

    if game_node ~= nil then
        log:info("Maxwell already has a Game sink, skipping")
        return
    end

    local card_num = props["alsa.card"]
    if card_num == nil then
        log:warning("Maxwell device found but alsa.card is nil, cannot create Game sink")
        return
    end

    log:info("Maxwell Dongle detected (card " .. card_num .. "), creating Game sink")
    game_node = createGameSink(device, card_num)
end)

devices_om:connect("object-removed", function(_, device)
    local props = device.properties

    if props["device.vendor.id"] ~= MAXWELL_VENDOR_ID or
        props["device.product.id"] ~= MAXWELL_PRODUCT_ID then
        return
    end

    if game_node ~= nil then
        log:info("Maxwell Dongle removed, destroying Game sink")
        game_node = nil
    end
end)

devices_om:activate()
