pragma solidity ^0.4.4;

contract Copyright {
  Song[] public songs;
  // address[] public users;
  // assume one song only has one copyright holder for now
  mapping(bytes32 => Song) songInfo;
  mapping(address => UserStatus) userInfo;

  event registerEvent(bytes32 param);
  event licenseEvent(bytes32 song, address authorized);
  // event downloadEvent(bytes32 songID, string downloadInfo);

  struct ShareHolder {
    address addr;
    uint share;
  }

  struct UserStatus {
    bool registered;
    mapping(bytes32 => uint) purchasedSongs;
    mapping(bytes32 => uint) uploadedSongs;
  }

  struct Song {
    bool registered;
    bytes32 ID;
    string downloadInfo;
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

  function getSongHash(string name, uint price, address[] holders, uint[] shares) public returns (bytes32) {
    bytes32 hashed = keccak256(name, price, holders, shares);
    /* bytes memory bytesArray = new bytes(32);
    for (uint256 i; i < 32; i++) {
        bytesArray[i] = hashed[i];
    }
    return string(bytesArray); */
    return hashed;
  }

  function registerCopyright(string name, string downloadInfo, uint price, address[] holders, uint[] shares) public {
    require(checkUserExists(msg.sender));
    require(shares.length == holders.length);
    require(checkShareSum(shares));

    bytes32 songID = keccak256(name, price, holders);
    // TODO: check if ID is unique
    songInfo[songID].registered = true;
    songInfo[songID].ID = songID;
    songInfo[songID].name = name;
    songInfo[songID].price = price;
    songInfo[songID].downloadInfo = downloadInfo;
    userInfo[msg.sender].uploadedSongs[songID] = 1;
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

  function getDownloadInfo(bytes32 songID) public constant returns (string) {
    require(canDownload(msg.sender, songID));
    // emit downloadEvent(songID, songInfo[songID].downloadInfo);
    return songInfo[songID].downloadInfo;
  }

  function canDownload(address user, bytes32 songID) public returns (bool) {
    if(userInfo[user].uploadedSongs[songID] == 1 ||
      userInfo[user].purchasedSongs[songID] == 1) {
        return true;
      }
      return false;
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

  function checkSongExists(bytes32 songID) public constant returns (bool) {
    return songInfo[songID].registered;
  }

  function checkSongPrice(bytes32 songID) public constant returns (uint) {
    return songInfo[songID].price;
  }

  function buyLicense(bytes32 songID) public payable {
  	require(checkUserExists(msg.sender));
    require(checkSongExists(songID));

  	uint price = songInfo[songID].price;
  	// Check that the amount paid is >= the price
  	// the ether is paid to the smart contract first through payable function
  	require(msg.value >= price);
    userInfo[msg.sender].purchasedSongs[songID] = 1;
    songInfo[songID].licenseHolders.push(msg.sender);
    // pay the coopyright holder
  	payRoyalty(songID, msg.value);

    emit licenseEvent(songID, msg.sender);
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
