//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;


import "./ERC721A/ERC721A.sol";
import "./ERC721A/extensions/ERC721AQueryable.sol";

contract Host is ERC721A, ERC721AQueryable {

  string[] private background = ["Black","Whtie","Rainbow", "Red", "Green"];

  constructor() ERC721A("HOST", "HOS") {}


  function mint() public {
    _mint(msg.sender, 1);
  }

  function _randomTrait(uint256 _tokenId) internal pure returns(uint256) {
    uint256 rand = uint256((keccak256(abi.encodePacked(toString(_tokenId) , "random it for me please"))));
    uint256 mod = rand % 4;
    return mod;
  }

  function tokenURI(uint256 _tokenId) public view override(ERC721A, IERC721A) returns(string memory) {
    uint256 trait = _randomTrait(_tokenId);
    string memory bg = background[trait];
    return string(abi.encodePacked('{"name": "Oppabear Gen 1", "description": "Bear Bear", "image": "https://unsplash.com/photos/AI6fP9IBOYk", "edition": "',toString(_tokenId),'", "attributes": [{"trait_type": "BG", "value": "',bg,'" }]}'));
  }

  function toString(uint256 value) internal pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT license
    // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
  }
}