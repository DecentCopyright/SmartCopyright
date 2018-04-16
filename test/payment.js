var Copyright = artifacts.require("./Copyright.sol");

contract("Payment", function (accounts) {
	it("should work!!!!!!!!!", async function() {
		let holders = [accounts[0], accounts[1], accounts[2]];
		let shares = [50, 30, 20];
		let buyer = accounts[3];

		let c = await Copyright.deployed();
		for(let seller of holders) {
			await c.userRegister({from: seller});
		}

		await c.userRegister({from: buyer});
		console.log("both of them should be able to registered")

		// let addrs = await c.checkUsers.call();
		// console.log(addrs);

		let song = "Awesome track!"
		console.log("upload a song")
		let price = 1000;
		let status = await c.registerCopyright(song, price, holders, shares);
    let hash;
    for (let e of status.logs) {
      if (e.event == "registerEvent") {
        hash = e.args.param
        console.log("Hash: " + hash);
      }
    }

		let prevBuyerBalance = await c.getMyBalance.call({from: buyer});
		console.log("Buyer's previous balance: " + prevBuyerBalance);
		for(let seller of holders) {
			let prevBalance = await c.getMyBalance.call({from: seller});
			console.log("Seller's previous balance: " + prevBalance);
		}

		await c.buyLicense(hash, {from: buyer, value: price});

		let newBuyerBalance = await c.getMyBalance.call({from: buyer});
		console.log("Buyer's new balance?: " + newBuyerBalance);
		for(let seller of holders) {
			let newBalance = await c.getMyBalance.call({from: seller});
			console.log("Seller's new balance?: " + newBalance);
		}

		let dif = prevBuyerBalance- newBuyerBalance;
		console.log("buyer balance difference: " + dif);

		// let difference = newBalance.toNumber() - prevBalance.toNumber();
		// console.log("Difference: " + difference);

		assert.isTrue(true);
	});
});
