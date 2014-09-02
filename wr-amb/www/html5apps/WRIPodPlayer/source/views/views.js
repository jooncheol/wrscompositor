var websocket = null;
var playstate = 0;
var artworkImage = null;
var haha = null;


enyo.kind({
    name: "myapp.MainView",
    classes: "app onyx font-lato enyo-unselectable",
    handlers: {
        onresize: "resized",
        onHideSongList: "hideSongList"
    },
    components:[
        {kind: "enyo.Panels",
            name: "mainPanels",
            classes: "panels enyo-fit",

            components: [
                {kind: "enyo.Panels", name: "contentPanels", classes: "enyo-fit",
                    arrangerKind: "CardArranger", onTransitionFinish: "contentTransitionCompleted",
                    components: [
                        {kind: "FittableRows", name: "controller", classes: "wide", fit: true, components: [
                            {kind: "FittableColumns", noStretch: true, fit: true, classes: "song-info-align-center", components: [
                                {kind: "enyo.Image", name: "artwork", classes: "artwork-image" },
                                {kind: "FittableRows", classes: "song-info-center", components: [
                                    {name: "songTitle", content: "", style: "text-align: left; margin-bottom: 10px"},
                                    {name: "songAlbum", content: "", style: "text-align: left; margin-bottom: 10px"},
                                    {name: "songArtist", content: "", style: "text-align: left; margin-bottom: 10px"},
                                    {kind: "FittableColumns", components: [
                                        {name: "songCurrentTime", style: "text-align: left"},
                                        {content: "/", classes: "song-timeinfo" },
                                        {name: "songTotalTime", style: "text-align: right"},
                                    ]},
                                ]},
                            ]},
                            {kind: "onyx.ProgressBar", name: "timeTrack", progress: 0, showStripes: false},
                            {kind: "onyx.Toolbar", layoutKind: "FittableColumnsLayout", noStretch:true, classes: "control-toolbar", components: [
                                {kind: "FittableColumns", noStretch: true, components: [
                                    {kind: "onyx.IconButton", src: "assets/prev.png", ontap: "prevOnTap"},
                                    {kind: "onyx.IconButton", src: "assets/pause.png", name: "playButton", ontap: "playOnTap"},
                                    {kind: "onyx.IconButton", src: "assets/next.png", ontap: "nextOnTap"},
                                ]},
                                {fit: true},
                                {kind: "onyx.IconButton", name: "listButton", src: "assets/list.png", classes: "list-button", ontap: "listOnTab"},
                            ]},
                        ]},
                    ]
                },
            ]
        },
    ],

    create: function() {
        this.inherited(arguments);
        haha = this;

        var wsUrl = "ws://"+window.location.hostname+":9090/";
        websocket = new WebSocket(wsUrl, 'ipod');

        websocket.onopen = function(evt) { console.log('onopen'); };
        websocket.onclose = function(evt) { console.log('onclose'); };
        websocket.onmessage =  enyo.bind(this, handleMessage);
        websocket.onerror = function(evt) { console.log('onopen'); };
    },

    prevOnTap: function(inSender, inEvent) {
        this.command("prev");
    },

    playOnTap: function(inSender, inEvent) {
        if (playstate == 4) { // playing
            this.$.playButton.setSrc("assets/pause.png");
            this.command("pause");
        } else if (playstate == 0 || playstate == 5) { // stopped or paused
            this.$.playButton.setSrc("assets/play.png");
            this.command("play");
        }
    },

    updatePlayPauseButton: function() {
        if (playstate == 4) { // playing
            this.$.playButton.setSrc("assets/pause.png");
        } else if (playstate == 5) { // paused
            this.$.playButton.setSrc("assets/play.png");
        }
    },

    updateArtwork: function(src) {
        this.$.artwork.setSrc(src);
    },

    nextOnTap: function(inSender, inEvent) {
        this.command("next");
    },

    listOnTab: function(inSender, inEvent) {
        var newComponent = this.$.contentPanels.createComponent({name: "songList", kind: "songListView"}, {owner: this});
        newComponent.render();
        this.$.contentPanels.render();
        this.$.contentPanels.setIndex(1);
    },

    updateTrackTimeInfo: function(current, total) {
        var currentTime = Math.floor(current / 1000);
        currentTime = Math.floor(currentTime / 60) + ":" + (currentTime % 60);
        this.$.songCurrentTime.setContent(currentTime);
        if (total != null) {
            var totalTime = Math.floor(total / 1000);
            totalTime = Math.floor(totalTime / 60) + ":" + (totalTime % 60);
            this.$.songTotalTime.setContent(totalTime);
        }
    },

    hideSongList: function(inSender, inEvent) {
        this.hidingSongList = true;
        this.$.contentPanels.setIndex(0);
        //this.updateArtwork('data:image/png;base64,' + artworkImage);
        //console.log("artwork : " + artworkImage);
    },

    resized: function() {
        console.log("resized");
    },

    contentTransitionCompleted: function(inSender, inEvent) {
        if (this.hidingSongList) {
            this.destroySongList();
        }
    },

    destroySongList: function() {
        this.$.songList.destroy();
        this.hidingSongList = false;
    },


    command: function(func) {
        var args = new Array;
        for(var i=1; i<arguments.length; i++)
            args.push(arguments[i]);
        var obj = {"function": func, "args": args};
        console.log(obj);
        websocket.send(JSON.stringify(obj));
    },

});

enyo.kind({
    name: "songListView",
    kind: "FittableRows",
    events: {
        onHideSongList: ""
    },
    components: [
        {content: "list..."},
        /*
        {kind: "onyx.Toolbar", layoutKind: "FittableColumnsLayout", fit: true, components: [
            {kind: "onyx.Button", content: "Close", ontap: "doHideSongList"}
        ]}
        */
        {fit: true},
        {kind: "onyx.Toolbar", layoutKind: "FittableColumnsLayout", noStretch: true, components: [
            {fit: true},
            {kind: "onyx.IconButton", name: "CloseButton", src: "assets/close.png", ontap: "doHideSongList"},
        ]},

    ],
});

function handleMessage(event) {
    console.log('handle message');
    //console.log('event :' + event.data);
    var obj = JSON.parse(event.data);
    console.log(obj);
    var evt = obj.event;
    var data = obj.data;
    var conn = obj.connection;

    if (conn != null && conn) {
        this.command('get_trackinfo');
    } else if (evt == "track info") {
        playstate = data.playstate;
        this.updatePlayPauseButton();
        if (playstate == 0) {
            this.updateArtwork("assets/default_artwork.jpg");
        }

        var trackLength = data.track_length;
        this.updateTrackTimeInfo(data.track_position, trackLength);

        this.$.timeTrack.max = trackLength;
        this.$.songTitle.setContent("title : " + data.title);
        this.$.songAlbum.setContent("album : " + data.album);
        this.$.songArtist.setContent("artist : " + data.artist);
        this.command('get_artwork', obj.data.track_index);
    } else if (evt == "current artwork") {
        artworkImage = data.image;
        this.updateArtwork('data:image/png;base64,' + artworkImage);
    } else if (evt == "track position changed") {
        this.$.timeTrack.animateProgressTo(data);
        this.updateTrackTimeInfo(data);
    } else if (evt == "track changed") {
        this.$.timeTrack.animateProgressTo(0);
    } else if (evt == "playstate changed") {
        playstate = data;
        this.updatePlayPauseButton();
    }
}
