// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {AxelarExecutable} from "axelar-gmp-sdk-solidity/executable/AxelarExecutable.sol";
import {IAxelarGateway} from "axelar-gmp-sdk-solidity/interfaces/IAxelarGateway.sol";
import {IAxelarGasService} from "axelar-gmp-sdk-solidity/interfaces/IAxelarGasService.sol";
import {IERC20} from "axelar-gmp-sdk-solidity/interfaces/IERC20.sol";

contract NFT is ERC721, ERC721URIStorage, Ownable, AxelarExecutable {
    uint256 private _nextTokenId;
    string public value;
    string public sourceChain;
    string public sourceAddress;
    IAxelarGasService public immutable gasService;

    constructor(
        address initialOwner,
        address gateway_,
        address gasReceiver_
    )
        ERC721("Protecc", "PTC")
        Ownable(initialOwner)
        AxelarExecutable(gateway_)
    {
        gasService = IAxelarGasService(gasReceiver_);
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://www.google.com";
    }

    // function safeMint(address to, string memory uri) public onlyOwner {
    //     uint256 tokenId = _nextTokenId++;
    //     _safeMint(to, tokenId);
    //     _setTokenURI(tokenId, uri);
    // }

    // The following functions are overrides required by Solidity.

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setRemoteValue(
        string calldata destinationChain,
        string calldata destinationAddress,
        string calldata value_
    ) external payable {
        require(msg.value > 0, "Gas payment is required");

        bytes memory payload = abi.encode(value_);
        gasService.payNativeGasForContractCall{value: msg.value}(
            address(this),
            destinationChain,
            destinationAddress,
            payload,
            msg.sender
        );
        gateway.callContract(destinationChain, destinationAddress, payload);
    }

    // Handles calls created by setAndSend. Updates this contract's value
    function _execute(
        string calldata sourceChain_,
        string calldata sourceAddress_,
        bytes calldata payload_
    ) internal override {
        (value) = abi.decode(payload_, (string));
        sourceChain = sourceChain_;
        sourceAddress = sourceAddress_;
    }
}
