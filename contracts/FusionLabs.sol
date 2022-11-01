//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IResult.sol";

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
    IResult result;

    mapping(uint256 => Host) hosts;
    mapping(uint256 => Stimulus) stimuli;
    mapping(uint256 => uint256) pairs;
    mapping(uint256 => bool) fusioned;
    mapping(address => uint256[]) locked;

    uint256 totalFusioned;
    uint256 maxLocked;

    event Received(uint256 _tokenId, address _owner, bytes data);
    event Fusioned(uint256 _hostTokenId, uint256 _stimulusTokenId);

    constructor(  
        IERC721 _host,
        IERC721 _stimulus,
        IResult _result,
        uint256 _maxLocked
    ) {
        host = _host;
        stimulus = _stimulus;
        result = _result;
        maxLocked = _maxLocked;
    }

    //Modifiers
    modifier onlyHostOwner(uint256 _tokenId) {
        require(host.ownerOf(_tokenId) == msg.sender, "only host owner");
        require(host.getApproved(_tokenId) == address(this), "owner does not approved their host");
        _;
    }

    modifier onlyLockedHostOwner(uint256 _tokenId) {
        require(hosts[_tokenId].owner == msg.sender, "only host owner");
        _;
    }
    
    modifier onlyStimulusOwner(uint256 _tokenId) {
        require(stimulus.ownerOf(_tokenId) == msg.sender, "only stimulus owner");
        require(stimulus.getApproved(_tokenId) == address(this), "owner does not approved their stimulus");
        _;
    }

    modifier onlyLockedStimulusOwner(uint256 _tokenId) {
        require(stimuli[_tokenId].owner == msg.sender, "only stimulus owner");
        _;
    }

    modifier onlyFusionAble(uint256 _hostTokenId, uint256 _stimulusTokenId) {
        require(hosts[_hostTokenId].locked, "token does not locked");
        require(!hosts[_hostTokenId].used, "token is already fusioned");
        require(stimuli[_stimulusTokenId].locked, "token does not locked");
        require(!stimuli[_stimulusTokenId].used, "token is already fusioned");
        require(!fusioned[_hostTokenId], "token is already fusioned");
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
        pairs[_hostTokenId] = _stimulusTokenId;
        locked[msg.sender].push(_hostTokenId);
        _lockHost(_hostTokenId);
        _lockStimulus(_stimulusTokenId);
    }

    function getFusionablePairs(address _owner) public view returns(string memory) {
        string memory useables;
        uint256[] memory lockedHosts = locked[_owner];
        for(uint256 i; i < lockedHosts.length; ++i) {
            if(hosts[lockedHosts[i]].locked && !hosts[lockedHosts[i]].used) {
                useables = string(abi.encodePacked(useables,'{"host":',toString(lockedHosts[i]),', "stimulus":',toString(pairs[lockedHosts[i]]),'},'));
            }
        }
        useables = substring(useables, 0, bytes(useables).length - 1);
        useables = string(abi.encodePacked('[',useables,']'));
    
        return useables;
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

    function fusion(uint256 _hostTokenId, uint256 _stimulusTokenId) public 
        onlyLockedHostOwner(_hostTokenId)
        onlyLockedStimulusOwner(_stimulusTokenId)
        onlyFusionAble(_hostTokenId, _stimulusTokenId)
    {
        hosts[_hostTokenId].used = true;
        stimuli[_stimulusTokenId].used = true;
        fusioned[_hostTokenId] = true; 
        _mintTo(msg.sender);
        emit Fusioned(_hostTokenId, _stimulusTokenId);
    }

    function getFusionedOf(uint256 _hostTokenId) public view returns(uint256) {
        return pairs[_hostTokenId];
    }

    function _mintTo(address _to) internal {
        result.mint(_to);
    }

    function cancelFusion(uint256 _hostTokenId) public onlyLockedHostOwner(_hostTokenId) cancelAble(_hostTokenId) {
        uint256 stimulusTokenId = pairs[_hostTokenId];
        _withdrawHost(_hostTokenId);
        _withdrawStimulus(stimulusTokenId);
        uint256[] storage lockedHost = locked[msg.sender];
        for(uint256 i = 0; i < lockedHost.length; ++i) {
            if(lockedHost[i] == _hostTokenId) {
                _removeCancelLocked(i, lockedHost);
            }
        }
    }

    function _removeCancelLocked(uint256 index, uint256[] storage array) internal {
        for(uint i = index; i < array.length-1; i++){
            array[i] = array[i+1];      
        }
        array.pop();
    }

    function _withdrawHost(uint256 _hostTokenId) internal {
        host.safeTransferFrom(address(this), msg.sender, _hostTokenId , "0x01");
    }
    
    function _withdrawStimulus(uint256 _stimulusTokenId) internal {
        stimulus.safeTransferFrom(address(this), msg.sender, _stimulusTokenId , "0x02");
    }

    function isHostLocked(uint256 _tokenId) public view returns(bool) {
        return hosts[_tokenId].locked;
    }

    function isStimulusLocked(uint256 _tokenId) public view returns(bool) {
        return stimuli[_tokenId].locked;
    }
    
    function isFusionable(uint256 _hostTokenId, uint256 _stimulusTokenId) public view returns(bool) {
        require(isHostLocked(_hostTokenId), 'not locked yet');
        require(isStimulusLocked(_stimulusTokenId), 'not locked yet');
        require(!hosts[_hostTokenId].used, 'host has been fusioned');
        require(!stimuli[_stimulusTokenId].used, 'stimuli has been fusioned');
        require(!fusioned[_hostTokenId], 'token has been fusion');
        return pairs[_hostTokenId] == _stimulusTokenId;
    }

    function ownerOf(uint256 _hostTokenId, uint256 _stimulusTokenId, address _owner) public view returns(bool) {
        require(hosts[_hostTokenId].owner == _owner, "not host owner or not it pair.");
        require(stimuli[_stimulusTokenId].owner == _owner, "not stimulus owner or not its pair." );
        return true;
    }

    function onERC721Received(address operator, address from,  uint256 _tokenId, bytes calldata data) external override returns(bytes4) {
        emit Received(_tokenId, from, data);
        return this.onERC721Received.selector;
    }

    function toString(uint256 value) internal pure returns (string memory) {
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

    function substring(
        string memory str,
        uint256 startIndex,
        uint256 endIndex
    ) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = strBytes[i];
        }
        return string(result);
    }
}