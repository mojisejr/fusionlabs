//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;


import "./ERC721A/ERC721A.sol";
import "./ERC721A/extensions/ERC721AQueryable.sol";

contract Stimulus is ERC721A, ERC721AQueryable {
  string[] private  types = ["A", "B", "C", "D", "E"];

  constructor() ERC721A("STIMULUS", "STI") {}

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
    string memory traits = types[trait];
    return string(abi.encodePacked('{"name": "Oppabear Serum", "description": "T-Virus", "image": "https://nftstorage.link/ipfs/bafybeia3oin4zv4lzunjdqi7uzlkfifkx4qf7uoxriegvr2iugrkou6tji", "edition": "',toString(_tokenId),'", "attributes": [{"trait_type": "TYPES", "value": "',traits,'" }]}'));
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

