local myaudio = audio
local sharedEngine = SimpleAudioEngine:sharedEngine()
local userDefault = CCUserDefault:sharedUserDefault()

local soundSwitch = true
local musicSwitch = true
local musicFilename = nil
local musicLooping = false

function myaudio.loadSwitch()
    soundSwitch = userDefault:getBoolForKey("SoundSwitch", true)
    musicSwitch = userDefault:getBoolForKey("MusicSwitch", true)
end

function myaudio.isSoundSwitch()
    return soundSwitch
end

function myaudio.isMusicSwitch()
    return musicSwitch
end

function myaudio.switchSound(open)
    soundSwitch = open
    userDefault:setBoolForKey("SoundSwitch", soundSwitch)
end

function myaudio.switchMusic(open)
    musicSwitch = open
    userDefault:setBoolForKey("MusicSwitch", musicSwitch)

    if musicFilename then
        if open then
            audio.playMusic(musicFilename, musicLooping)
        else
            audio.stopMusic()
        end
    end
end

function myaudio.playSound(filename, isLoop)
    if not soundSwitch then
        return
    end

    if not filename then
        printError("audio.playSound() - invalid filename")
        return
    end
    if type(isLoop) ~= "boolean" then isLoop = false end
    if DEBUG > 1 then
        printInfo("audio.playSound() - filename: %s, isLoop: %s", tostring(filename), tostring(isLoop))
    end
    return sharedEngine:playEffect(filename, isLoop)
end

function myaudio.playMusic(filename, isLoop)
    musicFilename = filename
    musicLooping = isLoop
    if not musicSwitch then
        return
    end

    if not filename then
        printError("audio.playMusic() - invalid filename")
        return
    end
    if type(isLoop) ~= "boolean" then isLoop = true end

    audio.stopMusic()
    if DEBUG > 1 then
        printInfo("audio.playMusic() - filename: %s, isLoop: %s", tostring(filename), tostring(isLoop))
    end
    sharedEngine:playBackgroundMusic(filename, isLoop)
end

