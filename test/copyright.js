var Copyright = artifacts.require("./Copyright.sol");
var hashToTest = "";

contract("Copyright!", function (accounts) {
  it("should return one right after you register", async function() {
    let c = await Copyright.deployed();
    await c.userRegister();
    // let count = await c.checkUsersCount.call();
    // console.log("Count = " + count);
    let amIRegistered = await c.amIRegistered.call();
    assert.equal(amIRegistered, true);
  });

  it("should return right price after registered", async function () {
    const contract = await Copyright.deployed();

    let songName = "hello world";
    let price = 1000;
    // function registerCopyright(string name, uint price, address[] holders, uint[] shares) public {
    let holders = [accounts[0], accounts[1], accounts[2]];
    let shares = [50, 30, 20];
    // let hash = await contract.songHash.call(songName, price, holders, shares);
    // // console.log(hash);
    let fileInfo = "song_url password";
    let hash;
    // hash = await contract.getSongHash(songName, price, holders, shares);
    // console.log("hash get: " + hash);
    let status = await contract.registerCopyright(songName, fileInfo, price, holders, shares);

    for (let e of status.logs) {
      if (e.event == "registerEvent") {
        hash = e.args.songID
        console.log("Hash: " + hash);

        hashToTest = hash;
      }
    }

    let ret_url = await contract.getDownloadInfo.call(hash);
    console.log("return url: " + ret_url);

    let result = await contract.checkSongPrice.call(hash);
    console.log("the price get: " + result);
    assert.equal(price, result);
  });

  it("should return fileInfo after purchase", async function () {
    const contract = await Copyright.deployed();
    let songID = hashToTest; //"0xeddd58b700b6959725c4a149795b43e01db13b369d7c56d8656fdf21af99e577";
    console.log("songID: " + songID)
    let price = 1000;
    let status = await contract.buyLicense(songID, {value: price});

    for (let e of status.logs) {
      if (e.event == "licenseEvent") {
        hash = e.args.songID
        console.log("Purchased song: " + hash);
      }
    }

    let ret_val = await contract.getDownloadInfo.call(songID);
    console.log("return url: " + ret_val);
    
    let fileInfo = "song_url password";
    assert.equal(ret_val, fileInfo);
  });

  it("should return 0 for registered songs", async function () {
    const contract = await Copyright.deployed();

    let result = await contract.checkSongPrice.call("not registered fake song hehehe");
    console.log(result);
    assert.equal(result, 0);
  });


});
