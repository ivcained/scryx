// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface Morpheus {
    function getFeed(
        uint256 feedID
    )
        external
        view
        returns (
            uint256 value,
            uint256 decimals,
            uint256 timestamp,
            string memory valStr
        );

    function requestFeeds(
        string[] calldata APIendpoint,
        string[] calldata APIendpointPath,
        uint256[] calldata decimals,
        uint256[] calldata bounties
    ) external payable returns (uint256[] memory feeds);

    function supportFeeds(
        uint256[] calldata feedIds,
        uint256[] calldata values
    ) external payable;
}

contract CrosschainLookup {
    Morpheus morpheus = Morpheus(0x0000000000071821e8033345A7Be174647bE0706);
    mapping(address => mapping(address => uint256)) public userBalance;
    mapping(address => mapping(address => uint256)) public userBalanceFeed;
    string public RPC = "https://opt-mainnet.g.alchemy.com/v2/s0cmMD2L366SRYy2sWKJDuEf_3lXOqSh";
    address public owner;

    constructor() payable {
        owner = msg.sender;
    }

    function getBalance(address target, address TOKEN) public payable {
        string[] memory apiEndpoint = new string[](1);
        apiEndpoint[0] = "XCHAIN";

        // ABI encode the balanceOf function and the address
        bytes memory data = abi.encodeWithSignature(
            "balanceOf(address)",
            target
        );

        string[] memory apiEndpointPath = new string[](1);
        apiEndpointPath[0] = string.concat(
            "XDATA?RPC=",
            RPC,
            "&ADDRS=",
            bytesToHexString(addressToBytes(TOKEN)),
            "&DATA=",
            bytesToHexString(data),
            "&FLAG=0"
        );

        uint256[] memory decimals = new uint256[](1);
        decimals[0] = 0;

        uint256[] memory bounties = new uint256[](1);
        bounties[0] = .001 ether; // Replace with actual bounty value

        uint256[] memory feeds = morpheus.requestFeeds{value: .01 ether}(
            apiEndpoint,
            apiEndpointPath,
            decimals,
            bounties
        );
        userBalanceFeed[target][TOKEN] = feeds[0]; // Storing the feed ID here, to be decoded in setMyBalance
    }

    function addressToBytes(
        address _address
    ) public pure returns (bytes memory) {
        bytes20 addressBytes = bytes20(_address);
        bytes memory result = new bytes(20);
        for (uint i = 0; i < 20; i++) {
            result[i] = addressBytes[i];
        }
        return result;
    }

    function bytesToHexString(
        bytes memory data
    ) public pure returns (string memory) {
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint i = 0; i < data.length; i++) {
            str[2 + i * 2] = alphabet[uint(uint8(data[i] >> 4))];
            str[3 + i * 2] = alphabet[uint(uint8(data[i] & 0x0f))];
        }
        return string(str);
    }

    function setBalance(address target, address token) public {
        (uint256 balance, uint256 timestamp,, ) = morpheus.getFeed(
            userBalanceFeed[target][token]
        );
       require(timestamp >= block.timestamp - 10000, "Data is too old");
        userBalance[target][token] = balance;
    }
}