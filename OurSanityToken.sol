// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract OurSanityToken is ERC20, ERC20Burnable, AccessControl, ChainlinkClient {
    using Chainlink for Chainlink.Request;
    using Strings for uint160;
    bytes32 public constant WHITELISTED_ROLE = keccak256("WHITELISTED");
    struct UserStatus{
        bool isVerified;
        bool qualified;
    }
    mapping(address => UserStatus) public users;

    address private _oracle;
    bytes32 private _jobId;
    uint256 private _fee;

    event ReqFulfilled(
        address indexed _walletAddress,
        bool indexed _isVerified,
        bool indexed _qualified
    );

    constructor() ERC20("OurSanityToken", "OST") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(WHITELISTED_ROLE, msg.sender);
        
        setPublicChainlinkToken();
        _oracle = 0x51CE786075cBe0Dc21869Cc4273Cb98720436aA7;
        _jobId = "efde17c8f1744470b08434d147b5af7e";
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
        request.add("wallet", Strings.toHexString(uint160(msg.sender), 20));
        requestId = sendChainlinkRequestTo(_oracle, request, _fee);
    }

    function fulfill(bytes32 _requestId, bytes memory _walletAddress, bool _isVerified, bool _qualified)
    public
    recordChainlinkFulfillment(_requestId) {
        address addr = bytesToAddress(_walletAddress);
        users[addr].isVerified = _isVerified;
        users[addr].qualified = _qualified;

        emit ReqFulfilled(addr, _isVerified, _qualified);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);
        require(hasRole(WHITELISTED_ROLE, msg.sender) || (users[msg.sender].isVerified && users[msg.sender].qualified), "User not permitted");
    }

    function bytesToAddress(bytes memory _addr) private pure returns(address addr) {
        assembly {
        addr := mload(add(_addr, 20))
    }
    }
    
}