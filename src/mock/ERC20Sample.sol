// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "../../lib/openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "../../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "../../lib/openzeppelin-contracts/contracts/utils/Strings.sol";

contract ERC721Sample is ERC721Enumerable, Ownable {
    using Strings for uint256;

    mapping(uint => string) internal _baseUri;

    constructor() ERC721("ERC721-MOCK", "EM") Ownable(msg.sender){}

    function mintBatch(
        address to,
        uint256 amount,
        string calldata baseUri
    ) public onlyOwner {
        uint256 id = totalSupply() + 1;
        for (uint i = 0; i < amount; i++) {
            _safeMint(to, id);
            _baseUri[id] = baseUri;
            id = id + 1;
        }
    }

    function mint(address to, string calldata baseUri) public {
        uint id = totalSupply() + 1;
        _safeMint(to, id);
        _baseUri[id] = baseUri;
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        return
        string(
            abi.encodePacked(_baseUri[tokenId], tokenId.toString(), ".json")
        );
    }
}
