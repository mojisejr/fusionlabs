//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FusionLabs is Ownable, IERC721Receiver {

    struct Host {
        address owner;
        bool burned;
        bool locked;
        bool used;
    }

    struct Stimulus {
        address owner;
        bool burned;
        bool locked;
        bool used;
    }

    IERC721 host;
    IERC721 stimulus;

    mapping(uint256 => Host) hosts;
    mapping(uint256 => Stimulus) stimuli;
    mapping(uint256 => uint256) fusioned;

    uint256 totalFusioned;
    uint256 maxLocked;

    event Received(uint256 _tokenId, address _owner, bytes data);
    event Fusioned(uint256 _hostTokenId, uint256 _stimulusTokenId);

    constructor(  
        IERC721 _host,
        IERC721 _stimulus,
        uint256 _maxLocked
    ) {
        host = _host;
        stimulus = _stimulus;
        maxLocked = _maxLocked;
    }

    //Modifiers
    modifier onlyHostOwner(uint256 _tokenId) {
        require(host.ownerOf(_tokenId) == msg.sender, "only host owner");
        require(host.getApproved(_tokenId) == msg.sender, "owner does not approved their host");
        _;
    }
    
    modifier onlyStimulusOwner(uint256 _tokenId) {
        require(stimulus.ownerOf(_tokenId) == msg.sender, "only stimulus owner");
        require(stimulus.getApproved(_tokenId) == msg.sender, "owner does not approved their stimulus");
        _;
    }

    modifier onlyFusionAble(uint256 _hostTokenId, uint256 _stimulusTokenId) {
        require(hosts[_hostTokenId].locked, "token does not locked");
        require(!hosts[_hostTokenId].used, "token is already fusioned");
        require(stimuli[_stimulusTokenId].locked, "token does not locked");
        require(!stimuli[_stimulusTokenId].used, "token is already fusioned");
        require(fusioned[_hostTokenId] == _stimulusTokenId, "invalid locked stimulus");
        _;
    }

    modifier cancelAble(uint256 _hostTokenId) {
        require(hosts[_hostTokenId].locked, "token does not locked");
        require(!hosts[_hostTokenId].used, "token is already used");
        _;
    }

    //Locking 
    function lock(uint256 _hostTokenId, uint256 _stimulusTokenId) public 
        onlyHostOwner(_hostTokenId)
        onlyStimulusOwner(_stimulusTokenId)
    { 
        _lockHost(_hostTokenId);
        _lockStimulus(_stimulusTokenId);
    }

    function _lockHost (uint256 _tokenId) internal {
        host.safeTransferFrom(msg.sender, address(this), _tokenId, "0x01"); 
        hosts[_tokenId].owner = msg.sender;
        hosts[_tokenId].locked = true;
    }

    function _lockStimulus (uint256 _tokenId) internal {
        stimulus.safeTransferFrom(msg.sender, address(this), _tokenId, "0x02");
        stimuli[_tokenId].owner = msg.sender;
        stimuli[_tokenId].locked = true;
    }

    //fusion
    function fusion(uint256 _hostTokenId, uint256 _stimulusTokenId) public 
        onlyHostOwner(_hostTokenId)
        onlyStimulusOwner(_stimulusTokenId)
        onlyFusionAble(_hostTokenId, _stimulusTokenId)
    {
        fusioned[_hostTokenId] = _stimulusTokenId; 
        // emit Fusioned(uint256 _hostTokenId, uint256 _stimulusTokenId);
    }

    function cancelFusion(uint256 _hostTokenId) public onlyHostOwner(_hostTokenId) cancelAble(_hostTokenId) {
        uint256 stimulusTokenId = fusioned[_hostTokenId];
        _withdrawHost(_hostTokenId);
        _withdrawStimulus(stimulusTokenId);
    }

    function _withdrawHost(uint256 _hostTokenId) internal {
        host.safeTransferFrom(address(this), msg.sender, _hostTokenId , "0x01");
    }
    
    function _withdrawStimulus(uint256 _stimulusTokenId) internal {
        stimulus.safeTransferFrom(address(this), msg.sender, _stimulusTokenId , "0x02");
    }

    //getter
    function isHostLocked(uint256 _tokenId) public view returns(bool) {
        return hosts[_tokenId].locked;
    }

    function isStimulusLocked(uint256 _tokenId) public view returns(bool) {
        return stimuli[_tokenId].locked;
    }

    function onERC721Received(address operator, address from,  uint256 _tokenId, bytes calldata data) external override returns(bytes4) {
        emit Received(_tokenId, from, data);
        return this.onERC721Received.selector;
    }
}