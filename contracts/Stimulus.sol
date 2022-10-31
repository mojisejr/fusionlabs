//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;


import "./ERC721A/ERC721A.sol";
import "./ERC721A/extensions/ERC721AQueryable.sol";

contract Stimulus is ERC721A, ERC721AQueryable {
  constructor() ERC721A("STIMULUS", "STI") {}

  function mint() public {
    _mint(msg.sender, 1);
  }
}