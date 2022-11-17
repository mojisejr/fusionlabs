//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;


import "./ERC721A/ERC721A.sol";
import "./ERC721A/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Mutant is ERC721A, ERC721AQueryable, Ownable {  

  address labs;
  uint256 max_supply;

  mapping(uint256 => string) baseURI;
  mapping(uint256 => bool) completed;
  uint256 requestCounter = 0;
  


  event Minted(address _to, uint256 _tokenId);
  event SetBaseURI(uint256 _tokenId, string _baseURI);
  event RequestBaseURI(uint256 _tokenId);

  constructor(address _labs) ERC721A("MUTANT", "MUT") {
    labs = _labs;
  }

  function mint(address _to) public {
    require(labs == msg.sender, 'result of fusion must be come from labs.');
    uint256 currentId = _nextTokenId() - 1; 
    _mint(_to, 1);
    emit Minted(_to, currentId);
  }

  function setBaseURI(uint256 _tokenId, string memory _baseURI) public {
    require(msg.sender == labs, 'invalid minted');
    require(!completed[_tokenId], 'uri has been set');
    completed[_tokenId] = true;
    baseURI[_tokenId] = _baseURI;
    emit SetBaseURI(_tokenId, _baseURI);
  }

  function tokenURI(uint256 _tokenId) public view override(ERC721A, IERC721A) returns(string memory) {
    require(completed[_tokenId], 'token uri not completed');
    return baseURI[_tokenId];      
  }

  function requestBaseURI(uint256 _tokenId) public {
    require(ownerOf(_tokenId) == msg.sender, 'only token owner');
    require(!completed[_tokenId], 'uri has already been set');
    ++requestCounter;
    emit RequestBaseURI(_tokenId);
  }
}