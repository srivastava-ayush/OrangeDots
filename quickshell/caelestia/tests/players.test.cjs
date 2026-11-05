const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const test = require("node:test");
const vm = require("node:vm");

// Exercise the service's actual selection functions with fake MPRIS players.
const source = fs.readFileSync(path.join(__dirname, "../services/Players.qml"), "utf8");
function fixture() {
    const spotify = { identity: "Spotify", isPlaying: false };
    const brave = { identity: "Brave", isPlaying: false };
    const context = vm.createContext({
        list: [spotify, brave],
        props: { manualActive: null },
        GlobalConfig: { services: { defaultPlayer: "Spotify" } },
        getIdentity: player => player.identity,
    });
    for (const name of ["selectActive", "followPlayback"]) {
        const body = source.match(new RegExp(`    function ${name}\\([^]*?\\n    }`))[0]
            .replace(/: MprisPlayer|: void/g, "");
        vm.runInContext(body, context);
    }
    return { context, spotify, brave };
}

test("playing source wins over the default before any selection", () => {
    const { context, spotify, brave } = fixture();
    assert.equal(context.selectActive(), spotify);
    brave.isPlaying = true;
    assert.equal(context.selectActive(), brave);
});

test("Brave takes over from selected Spotify and stays selected on pause", () => {
    const { context, spotify, brave } = fixture();
    spotify.isPlaying = true;
    context.props.manualActive = spotify;
    brave.isPlaying = true;
    context.followPlayback(brave);
    assert.equal(context.selectActive(), brave);
    brave.isPlaying = false;
    context.followPlayback(brave);
    assert.equal(context.selectActive(), brave);
    spotify.isPlaying = false;
    context.followPlayback(spotify);
    assert.equal(context.selectActive(), brave);
    spotify.isPlaying = true;
    context.followPlayback(spotify);
    assert.equal(context.selectActive(), spotify);
});

test("manual selection works until another source starts playback", () => {
    const { context, spotify, brave } = fixture();
    brave.isPlaying = true;
    context.props.manualActive = spotify;
    assert.equal(context.selectActive(), spotify);
    context.followPlayback(brave);
    assert.equal(context.selectActive(), brave);
});

test("disconnected sources cannot stay selected or take over", () => {
    const { context, spotify, brave } = fixture();
    context.props.manualActive = brave;
    context.list = [spotify];
    brave.isPlaying = true;
    context.followPlayback(brave);
    assert.equal(context.selectActive(), spotify);
    context.list = [];
    assert.equal(context.selectActive(), null);
});

test("service watches playback changes and already-playing new sources", () => {
    assert.match(source, /Instantiator\s*\{\s*model: root\.list/);
    assert.match(source, /onIsPlayingChanged\(\): void\s*\{\s*root\.followPlayback\(modelData\)/);
    assert.match(source, /Component\.onCompleted: root\.followPlayback\(modelData\)/);
});
