var Copyright = artifacts.require("./Copyright.sol");

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
    let status = await contract.registerCopyright(songName, price, holders, shares);
    let hash;
    for (let e of status.logs) {
      if (e.event == "registerEvent") {
        hash = e.args.param
        console.log("Hash: " + hash);
      }
    }

    let result = await contract.checkSongPrice.call(hash);
    console.log("the price get: " + result);
    assert.equal(price, result);
  });

  it("should return 0 for registered songs", async function () {
    const contract = await Copyright.deployed();

    let result = await contract.checkSongPrice.call("not registered fake song hehehe");
    console.log(result);
    assert.equal(result, 0);
  });


});
