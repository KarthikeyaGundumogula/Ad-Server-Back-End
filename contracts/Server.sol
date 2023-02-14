//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/Counters.sol";
import "./Token.sol";

contract Server is Token {
    using Counters for Counters.Counter;
    Counters.Counter AdIds;
    Counters.Counter PublisherIds;
    address public owner;
    uint256 public nativeTokenId;
    uint256[] public runningCampaignIdsList;

    struct Ad {
        uint256 id;
        uint256 totalFunds;
        uint256 currentFunds;
        uint256 clicks;
        uint256 display;
        address Advertiser;
        uint256[] PublisherIds;
        bool campaignRunning;
    }

    struct Publisher {
        uint256 id;
        string url;
        address publisher;
        uint256 clickReward;
        uint256 displayReward;
        uint256[] AdIds;
    }

    mapping(uint256 => Ad) public IdToCampaign;
    mapping(uint256 => Publisher) public IdToPublisher;
    mapping(address => uint256) public PublisherAddressToId;
    mapping(address => uint256[]) public AdIdsListByAdvertiser;
    mapping(address => uint256[]) public runningCampaignIdsListByAdvertiser;
    mapping(uint256 => bool) IsCampaignCreated;
    mapping(address => bool) IsPublisher;
    mapping(uint256 => mapping(address => bool)) IsPublisherAdded;

    event AdCreated(
        uint256 id,
        uint256 totalFunds,
        string AdURI,
        address Advertiser
    );

    event Click(uint256 id, uint256 PublisherId);
    event CampaignStarted(uint256 id);
    event CampaignStopped(uint256 id);
    event PublisherAdded(uint256 id, uint256 PublisherId);
    event PublisherRemoved(uint256 id, uint256 PublisherId);

    event fundsAdded(uint256 id, uint256 AddedAmount);

    event fundsRemoved(uint256 id, uint256 RemovedAmount);

    event PublisherCreated(
        uint256 id,
        uint256 clickReward,
        uint256 displayReward,
        address publisher,
        string url
    );

    event AdServed(uint256 Adid, uint publisherId);

    constructor() {
        nativeTokenId = AdIds.current();
        owner = msg.sender;
    }

    function createAd(
        string memory _AdURI,
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
            _totalFunds,
            _totalFunds,
            0,
            0,
            msg.sender,
            new uint256[](0),
            false
        );
        IsCampaignCreated[id] = true;
        AdIdsListByAdvertiser[msg.sender].push(id);

        emit AdCreated(id, _totalFunds, _AdURI, msg.sender);

        return id;
    }

    function startCampaign(uint256 Id) public {
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
        runningCampaignIdsList.push(Id);
        runningCampaignIdsListByAdvertiser[msg.sender].push(Id);
        setApprovalForAll(address(this), true);
        emit CampaignStarted(Id);
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
        for (uint256 i = 0; i < runningCampaignIdsList.length; i++) {
            if (runningCampaignIdsList[i] == _id) {
                runningCampaignIdsList[i] = runningCampaignIdsList[
                    runningCampaignIdsList.length - 1
                ];
                runningCampaignIdsList.pop();
                break;
            }
        }
        for (
            uint256 i = 0;
            i < runningCampaignIdsListByAdvertiser[msg.sender].length;
            i++
        ) {
            if (runningCampaignIdsListByAdvertiser[msg.sender][i] == _id) {
                runningCampaignIdsListByAdvertiser[msg.sender][
                    i
                ] = runningCampaignIdsListByAdvertiser[msg.sender][
                    runningCampaignIdsListByAdvertiser[msg.sender].length - 1
                ];
                runningCampaignIdsListByAdvertiser[msg.sender].pop();
                break;
            }
        }
        emit CampaignStopped(_id);
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
        emit fundsAdded(_id, amount);
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
        emit fundsRemoved(_id, amount);
    }

    function createPublisher(
        uint256 _clickReward,
        uint256 _displayReward,
        string memory _url
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
            _url,
            msg.sender,
            _clickReward,
            _displayReward,
            new uint256[](0)
        );
        IsPublisher[msg.sender] = true;
        PublisherAddressToId[msg.sender] = id;
        emit PublisherCreated(
            id,
            _clickReward,
            _displayReward,
            msg.sender,
            _url
        );
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
        IdToCampaign[_id].PublisherIds.push(PublisherAddressToId[_publisher]);
        IsPublisherAdded[_id][_publisher] = true;
        IdToPublisher[PublisherAddressToId[_publisher]].AdIds.push(_id);
        emit PublisherAdded(_id, PublisherAddressToId[_publisher]);
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
        uint256 publisherId = PublisherAddressToId[_publisher];
        for (uint i = 0; i < IdToCampaign[_id].PublisherIds.length; i++) {
            if (IdToCampaign[_id].PublisherIds[i] == publisherId) {
                IdToCampaign[_id].PublisherIds[i] = IdToCampaign[_id]
                    .PublisherIds[IdToCampaign[_id].PublisherIds.length - 1];
                IdToCampaign[_id].PublisherIds.pop();
                IsPublisherAdded[_id][_publisher] = false;
            }
        }
        for (uint i = 0; i < IdToPublisher[publisherId].AdIds.length; i++) {
            if (IdToPublisher[publisherId].AdIds[i] == _id) {
                IdToPublisher[publisherId].AdIds[i] = IdToPublisher[publisherId]
                    .AdIds[IdToPublisher[publisherId].AdIds.length - 1];
                IdToPublisher[publisherId].AdIds.pop();
            }
        }
        emit PublisherRemoved(_id, publisherId);
    }

    function serveAd(
        uint256 _id,
        address _Advertiser
    ) public returns (string memory adURI) {
        //this function serves the Ad to the user
        require(
            IdToCampaign[_id].campaignRunning == true,
            "Campaign is not running"
        );
        require(IsPublisher[msg.sender] == true, "Publisher is not registered");
        require(
            IsPublisherAdded[_id][msg.sender] == true,
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
            _Advertiser,
            msg.sender,
            nativeTokenId,
            IdToPublisher[_id].displayReward,
            ""
        );

        emit AdServed(_id, PublisherAddressToId[msg.sender]);
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
        uint publisherId = PublisherAddressToId[_publisher];
        IdToCampaign[_adID].totalFunds -= IdToPublisher[publisherId]
            .clickReward;
        IdToCampaign[_adID].currentFunds -= IdToPublisher[publisherId]
            .clickReward;
        IdToCampaign[_adID].clicks += 1;
        emit Click(_adID, PublisherAddressToId[_publisher]);
    }
}