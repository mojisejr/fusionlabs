//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IFusionLabs  {
  function isFusionable(uint256 _hostTokenId, uint256 _stimulusTokenId) external view returns(bool);
  function ownerOf(uint256 _hostTokenId, uint256 _stimulusTokenId, address _owner) external view returns(bool);
}