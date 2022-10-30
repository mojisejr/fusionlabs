//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;


import "./ERC721A/ERC721A.sol";
import "./ERC721A/extensions/ERC721AQueryable.sol";

contract Host is ERC721A, ERC721AQueryable {
  constructor() ERC721A("HOST", "HOS") {}
}