//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../IResult.sol";

contract FusionLabsV2 is Ownable, IERC721Receiver {

    struct Host {
        address owner;
        bool locked;
        bool used;
    }

    struct Stimulus {
        address owner;
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

    error EmptyList();

    //Modifiers
    modifier onlyHostOwner(uint256 _tokenId) {
        require(host.ownerOf(_tokenId) == msg.sender, "only host owner");
        require(host.getApproved(_tokenId) == address(this), "owner does not approved their host");
        _;
    }
 
    modifier onlyStimulusOwner(uint256 _tokenId) {
        require(stimulus.ownerOf(_tokenId) == msg.sender, "only stimulus owner");
        require(stimulus.getApproved(_tokenId) == address(this), "owner does not approved their stimulus");
        _;
    }

    modifier onlyFusionAble(uint256 _hostTokenId, uint256 _stimulusTokenId) {
        require(!hosts[_hostTokenId].locked, "token does not locked");
        require(!hosts[_hostTokenId].used, "token is already fusioned");
        require(!stimuli[_stimulusTokenId].locked, "token does not locked");
        require(!stimuli[_stimulusTokenId].used, "token is already fusioned");
        require(!fusioned[_hostTokenId], "token is already fusioned");
        _;
    }

    modifier Available() {
        require(totalFusioned < maxLocked, 'reach max supply');
        _;
    }

    //FUSION FUNCTION
    /////////////////** */
    function fusion(uint256 _hostTokenId, uint256 _stimulusTokenId) public payable
        onlyHostOwner(_hostTokenId)
        onlyStimulusOwner(_stimulusTokenId)
        onlyFusionAble(_hostTokenId, _stimulusTokenId)
        Available()
    {
        hosts[_hostTokenId].used = true;
        stimuli[_stimulusTokenId].used = true;
        fusioned[_hostTokenId] = true; 
        pairs[_hostTokenId] = _stimulusTokenId;
        locked[msg.sender].push(_hostTokenId);
        _lockHost(_hostTokenId);
        _lockStimulus(_stimulusTokenId);
        _increaseTotalFusioned();
        _mintTo(msg.sender);
        emit Fusioned(_hostTokenId, _stimulusTokenId);
    }


    //SETTER FUNCTIONS
    //////////////////
    function setHost(IERC721 _host) public onlyOwner {
        host = _host;
    }

    function setStimulus(IERC721 _stimulus) public onlyOwner {
        stimulus = _stimulus;
    }


    //VIEWS FUNCTIONS
    /////////////////

    function isHostLocked(uint256 _tokenId) public view returns(bool) {
        return hosts[_tokenId].locked;
    }

    function isStimulusLocked(uint256 _tokenId) public view returns(bool) {
        return stimuli[_tokenId].locked;
    }
    

    function ownerOf(uint256 _hostTokenId, uint256 _stimulusTokenId, address _owner) public view returns(bool) {
        require(hosts[_hostTokenId].owner == _owner, "not host owner or not it pair.");
        require(stimuli[_stimulusTokenId].owner == _owner, "not stimulus owner or not its pair." );
        return true;
    }

    function getPairOf(uint256 _hostTokenId) public view returns(uint256) {
        return pairs[_hostTokenId];
    }

    function onERC721Received(address operator, address from,  uint256 _tokenId, bytes calldata data) external override returns(bytes4) {
        emit Received(_tokenId, from, data);
        return this.onERC721Received.selector;
    }

    //HELPER FUNCTIONS
    //////////////////

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

    //INTERNAL FUNCTIONS
    ////////////////////

    function _lockHost (uint256 _tokenId) internal {
        host.safeTransferFrom(msg.sender, address(this), _tokenId, "0x00"); 
        hosts[_tokenId].owner = msg.sender;
        hosts[_tokenId].locked = true; 
    }

    function _lockStimulus (uint256 _tokenId) internal {
        stimulus.safeTransferFrom(msg.sender, address(this), _tokenId, "0x00");
        stimuli[_tokenId].owner = msg.sender;
        stimuli[_tokenId].locked = true;
    }

    function _withdrawHost(uint256 _hostTokenId) internal {
        host.safeTransferFrom(address(this), msg.sender, _hostTokenId , "0x00");
    }
    
    function _withdrawStimulus(uint256 _stimulusTokenId) internal {
        stimulus.safeTransferFrom(address(this), msg.sender, _stimulusTokenId , "0x00");
    }

    function _removeCancelLocked(uint256 index, uint256[] storage array) internal {
        for(uint i = index; i < array.length-1;){
            array[i] = array[i+1];      
            unchecked {
                ++i;
            }
        }
        array.pop();
    }

    function _mintTo(address _to) internal {
        result.mint(_to);
    }

    function _increaseTotalFusioned() internal {
        ++totalFusioned;
    }
}