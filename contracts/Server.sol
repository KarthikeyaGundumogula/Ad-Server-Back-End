//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Server is ERC1155URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter public AdIds;
    Counters.Counter public PublisherIds;
    uint256 nativeTokenId;
    uint256 public nativeTokenPrice;
    address[] public publishersList;

    struct Ad {
        uint256 id;
        uint256 clickReward;
        uint256 displayReward;
        uint256 totalFunds;
        uint256 currentFunds;
        uint256 clicks;
        uint256 display;
        address Advertiser;
        address[] publishers;
        bool campaignRunning;
    }

    struct Publisher {
        uint256 id;
        address publisher;
        uint256 clickReward;
        uint256 displayReward;
    }

    mapping(uint256 => Ad) IdToCampaign;
    mapping(uint256 => bool) IsCampaignCreated;
    mapping(uint256 => address) AdToPublisher;
    mapping(address => bool) IsPublisher;
    mapping(uint256 => Publisher) IdToPublisher;
    mapping(uint256 => mapping(address => bool)) IsPublisherAdded;

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
        address Advertiser,
        bool campaignRunning
    );

    event campaignStopped(
        uint256 id,
        uint256 totalFunds,
        address Advertiser,
        bool campaignRunning
    );

    event Impression(
        uint256 id,
        uint256 clicks,
        uint256 currentFunds,
        address Advertiser
    );

    event Click(
        uint256 id,
        uint256 clicks,
        uint256 currentFunds,
        address Advertiser
    );

    event PublisherCreated(
        uint256 id,
        uint256 clickReward,
        uint256 displayReward,
        address publisher
    );

    event AdServed(
        uint256 id,
        uint256 currentFunds,
        address Advertiser,
        address publisher
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
        IdToCampaign[id] = Ad(
            id,
            _clickReward,
            _displayReward,
            _totalFunds,
            _totalFunds,
            0,
            0,
            msg.sender,
            new address[](0),
            false
        );
        IsCampaignCreated[id] = true;

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

    function startCampaign(uint256 Id) public payable {
        //this function starts the campaign
        require(IsCampaignCreated[Id] == true, "Ad is not created");
        require(
            IdToCampaign[Id].Advertiser == msg.sender,
            "You are not the Advertiser"
        );
        require(
            IdToCampaign[Id].campaignRunning == false,
            "Campaign is already running"
        );
        require(
            IdToCampaign[Id].totalFunds <= balanceOf(msg.sender, nativeTokenId),
            "Insufficient funds"
        );
        IdToCampaign[Id].campaignRunning = true;
        setApprovalForAll(address(this), true);
        emit campaignStarted(Id, IdToCampaign[Id].totalFunds, msg.sender, true);
    }

    function stopCampaign(uint256 _id) public {
        //this function stops the campaign
        require(IsCampaignCreated[_id] == true, "No campaign found");
        require(
            IdToCampaign[_id].campaignRunning == true,
            "Campaign is not started"
        );
        setApprovalForAll(address(this), false);
        IdToCampaign[_id].campaignRunning = false;
    }

    function addFundsToCampaign(uint256 _id, uint256 amount) public {
        //this function adds funds to the Ad
        require(
            IdToCampaign[_id].Advertiser == msg.sender,
            "only advertiser can add funds"
        );
        require(
            balanceOf(msg.sender, nativeTokenId) >= amount,
            "Insufficient Funds"
        );
        IdToCampaign[_id].totalFunds += amount;
        IdToCampaign[_id].currentFunds += amount;
    }

    function removeFundsFromCampaign(uint256 _id, uint256 amount) public {
        //this function removes funds from the Ad
        require(
            msg.sender == IdToCampaign[_id].Advertiser,
            "only Advertiser can remove funds from the campaign"
        );
        require(
            IdToCampaign[_id].currentFunds >= amount,
            "Current funds are less than the amount"
        );
        IdToCampaign[_id].currentFunds -= amount;
        IdToCampaign[_id].totalFunds -= amount;
    }

    function createPublisher(
        uint256 _clickReward,
        uint256 _displayReward
    ) public {
        //this function makes the user a publisher
        require(
            IsPublisher[msg.sender] == false,
            "You are already a publisher"
        );
        PublisherIds.increment();
        uint256 id = PublisherIds.current();
        IdToPublisher[id] = Publisher(
            id,
            msg.sender,
            _clickReward,
            _displayReward
        );
        IsPublisher[msg.sender] = true;
        publishersList.push(msg.sender);
        emit PublisherCreated(id, _clickReward, _displayReward, msg.sender);
    }

    function SubscribetoPublisher(uint256 _id, address _publisher) public {
        //this function adds the publisher to the list of  a particular Ad publishers
        require(
            IdToCampaign[_id].campaignRunning == true,
            "Campaign is not running"
        );
        require(IsPublisher[_publisher] == true, "Publisher is not registered");
        require(
            IsPublisherAdded[_id][_publisher] == false,
            "Publisher is already added"
        );
        require(
            IdToCampaign[_id].currentFunds >=
                IdToPublisher[_id].clickReward +
                    IdToPublisher[_id].displayReward,
            "Insufficient funds"
        );
        IdToCampaign[_id].publishers.push(_publisher);
        IsPublisherAdded[_id][_publisher] = true;
    }

    function UnSubscribetoPublisher(uint256 _id, address _publisher) public {
        //this function removes the publisher from the list of  a particular Ad publishers
        require(
            IdToCampaign[_id].campaignRunning == true,
            "Campaign is not running"
        );
        require(IsPublisher[_publisher] == true, "Publisher is not registered");
        require(
            IsPublisherAdded[_id][_publisher] == true,
            "Publisher is not added"
        );
        for (uint i = 0; i < IdToCampaign[_id].publishers.length; i++) {
            if (IdToCampaign[_id].publishers[i] == _publisher) {
                IdToCampaign[_id].publishers[i] = IdToCampaign[_id].publishers[
                    IdToCampaign[_id].publishers.length - 1
                ];
                IdToCampaign[_id].publishers.pop();
                IsPublisherAdded[_id][_publisher] = false;
            }
        }
    }

    function serveAd(
        uint256 _id,
        address _publisher
    ) public returns (string memory adURI) {
        //this function serves the Ad to the user
        require(
            IdToCampaign[_id].campaignRunning == true,
            "Campaign is not running"
        );
        require(IsPublisher[_publisher] == true, "Publisher is not registered");
        require(
            IsPublisherAdded[_id][_publisher] == true,
            "Publisher is not added"
        );
        require(
            IdToCampaign[_id].currentFunds >=
                IdToPublisher[_id].clickReward +
                    IdToPublisher[_id].displayReward,
            "Insufficient funds"
        );
        IdToCampaign[_id].currentFunds -= IdToPublisher[_id].displayReward;
        IdToCampaign[_id].display += 1;
        _safeTransferFrom(
            IdToCampaign[_id].Advertiser,
            _publisher,
            nativeTokenId,
            IdToPublisher[_id].displayReward,
            ""
        );

        emit AdServed(
            _id,
            IdToCampaign[_id].currentFunds,
            IdToCampaign[_id].Advertiser,
            _publisher
        );
        return uri(IdToCampaign[_id].id);
    }

    function transferClickReward(uint256 _adID, address _publisher) public {
        require(
            IdToCampaign[_adID].campaignRunning == true,
            "Campaign is not running"
        );
        require(IsPublisher[_publisher] == true, "Publisher is not registered");
        require(
            IsPublisherAdded[_adID][_publisher] == true,
            "Publisher is not added"
        );
        _safeTransferFrom(
            IdToCampaign[_adID].Advertiser,
            _publisher,
            nativeTokenId,
            IdToPublisher[_adID].clickReward,
            ""
        );
    }

    function getAd() public {
        //this function returns the Ad details
    }

    function getPublishers() public {
        //this function returns the list of publishers
    }

    function getCurrentFundsForAd() public {
        //this function returns the current funds for the Ad
    }

    function getRunningCampaigns() public {
        //this function returns the list of running campaigns
    }
}
