//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Server is ERC1155URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter public AdIds;
    uint256 nativeTokenId;
    uint256 public nativeTokenPrice;
    address[] public publishers;
    address[] public subscribers;
    uint256[] public Ads;

    struct Ad {
        uint256 id;
        uint256 clickReward;
        uint256 displayReward;
        uint256 totalFunds;
        uint256 currentFunds;
        uint256 clicks;
        address Advertiser;
        bool campaignRunning;
    }

    mapping(uint256 => Ad) IdToAd;
    mapping(uint256 => Ad) IdToCampaign;
    mapping(uint256 => address) AdToPublisher;

    event AdCreated(
        uint256 id,
        uint256 clickReward,
        uint256 displayReward,
        uint256 totalFunds,
        uint256 clicks,
        address Advertiser,
        bool campaignRunning
    );

    event campaignStarted(
        uint256 id,
        uint256 totalFunds,
        string trackingURL,
        address Advertiser,
        bool campaignRunning,
        string imageURL,
        string targetURL,
        uint256 clickReward,
        uint256 displayReward
    );

    event Impression(
        uint256 id,
        uint256 clicks,
        uint256 currentFunds,
        address Advertiser
    );

    constructor() ERC1155("") {
        nativeTokenPrice = 0.000001 ether;
        nativeTokenId = AdIds.current();
    }

    function buyAdTokens() public {
        //this function is used to buy tokens
    }

    function createAd(
        string memory _AdURI,
        uint256 _clickReward,
        uint256 _displayReward,
        uint256 _totalFunds
    ) public returns (uint256) {
        // we will make every ad as an NFT
        //this function mints an NFT
        AdIds.increment();
        uint256 id = AdIds.current();
        _mint(msg.sender, id, 1, "");
        _setURI(id, _AdURI);
        Ads.push(id);
        IdToAd[id] = Ad(
            id,
            _clickReward,
            _displayReward,
            _totalFunds,
            _totalFunds,
            0,
            msg.sender,
            false
        );

        emit AdCreated(
            id,
            _clickReward,
            _displayReward,
            _totalFunds,
            0,
            msg.sender,
            false
        );

        return id;
    }

    function runCampaign(uint256 Id) public {}

    function serveAd() public {
        //this function returns the IPFS link to the NFTAd
    }

    function stopCampaign() public {
        //this function stops the campaign
        //returns the funds to the advertiser
    }

    function addFundsToAd() public {
        //this function adds funds to the Ad
    }

    function SubscribetoPublisher() public {
        //this function adds the publisher to the list of  a particular Ad publishers
    }

    function UnSubscribetoPublisher() public {
        //this function removes the publisher from the list of  a particular Ad publishers
    }

    function getAd() public {
        //this function returns the Ad details
    }

    function getPublishers() public {
        //this function returns the list of publishers
    }

    function getSubscribers() public {
        //this function returns the list of subscribers
    }

    function getCurrentFundsForAd() public {
        //this function returns the current funds for the Ad
    }

    function getRunningCampaigns() public {
        //this function returns the list of running campaigns
    }
}
