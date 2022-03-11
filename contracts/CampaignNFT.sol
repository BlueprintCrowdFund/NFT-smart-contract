// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.10;

// This constract is for creating NFT's for the Bluepring DAO on behalf of
// the registering startup companies

import "hardhat/console.sol";
import {Base64} from "./libs/Base64.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import { StringUtils } from "./libs/StringUtils.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract CampaignNFT is Ownable, ERC721URIStorage {

  // Magic given to us by OpenZeppelin to help us keep track of tokenIds.
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  // set base price
  // users pay (no of weeks * baseprice)
  uint private PRICE;

  // We'll be storing our NFT images on chain as SVGs
  string svgPartOne = '<svg>';
  string svgPartTwo = '</svg>';

  // Campaigns
  struct Campaign {
    string name;
    uint256 budget;
    uint startDate; //date when campaign begins / can be issued
    uint endDate; // date when capaign gets expired
    bool isRedeemed;
    string nftTier1;
    string nftTier2;
    string nftTier3;
  }

  error Unauthorized();
  error AlreadyRegistered();
  error InsufficientBalance(uint256 _available, uint256 _required);
  error InvalidCampaignName(string name);
  error InvalidCampaignDuration();

  // campaigns count
  uint8 campaignCount;

  // mapping of campaign names to client eth addresses
  mapping (string => address) private campaign2Owner;

  // keep track of campaigns
  mapping (uint => Campaign) campaigns;

  // make contract is payable and ownable
  constructor(uint price) payable Ownable() ERC721("Blueprint DAO", "BDAO") {
    PRICE = price;
  }

  // ensure campaign does not already exist
  modifier campaignNameNotExists(string calldata campaignName) {
    if(campaign2Owner[campaignName] != address(0)) revert AlreadyRegistered() ;
    _;
  }

  /** ensure campaign does already exist
  * @param campaignName name of campaign
  */
  modifier camapaignExists(string calldata campaignName) {
    if (campaign2Owner[campaignName] != address(0)) revert Unauthorized();
    _;
  }

  /** ensure current user is owner of given campaign
  * @param campaignName name of campaign
  */
  modifier isOwner(string calldata campaignName) {
    if (campaign2Owner[campaignName] != msg.sender) revert Unauthorized();
    _;
  }

  /** make sure user has sufficient funds to pay price for the campaign
  * total price = base price * duration (in days) 7 days minimum
  * @param endDate desired campaign end date
  */
  modifier hasFunds(uint endDate) {
    // make end date is in at least 1 week
    if (endDate < (block.timestamp + 7 days)) revert InvalidCampaignDuration();

    uint256 _price = getPrice(endDate);
    console.log("this txn will cost %d", _price);

    // ensure correct balance
    if (msg.value < _price) revert InsufficientBalance({
      _available: msg.value,
      _required: _price
    });

    _;
  }

  function getPrice(uint endDate) public view returns (uint256) {
    uint numDays = (endDate - block.timestamp) / 60 / 60 / 24;
    uint cost = numDays * PRICE; // base price of 0.5 eth
    return (cost * 10**16);
  }

  /** limit length of campaign names to 4 - 25 chars
  ** we hate long campaign names! ;)
  * @param campaignName name of campaign
  */
  function valid(string calldata campaignName) public pure returns(bool) {
    return StringUtils.strlen(campaignName) >= 3 && StringUtils.strlen(campaignName) <= 25;
  }

  // token uri
  function _getTokenURI(string memory _campaignName, string memory _data) private view returns (string memory) {
    string memory finalSvg = string(abi.encodePacked(svgPartOne, _data, svgPartTwo));
  	uint256 length = StringUtils.strlen(_campaignName);
		string memory strLen = Strings.toString(length);

    // TEMPORARY
    string memory json = Base64.encode(
      bytes(
        string(
          abi.encodePacked(
            '{"name": "',
            _campaignName,
            '", "description": "Description of NFT", "image": "data:image/svg+xml;base64,',
            Base64.encode(bytes(finalSvg)),
            '","length":"',
            strLen,
            '"}'
          )
        )
      )
    );

    return string( abi.encodePacked("data:application/json;base64,", json));
  }

    // validate length of campaign name
    if (!valid(campaignName)) revert InvalidCampaignName(campaignName);

    uint256 newRecordId = _tokenIds.current();

		console.log("\n--------------------------------------------------------");
    // additional (meta) data to put in NFT
    string memory _data = "";
	  console.log("Final tokenURI", _getTokenURI(campaignName, _data));
	  console.log("--------------------------------------------------------\n");

    _safeMint(msg.sender, newRecordId);
    _setTokenURI(newRecordId, _getTokenURI(campaignName, _data));

    campaign2Owner[campaignName] = msg.sender;
    campaignCount++;

    campaigns[newRecordId] = Campaign(
      campaignName,
      msg.value,
      block.timestamp,
      endDate,
      false,
      "",
      "",
      ""
    );

    _tokenIds.increment();
  }

   // get list of all campaigns names
  function getCampaigns() public view returns (Campaign[] memory) {
    console.log("Getting all campaigns from contract...");

    Campaign[] memory allNames = new Campaign[](_tokenIds.current());

    for (uint i = 0; i < _tokenIds.current(); i++) {
      allNames[i] = campaigns[i];
      console.log("Name for token %d is %s", i, allNames[i].name);
    }

    return allNames;
  }


  // allow only owner to withdraw
  function withdraw() public onlyOwner {
    // get constract balance
    uint balance = address(this).balance;

    (bool success, ) = msg.sender.call{value: balance}("");
    require(success, "Failed to withdraw Matic!");
  }
}