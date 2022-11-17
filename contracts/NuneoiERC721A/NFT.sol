//SPDX-License-Identifier: Unlicense
//Cloned Contract From Oppabear Pixel ART of "Apetimism Launch Pad" with some special changes.
//THANK YOU TO  Apetimism Project for this cool contract.

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; 
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "./ERC721AQueryable.sol";

interface IERC20 {
  function balanceOf(address account) external view returns (uint256);
  function transfer(address _to, uint256 _amount) external returns (bool);
}

interface IWhitelist {
  function isWhitelist(address addr) external view returns (int8);
}

contract OppaBearMutantNFT is ERC721AQueryable, ERC2981, Ownable, Pausable, ReentrancyGuard {
  event Received(address, uint);
  event RoundChanged(uint8);
  event TotalMintedChanged(uint256);

  //////////////
  // Constants
  //////////////

  uint256 public MAX_SUPPLY = 2000;
  uint256 public RESERVED_NFT_COUNT = 0;
  uint256 public TEAM_NFT_COUNT = 229;
  uint256 public START_TOKEN_ID = 1;

  //////////////
  // Internal
  //////////////

  string private _baseURIExtended;
  bool private _isReservedNFTsMinted = false;
  bool private _isTeamNFTsMinted = false;

  address private _signer;

  mapping(address => uint256) private _addressTokenMinted;

  mapping(uint256 => uint8) private _nonces;

  /////////////////////
  // Public Variables
  /////////////////////

  uint8 public currentRound = 0;
  address public teamAddress;
  address public whitelisterAddress;
  bool public metadataFrozen = false;
  uint8 public maxMintPerTx = 10;
  uint16 public maxMintPerAddress = 4;

  mapping(int16 => uint256) mintPriceByRole;

  struct Role {
    string name;
    int16 role_id;
    uint256 max_mint;
    uint256 mint_price;
    bool exists;
  }
  mapping(uint8 => mapping(int16 => Role)) public allowedRolesInRound;
  mapping(uint8 => uint16) public allowedRolesInRoundCount;
  mapping(uint8 => int16[]) public allowedRolesInRoundArr;
  uint8[] public availableRounds;
  mapping(uint8 => uint256) public roundAllocations;
  mapping(uint8 => uint256) public totalMintedInRound;

  ////////////////
  // Actual Code
  ////////////////

  constructor() ERC721A("Oppabear Mutant", "Oppabear Mutant") {
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return START_TOKEN_ID;
  }

  //////////////////////
  // Setters for Owner
  //////////////////////

  function setCurrentRound(uint8 round_) public onlyOwner {
    currentRound = round_;
    emit RoundChanged(round_);
  }

  function setTeamAddress(address addr) public onlyOwner {
    teamAddress = addr;
  }

  function setWhitelisterAddress(address addr) public onlyOwner {
    whitelisterAddress = addr;
  }

  function setSignerAddress(address addr) public onlyOwner {
    _signer = addr;
  }

  function setMaxMintPerTx(uint8 count) public onlyOwner {
    maxMintPerTx = count;
  }

  function setMaxMintPerAddress(uint16 count) public onlyOwner {
    maxMintPerAddress = count;
  }

  function setBaseURI(string memory baseURI) external onlyOwner {
    require(!metadataFrozen, "Metadata has already been frozen");
    _baseURIExtended = baseURI;
  }

  function addAllowedRoleInRound(uint8 round, int16 role, string memory roleName, uint256 maxMint, uint256 mintPrice) public onlyOwner {
    bool role_already_existed = allowedRolesInRound[round][role].exists;
    allowedRolesInRound[round][role].name = roleName;
    allowedRolesInRound[round][role].role_id = role;
    allowedRolesInRound[round][role].max_mint = maxMint;
    allowedRolesInRound[round][role].mint_price = mintPrice;
    allowedRolesInRound[round][role].exists = true;
    if (role_already_existed)
      return;
    allowedRolesInRoundCount[round]++;

    allowedRolesInRoundArr[round].push(role);

    bool found = false;
    for (uint8 i = 0; i < availableRounds.length; i++)
      if (availableRounds[i] == round)
        found = true;

    if (!found)
      availableRounds.push(round);
  }

  function removeAllowedRoleInRound(uint8 round, int16 role) public onlyOwner {
    require(allowedRolesInRound[round][role].exists, "Role not existed");
    allowedRolesInRound[round][role].name = "";
    allowedRolesInRound[round][role].role_id = 0;
    allowedRolesInRound[round][role].max_mint = 0;
    allowedRolesInRound[round][role].mint_price = 0;
    allowedRolesInRound[round][role].exists = false;
    allowedRolesInRoundCount[round]--;

    // Remove available role
    for (uint8 i = 0; i < allowedRolesInRoundArr[round].length; i++) {
      if (allowedRolesInRoundArr[round][i] == role) {
        removeArrayAtInt16Index(allowedRolesInRoundArr[round], i);
        break;
      }
    }

    if (allowedRolesInRoundCount[round] == 0) {
      // Remove available round
      for (uint8 i = 0; i < availableRounds.length; i++) {
        if (availableRounds[i] == round) {
          removeArrayAtUint8Index(availableRounds, i);
          break;
        }
      }
    }
  }

  function setRoundAllocation(uint8 round, uint256 allocation) public onlyOwner {
    roundAllocations[round] = allocation;
  }

  function freezeMetadata() public onlyOwner {
    metadataFrozen = true;
  }
  
  ////////////
  // Minting
  ////////////

  function mintReservedNFTs() public onlyOwner {
    require(teamAddress != address(0), "Team wallet is not yet set");
    require(whitelisterAddress != address(0), "Whitelister address is not yet set");
    require(!_isReservedNFTsMinted, "Already minted");

    string memory baseURI = _baseURI();
    require(bytes(baseURI).length != 0, "baseURI is not yet set");

    if (RESERVED_NFT_COUNT > 0)
      _safeMint(owner(), RESERVED_NFT_COUNT);

    _isReservedNFTsMinted = true;

    emit TotalMintedChanged(totalMinted());
  }

  function mintTeamNFTs() public onlyOwner {
    require(teamAddress != address(0), "Team wallet is not yet set");
    require(whitelisterAddress != address(0), "Whitelister address is not yet set");
    require(_isReservedNFTsMinted, "Reserved NFTs needs to be minted first");
    require(!_isTeamNFTsMinted, "Already minted");

    string memory baseURI = _baseURI();
    require(bytes(baseURI).length != 0, "baseURI is not yet set");

    if (TEAM_NFT_COUNT > 0)
      _safeMint(teamAddress, TEAM_NFT_COUNT);

    _isTeamNFTsMinted = true;
  }

  function mint(uint256 quantity, int8 role, uint256 nonce, uint8 v, bytes32 r, bytes32 s) external payable whenNotPaused nonReentrant {
    require(currentRound != 0, "Mint is not yet started");

    uint256 combined_nonce = nonce;
    if (role >= 0)
      combined_nonce = (nonce << 8) + uint8(role);

    require(_nonces[combined_nonce] == 0, "Duplicated nonce");
    require(_recoverAddress(combined_nonce, v, r, s) == _signer, "Invalid signature");

    bool is_public_round = allowedRolesInRound[currentRound][0].exists;
    int8 selected_role = IWhitelist(whitelisterAddress).isWhitelist(msg.sender);
    if (role >= 0)
      selected_role = role;

    if (!allowedRolesInRound[currentRound][selected_role].exists) {
      if (!is_public_round)
        require(false, "You are not eligible to mint in this round");
      selected_role = 0;
    }

    require(_isReservedNFTsMinted && _isTeamNFTsMinted, "Contract is not ready for public mint yet");
    require(quantity > 0, "Quantity cannot be zero");
    if (role >= 0)
      require(maxMintableForTxForRole(msg.sender, role) >= quantity, "You have reached maximum allowed");
    else
      require(maxMintableForTx(msg.sender) >= quantity, "You have reached maximum allowed");
    require(totalMinted() + quantity <= MAX_SUPPLY, "Cannot mint more than maximum supply");
    require(mintableLeft() >= quantity, "Not enough NFT left to mint.");

    uint256 cost = quantity * allowedRolesInRound[currentRound][selected_role].mint_price;
    _nonces[combined_nonce] = 1;

    require(msg.value == cost, "Unmatched ether balance");

    _safeMint(msg.sender, quantity);

    totalMintedInRound[currentRound] = totalMintedInRound[currentRound] + quantity;

    _addressTokenMinted[msg.sender] = _addressTokenMinted[msg.sender] + quantity;
  }

  function _recoverAddress(uint256 nonce, uint8 v, bytes32 r, bytes32 s) private pure returns (address) {
    bytes32 msgHash = keccak256(abi.encodePacked(nonce));
    bytes32 messageDigest = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", msgHash));
    return ecrecover(messageDigest, v, r, s);
  }

  ////////////////
  // Transfering
  ////////////////

  function transfersFrom(
    address from,
    address to,
    uint256[] calldata tokenIds
  ) public virtual {
    for (uint i = 0; i < tokenIds.length; i++)
      transferFrom(from, to, tokenIds[i]);
  }

  function safeTransfersFrom(
    address from,
    address to,
    uint256[] calldata tokenIds
  ) public virtual {
    for (uint i = 0; i < tokenIds.length; i++)
      safeTransferFrom(from, to, tokenIds[i]);
  }

  function safeTransfersFrom(
    address from,
    address to,
    uint256[] calldata tokenIds,
    bytes memory _data
  ) public virtual {
    for (uint i = 0; i < tokenIds.length; i++)
      safeTransferFrom(from, to, tokenIds[i], _data);
  }

  //////////////
  // Pausable
  //////////////

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  ///////////////////
  // Internal Views
  ///////////////////

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseURIExtended;
  }

  /////////////////
  // Public Views
  /////////////////

  function getAllAvailableRounds() public onlyOwner() view returns (uint8[] memory) {
    uint256 len = availableRounds.length;
    uint8[] memory ret = new uint8[](len);
    for (uint i = 0; i < len; i++)
      ret[i] = availableRounds[i];
    return ret;
  }

  function getAllowedRolesInRoundArr(uint8 round) public onlyOwner() view returns (int16[] memory) {
    uint256 len = allowedRolesInRoundArr[round].length;
    int16[] memory ret = new int16[](len);
    for (uint i = 0; i < len; i++)
      ret[i] = allowedRolesInRoundArr[round][i];
    return ret;
  }

  function mintPriceForCurrentRound(address addr) public view returns (uint256) {
    int8 selected_role = IWhitelist(whitelisterAddress).isWhitelist(addr);
    return allowedRolesInRound[currentRound][selected_role].mint_price;
  }

  function mintPriceForCurrentRoundForRole(int8 role) public view returns (uint256) {
    return allowedRolesInRound[currentRound][role].mint_price;
  }

  function maxMintable(address addr) public view virtual returns (uint256) {
    int8 selected_role = IWhitelist(whitelisterAddress).isWhitelist(addr);
    return maxMintableForRole(addr, selected_role);
  }

  function maxMintableForRole(address addr, int8 role) public view virtual returns (uint256) {
    uint256 minted = _addressTokenMinted[addr];
    uint256 max_mint = 0;

    // Not yet started
    if (currentRound == 0)
      return 0;
    // Total minted in this round reach the maximum allocated
    if (totalMintedInRound[currentRound] >= roundAllocations[currentRound])
      return 0;

    bool is_public_round = allowedRolesInRound[currentRound][0].exists;
    if (allowedRolesInRound[currentRound][role].exists)
      max_mint = allowedRolesInRound[currentRound][role].max_mint;
    else if (is_public_round)
      max_mint = allowedRolesInRound[currentRound][0].max_mint;

    // Hit the maximum per wallet
    if (minted >= maxMintPerAddress)
      return 0;
    // Cannot mint more for this round
    if (minted >= max_mint)
      return 0;

    uint256 wallet_quota_left = maxMintPerAddress - minted;
    uint256 round_quota_left = max_mint - minted;
    uint256 round_allocation_quota_left = roundAllocations[currentRound] - totalMintedInRound[currentRound];

    return min(min(wallet_quota_left, round_quota_left), round_allocation_quota_left);
  }

  function maxMintableForTx(address addr) public view virtual returns (uint256) {
    uint256 mintable = maxMintable(addr);

    if (mintable > maxMintPerTx)
      return maxMintPerTx;

    return mintable;
  }

  function maxMintableForTxForRole(address addr, int8 role) public view virtual returns (uint256) {
    uint256 mintable = maxMintableForRole(addr, role);

    if (mintable > maxMintPerTx)
      return maxMintPerTx;

    return mintable;
  }

  function tokenURI(uint256 tokenId) public view virtual override(ERC721A, IERC721Metadata) returns (string memory) {
    require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');

    string memory baseURI = _baseURI();
    return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, Strings.toString(tokenId), ".json")) : '';
  }

  function totalMinted() public view returns (uint256) {
    return _totalMinted();
  }

  function mintableLeft() public view returns (uint256) {
    return MAX_SUPPLY - totalMinted();
  }

  ////////////
  // Helpers
  ////////////

  function removeArrayAtInt16Index(int16[] storage array, uint256 index) private {
    for (uint i = index; i < array.length - 1; i++)
      array[i] = array[i + 1];
    delete array[array.length - 1];
    array.pop();
  }

  function removeArrayAtUint8Index(uint8[] storage array, uint256 index) private {
    for (uint i = index; i < array.length - 1; i++)
      array[i] = array[i + 1];
    delete array[array.length - 1];
    array.pop();
  }

  function min(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }

  ////////////
  // ERC2981
  ////////////

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981, IERC165) returns (bool) {
    return super.supportsInterface(interfaceId) || ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
  }

  function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
    _setDefaultRoyalty(receiver, feeNumerator);
  }

  function deleteDefaultRoyalty() public onlyOwner {
    _deleteDefaultRoyalty();
  }

  function setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator) public onlyOwner {
    _setTokenRoyalty(tokenId, receiver, feeNumerator);
  }

  function resetTokenRoyalty(uint256 tokenId) public onlyOwner {
    _resetTokenRoyalty(tokenId);
  }

  ///////////////
  // Withdrawal
  ///////////////

  function withdraw() public onlyOwner {
    uint256 balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }

  function withdrawToken(address tokenAddress) public onlyOwner {
    IERC20 tokenContract = IERC20(tokenAddress);
    tokenContract.transfer(msg.sender, tokenContract.balanceOf(address(this)));
  }

  /////////////
  // Fallback
  /////////////

  receive() external payable {
    emit Received(msg.sender, msg.value);
  }
}