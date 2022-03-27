import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./AdminRoles.sol";
pragma solidity ^0.8.4;

contract Egg is ERC721, Ownable, AdminRoles {
    string BaseTokenURI;
    using Strings for uint256;
    mapping(uint256 => uint256) creationTime;

    constructor(
        string memory uri,
        string memory name,
        string memory symbol
    ) ERC721(name, symbol) {
        BaseTokenURI = uri;
    }

    function createURI(uint256 egg) internal view returns (string memory) {
        return string(abi.encodePacked(BaseTokenURI, egg.toString()));
    }

    function tokenURI(uint256 egg)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return createURI(egg);
    }

    function mint(address to, uint256 id) public onlyMinter {
        creationTime[id] = block.timestamp;
        _mint(to, id);
    }

    function setBaseURI(string memory uri) public onlyOwner {
        BaseTokenURI = uri;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}