pragma solidity ^0.4.4;

contract Copyright {
  Song[] public songs;
  // address[] public users;
  // assume one song only has one copyright holder for now
  mapping(bytes32 => Song) songInfo;
  mapping(address => UserStatus) userInfo;
  // mapping(uint => uint) priceInfo;
  // mapping(uint => address[]) authorization;
  // mapping(address => Song[]) purchasedSongs;
  // mapping(address => Song[]) uploadedSongs;

  event registerEvent(bytes32 param);

  struct ShareHolder {
    address addr;
    uint share;
  }

  struct UserStatus {
    bool registered;
    bytes32[] purchasedSongs;
    bytes32[] uploadedSongs;
  }

  struct Song {
    bytes32 ID;
    string name;
    ShareHolder[] shareHolders;
    uint price;
    address[] licenseHolders;
  }

  //TODO: check duplicate
  function userRegister() public {
    // users.push(msg.sender);
    userInfo[msg.sender].registered = true;
  }

  /* function songHash(string name, uint price, address[] holders, uint[] shares) public returns (bytes32) {
    return keccak256(name, price, holders);
  } */

  function registerCopyright(string name, uint price, address[] holders, uint[] shares) public {
    require(checkUserExists(msg.sender));
    require(shares.length == holders.length);
    require(checkShareSum(shares));
    // songs.push(song);
    // priceInfo[song] = price;
    // holderInfo[song].add = msg.sender;
    // holderInfo[song].share = 1;
    bytes32 songID = keccak256(name, price, holders);
    // TODO: check if ID is unique
    songInfo[songID].name = name;
    songInfo[songID].price = price;
    require(songInfo[songID].shareHolders.length == 0);   // If we're registering the song for the first time, this should be an empty array
    for(uint i = 0; i < shares.length; i++) {
      ShareHolder memory holder = ShareHolder({ addr: holders[i], share: shares[i]});
      songInfo[songID].shareHolders.push(holder);
    }
    // if it was successful
    emit registerEvent(songID);

    // TODO: Check if song already exists in the array
    songs.push(songInfo[songID]);
  }

  function checkShareSum(uint[] list) public constant returns (bool) {
    uint sum = 0;
    for(uint i = 0; i < list.length; i++) {
      sum += list[i];
    }
    return sum == 100;
  }

  function checkUserExists(address user) public constant returns (bool) {
    return userInfo[user].registered;
  }

  function amIRegistered() public constant returns (bool) {
    return checkUserExists(msg.sender);
  }

  function checkSongPrice(bytes32 songID) public constant returns (uint) {
    return songInfo[songID].price;
  }

  function buyLicense(bytes32 songID) public payable {
  	require(checkUserExists(msg.sender));
  	uint price = songInfo[songID].price;
  	// Check that the amount paid is >= the price
  	// the ether is paid to the smart contract first through payable function
  	require(msg.value >= price);
  	// authorization[song].push(msg.sender);
  	// pay the coopyright holder
    userInfo[msg.sender].purchasedSongs.push(songID);
    songInfo[songID].licenseHolders.push(msg.sender);
  	payRoyalty(songID, msg.value);
  }

  function payRoyalty(bytes32 songID, uint amount) private {
    ShareHolder[] holders = songInfo[songID].shareHolders;
    for(uint i = 0; i < holders.length; i++) {
      ShareHolder holder = holders[i];
      holder.addr.transfer(amount * holder.share / 100);
    }
  	// holderInfo[song].add.transfer(amount);
  }

  function getMyBalance() public constant returns (uint) {
  	return msg.sender.balance;
  }

}
