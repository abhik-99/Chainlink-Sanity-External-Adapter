// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract OurSanityToken is ERC20, ERC20Burnable, AccessControl, ChainlinkClient {
    using Chainlink for Chainlink.Request;
    bytes32 public constant WHITELISTED_ROLE = keccak256("WHITELISTED");
    struct UserStatus{
        bool isVerified;
        bool qualified;
    }
    mapping(address => UserStatus) public users;

    address private _oracle;
    bytes32 private _jobId;
    uint256 private _fee;

    constructor() ERC20("OurSanityToken", "OST") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(WHITELISTED_ROLE, msg.sender);
        
        setPublicChainlinkToken();
        _oracle = 0xf8b64a4273F13C2521ACC715d3022b8Bd31e1bE8;
        _jobId = "24e32372e58a4ed9baa6e38c59d9cc6a";
        _fee = 0 * LINK_DIVISIBILITY; // (Varies by network and job)
    }

    function mint(address to, uint256 amount)
    public
    onlyRole(DEFAULT_ADMIN_ROLE) {
        _mint(to, amount);
    }

    function whitelistUser(address user)
    public
    onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(WHITELISTED_ROLE, user);
    }

    function getUserVerificationStatus()
    public
    view
    returns (bool, bool) {
        return (
            users[msg.sender].isVerified,
            users[msg.sender].qualified
        );
    }

    function userVerficationQuery()
    public
    returns (bytes32 requestId) {
        Chainlink.Request memory request = buildChainlinkRequest(_jobId, address(this), this.fulfill.selector);
        request.add("wallet", toAsciiString(msg.sender));
        requestId = sendChainlinkRequestTo(_oracle, request, _fee);
    }

    function fulfill(bytes32 _requestId, address _walletAddress, bool _isVerified, bool _qualified)
    public
    recordChainlinkFulfillment(_requestId) {
        users[_walletAddress].isVerified = _isVerified;
        users[_walletAddress].qualified = _qualified;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);
        require(hasRole(WHITELISTED_ROLE, msg.sender) || (users[msg.sender].isVerified && users[msg.sender].qualified), "User not permitted");
    }
    
    function toAsciiString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2*i] = char(hi);
            s[2*i+1] = char(lo);            
        }
        return string(s);
    }
    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }
}