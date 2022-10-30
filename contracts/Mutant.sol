//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;


import "./ERC721A/ERC721A.sol";
import "./ERC721A/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Mutant is ERC721A, ERC721AQueryable, Ownable{ 
  address labs;
  constructor(address _lab) ERC721A("HOST", "HOS") {}

  function mint(address _to) public {
    require(labs == msg.sender, "mutant only come from labs");
    _mint(_to, 1);
  }
}