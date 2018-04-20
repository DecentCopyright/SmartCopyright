pragma solidity ^0.4.21;
// pragma experimental ABIEncoderV2;

contract Copyright {
  Song[] public songs;

  mapping(bytes32 => Song) songInfo;
  mapping(address => UserStatus) userInfo;

  event registerEvent(bytes32 songID);
  event licenseEvent(bytes32 songID, address authorized);

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
    bytes32 name;
    bytes32 fileURL1;
    bytes32 fileURL2;
    bytes32 key;
    uint price;
    ShareHolder[] shareHolders;
    address[] licenseHoldersList;
    mapping(address => bool) licenseHolders;
  }


  // -------------- User registration

  //TODO: check duplicate
  function userRegister() public {
    userInfo[msg.sender].registered = true;
  }

  function checkUserExists(address user) public constant returns (bool) {
    return userInfo[user].registered;
  }

  function amIRegistered() public constant returns (bool) {
    return checkUserExists(msg.sender);
  }

  function getMyBalance() public constant returns (uint) {
    return msg.sender.balance;
  }



  // -------------- Upload

  function registerCopyright(bytes32 name, bytes32 URL1, bytes32 URL2, bytes32 password, uint price, address[] holders, uint[] shares) public {
    require(checkUserExists(msg.sender));
    require(shares.length == holders.length);
    require(checkShareSum(shares));

    // TODO: check if ID is unique

    bytes32 songID = keccak256(name, URL1, songs.length);
    songInfo[songID].registered = true;
    songInfo[songID].ID = songID;
    songInfo[songID].name = name;
    songInfo[songID].price = price;
    songInfo[songID].fileURL1 = URL1;
    songInfo[songID].fileURL2 = URL2;
    songInfo[songID].key = password;

    // TODO:
    // Add this song to every shareholder's userInfo?
    userInfo[msg.sender].uploadedList.push(songID);

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

  function checkShareSum(uint[] list) internal pure returns (bool) {
    uint sum = 0;
    for(uint i = 0; i < list.length; i++) {
      sum += list[i];
    }
    return (sum == 100);
  }



  // -------------- Purchase

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
    userInfo[msg.sender].purchasedList.push(songID);

    songInfo[songID].licenseHolders[msg.sender] = true;
    songInfo[songID].licenseHoldersList.push(msg.sender);
    // pay the coopyright holder
    payRoyalty(songID, msg.value);

    emit licenseEvent(songID, msg.sender);
  }

  function payRoyalty(bytes32 songID, uint amount) private {
    ShareHolder[] storage holders = songInfo[songID].shareHolders;
    for(uint i = 0; i < holders.length; i++) {
      ShareHolder storage holder = holders[i];
      holder.addr.transfer(amount * holder.share / 100);
    }
  }



  // -------------- Download

  function getFileInfo(bytes32 songID) public constant returns (bytes32[3]) {
    require(canDownload(msg.sender, songID));
    return [songInfo[songID].fileURL1, songInfo[songID].fileURL2, songInfo[songID].key];
  }

  function canDownload(address user, bytes32 songID) public constant returns (bool) {
    return (checkPurchased(user, songID) || checkUploaded(user, songID));
  }

  function checkPurchased(address user, bytes32 songID) public constant returns (bool) {
    return songInfo[songID].licenseHolders[user];
  }

  function checkUploaded(address user, bytes32 songID) public constant returns (bool) {
    ShareHolder[] storage holders = songInfo[songID].shareHolders;
    for(uint i = 0; i < holders.length; i++) {
      if (holders[i].addr == user) {
        return true;
      }
    }
    return false;
  }



  // -------------- Query song list

  function getSongInfo(bytes32 songID) public constant returns (bytes32[2]) {
    Song storage song = songInfo[songID];
    return [song.name, bytes32(song.price)];
  }

  function getSongList(uint from, uint count, bool reverse) public constant returns (bytes32[]) {
    uint lastIndex = songs.length-1;
    if (from+count > lastIndex) {
      count = lastIndex-from;
    }

    bytes32[] memory response = new bytes32[](count * 3);
    for (uint i = from; i < from+count; i++) {
      uint index = !reverse ? i : lastIndex-i;
      if (index > lastIndex || index < 0) {
        break;
      }
      Song storage song = songs[index];
      response[3*i + 0] = song.ID;
      response[3*i + 1] = song.name;
      response[3*i + 2] = bytes32(song.price);
    }

    return response;
  }

  function prepareSongList(bytes32[] songList) internal view returns (bytes32[]) {
    uint count = songList.length;
    bytes32[] memory response = new bytes32[](count * 2);
    for (uint i = 0; i < count; i++) {
      bytes32 songID = songList[i];
      Song storage song = songInfo[songID];
      response[2*i + 0] = song.ID;
      response[2*i + 1] = song.name;
    }
    return response;
  }

  function getMyPurchasedSongs() public constant returns (bytes32[]) {
    require(checkUserExists(msg.sender));
    return prepareSongList(userInfo[msg.sender].purchasedList);
  }

  function getMyUploadedSongs() public constant returns (bytes32[]) {
    require(checkUserExists(msg.sender));
    return prepareSongList(userInfo[msg.sender].uploadedList);
  }
}
