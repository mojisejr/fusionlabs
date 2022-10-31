//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;


import "./ERC721A/ERC721A.sol";
import "./ERC721A/extensions/ERC721AQueryable.sol";
import "./IResult.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Mutant is ERC721A, ERC721AQueryable, Ownable {  
  address labs;

  event Minted(address _to, uint256 tokenId);
  constructor(address _labs) ERC721A("MUTANT", "MUT") {
    labs = _labs;
  }

  function mint(address _to) public {
    require(labs == msg.sender, 'result of fusion must be come from labs.');
    uint256 currentId = _nextTokenId() - 1; 
    _mint(_to, 1);
    emit Minted(_to, currentId);
  }
}