pragma solidity ^0.4.4;
pragma experimental ABIEncoderV2;

contract Copyright {
  Song[] public songs;
  // address[] public users;
  // assume one song only has one copyright holder for now
  mapping(bytes32 => Song) songInfo;
  mapping(address => UserStatus) userInfo;

  event registerEvent(bytes32 songID);
  event licenseEvent(bytes32 songID, address authorized);
  // event downloadEvent(bytes32 songID, string fileInfo);

  struct ShareHolder {
    address addr;
    uint share;
  }

  struct UserStatus {
    bool registered;
    bytes32[] purchasedList;
    bytes32[] uploadedList;
  }

  struct Song {
    bool registered;
    bytes32 ID;
    bytes32 fileURL;
    bytes32 password; // URL ' ' password
    bytes32 name;
    
    uint price;
    ShareHolder[] shareHolders;
    
    address[] licenseHoldersList;
    mapping(address => bool) licenseHolders;
  }

  //TODO: check duplicate
  function userRegister() public {
    // users.push(msg.sender);
    userInfo[msg.sender].registered = true;
  }

  function registerCopyright(bytes32 songID, string name, string fileInfo, uint price, address[] holders, uint[] shares) public {
    require(checkUserExists(msg.sender));
    require(shares.length == holders.length);
    require(checkShareSum(shares));

    /* bytes32 songID = keccak256(name, price, holders); */
    // TODO: check if ID is unique
    songInfo[songID].registered = true;
    songInfo[songID].ID = songID;
    songInfo[songID].name = name;
    songInfo[songID].price = price;
    songInfo[songID].fileInfo = fileInfo;

    userInfo[msg.sender].uploadedList.push(songID);
    userInfo[msg.sender].uploadedCount += 1;
    
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


  function getfileInfo(bytes32 songID) public constant returns (string) {
    require(canDownload(msg.sender, songID));
    return songInfo[songID].fileInfo;
  }

  function canDownload(address user, bytes32 songID) public returns (bool) {
    return (checkPurchased(user, songID) || checkUploaded(user, songID));
  }

  function checkPurchased(address user, bytes32 songID) public constant returns (bool) {
    return songInfo[songID].licenseHolders[user];
  }

  function checkUploaded(address user, bytes32 songID) public constant returns (bool) {
    for(unit i = 0; i < songInfo[songID].shareHolders.leangh; i++) {
      if (songInfo[songID].shareHolders[i] == user) {
        return true;
      }
    }
    return false;
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

  function buyLicense(bytes32 songID) public payable {
  	require(checkUserExists(msg.sender));
    require(checkSongExists(songID));

  	uint price = songInfo[songID].price;
  	// Check that the amount paid is >= the price
  	// the ether is paid to the smart contract first through payable function
  	require(msg.value >= price);
    userInfo[msg.sender].purchasedSongs[songID] = 1;
    userInfo[msg.sender].purchasedList.push(songID);
    userInfo[msg.sender].purchasedCount += 1;
    songInfo[songID].licenseHoldersList.push(msg.sender);
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

  function getPurchasedSongs() public constant returns (bytes32[]) {
    require(checkUserExists(msg.sender));
    return userInfo[msg.sender].purchasedList;
    /* uint counter = 0;
    uint size = userInfo[msg.sender].purchasedCount;
    string[] memory purchasedSongs = new string[](size);
    bytes32[] memory purchasedSongs = new bytes32[](10);
    string[2] purchasedSongs;
    bytes32 songID;
    for(uint i = 0; i < songs.length; i++) {
      bytes32 songID = songs[i].ID;
      songID = songs[i].ID;
      if (userInfo[msg.sender].purchasedSongs[songID] == 1) {
        purchasedSongs[counter] = bytes32(songs[i].name);
        counter += 1;

        purchasedSongs[counter] = songs[i].ID;
        counter += 1;

        purchasedSongs[counter] = songs[i].ID;
        counter += 1;
      } */
    /* } */
    /* return purchasedSongs; */
    //userInfo[msg.sender].purchasedSongs[songID] == 1;
    /* return true; */
  }
/*
  function getUploadedSongs() public returns (Song[]) {
    require(checkUserExists(msg.sender));
    Song[] uploadedSongs;
    for(uint i = 0; i < songs.length; i++) {
      bytes32 songID = songs[i].ID;
      if (userInfo[msg.sender].uploadedSongs[songID] == 1) {
        uploadedSongs.push(songs[i]);
      }
    }
    return uploadedSongs;
  }

  function getUnpurchasedSongs() public returns (Song[]) {
    require(checkUserExists(msg.sender));
    Song[] unpurchasedSongs;
    for(uint i = 0; i < songs.length; i++) {
      bytes32 songID = songs[i].ID;
      if (userInfo[msg.sender].uploadedSongs[songID] != 1 && userInfo[msg.sender].purchasedSongs[songID] != 1) {
        unpurchasedSongs.push(songs[i]);
      }
    }
    return unpurchasedSongs;
  } */

  function checkShareSum(uint[] list) private constant returns (bool) {
    uint sum = 0;
    for(uint i = 0; i < list.length; i++) {
      sum += list[i];
    }
    return sum == 100;
  }
}
