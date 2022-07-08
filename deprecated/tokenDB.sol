//SPDX-License-Identifier: MIT
pragma solidity >0.6.0;
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

struct proposal{ //we don't create a vote limit, since people could vote a number of times that is higher of total associates
    uint256 id;
    uint256 typeOfProposal;
    uint256 startingVote;
    uint256 endingVote;
    uint256 inFavour;
    uint256 expiration; //for being scrutinized
    address author;
    string object;
    bool isGovernanceProp;
    bool isReputationProp;
    bool integrated;
    bool approved;
    bool scrutinized;
    bool executed; //modified via a hook
}

interface IPolis{
    function getProposal(uint256)external returns(proposal memory);
    function getNewPolisProposed(uint256 _id)external view returns(address);
    function getProposedAddresses(uint256 _id)external view returns(address[]memory);
    function removeReputation(address[]memory _ostracized, uint256 _id) external;
    function addedAssociatesOrPartners(uint256 _id)external;
    function polisAddressChanged(uint256 _id)external;
}

contract DiscoverBlockchainTokenDep is ERC1155{

    event newAssociates(address[] _newMembers);
    event newPartners(address[] _newPartners);
    event newPolis(address);
    event tokenClaimed(address);

    uint256 public totalMembers;
    uint256 public totalPartners;
    address public polisAddress;
    address public agoraAddress;

    string public name = "Discover Blockchain Token";
    string public symbol = "DBT";
    mapping(address=>bool) public founders; //updated at the deployment of the contract and never again
    mapping(address=>bool) public associates;
    mapping(address=>bool) public partners;
    mapping(address=>mapping(uint256=>bool)) public tokenClaimedList; //address -> token type -> received

    // address public pendingAssociates; //why we would write "official partner" on the token if associates must then be approved; 

    bool public dao;

    constructor(address[]memory _founders) ERC1155("ipfs://..."){ //SET HERE THE IPFS ADDRESS!
        for(uint i=0;i<_founders.length;i++){
            founders[_founders[i]] = true;
            associates[_founders[i]] = true;
            totalMembers+=1;
        }
    }

    modifier onlyLeviathan(uint256 _id) { //id of the proposal
        //id=0 won't exist. createProposal() create the first ever proposal with id=1
        require(founders[msg.sender]&&!dao||dao, "Caller is not the Leviathan");
        if(dao){
            proposal memory prop = IPolis(agoraAddress).getProposal(_id);
            require(prop.approved,"Proposal is not approved");
            require(prop.isGovernanceProp, "Not a governance proposal");
        }
        _;
    }
    modifier onlyAssociate() {
        require(associates[msg.sender], "Caller is not an Associate");
        _;
    }
    modifier onlyPartner() {
        require(partners[msg.sender], "Caller is not a Partner");
        _;
    }

    //////////////////////////////////////
    function getCurrentPolisAddress()public view returns (address){ //in order to give aaccess to agora address
        return polisAddress;
    }
    function isFounder(address _addy)public view returns (bool){ //checked by polis modifier
        return founders[_addy];
    }
    function isAssociate(address _addy)public view returns (bool){ //checked by polis modifier
        return associates[_addy];
    }
    function isPartner(address _addy)public view returns (bool){ //checked by polis modifier
        return partners[_addy];
    }
    function getNumberAssociates() public view returns (uint256){
        return totalMembers;
    }
    //////////////////////////////////////

    function setPolisAddress(uint256 _id) public onlyLeviathan(_id){
        polisAddress = IPolis(agoraAddress).getNewPolisProposed(_id);
        IPolis(agoraAddress).polisAddressChanged(_id);
        emit newPolis(polisAddress);
    }

    // function setAgoraAddress(uint256 _id) public onlyLeviathan(_id){
    // //     agoraAddress = _newAddress;
    // }

    function addAssociates(uint256 _id) public onlyLeviathan(_id){
        address[]memory _newMembers=IPolis(agoraAddress).getProposedAddresses(_id);
        for(uint i=0;i<_newMembers.length;i++){
            associates[_newMembers[i]] = true;
            totalMembers+=1;
        }
        IPolis(agoraAddress).addedAssociatesOrPartners(_id);
        emit newAssociates(_newMembers);
    }

    function addPartners(uint256 _id) public onlyLeviathan(_id){
        address[]memory _newPartners=IPolis(agoraAddress).getProposedAddresses(_id);
        for(uint i=0;i<_newPartners.length;i++){
            partners[_newPartners[i]] = true;
        }
        IPolis(agoraAddress).addedAssociatesOrPartners(_id);
        emit newPartners(_newPartners);
    }

    function claimToken()public{
        require(founders[msg.sender]||associates[msg.sender]||partners[msg.sender],"Unauthorized to claim token");
        if(founders[msg.sender]){
            require(!tokenClaimedList[msg.sender][0],"Token already claimed");
            _mint(msg.sender,0,1,"0x000"); //token0 == token founder
        }
        if(associates[msg.sender]){
            require(!tokenClaimedList[msg.sender][1],"Token already claimed");
            _mint(msg.sender,1,1,"0x000"); //token1 == token associate
        }
        if(partners[msg.sender]){
            require(!tokenClaimedList[msg.sender][2],"Token already claimed");
            _mint(msg.sender,2,1,"0x000"); //token2 == token partner
        }
        emit tokenClaimed(msg.sender);
    }

    function safeTransferFrom(address from,address to,uint256 id,uint256 amount,bytes memory data) public virtual override {
        // require(from==msg.sender&&(founders[msg.sender]||associates[msg.sender]||partners[msg.sender]),"Unauthorized to transfer token");
        
        //you should check also if there is a pending proposal and the associate voted,
        //  in that case, the transfer couldn't be done until the end of the proposal
        if(id==1){
            //token1 == token associate
            associates[tx.origin]=false;
            associates[to]=true;
        }
        if(id==2){
            //token2 == token partner
            partners[tx.origin]=false;
            partners[to]=true;
        }
        tokenClaimedList[tx.origin][id]=false; //if the associate/partner wants to come back, he will be allowed to claim a new token
        tokenClaimedList[to][id]=true; //otherwise recipient could claim a new token
        super.safeTransferFrom(from,to,id,amount,data);
    }

    function safeBatchTransferFrom(address from,address to,uint256[] memory ids,uint256[] memory amounts,bytes memory data) public virtual override {
        // require(from==msg.sender&&(founders[msg.sender]||associates[msg.sender]||partners[msg.sender]),"Unauthorized to transfer token");
        
        //you should check also if there is a pending proposal and the associate voted,
        //  in that case, the transfer couldn't be done until the end of the proposal
        for(uint i=0; i<ids.length; i++){
            if(ids[i]==1){
                //token1 == token associate
                associates[tx.origin]=false;
                associates[to]=true;
            }
            if(ids[i]==2){
                //token2 == token partner
                partners[tx.origin]=false;
                partners[to]=true;
            }
            tokenClaimedList[tx.origin][ids[i]]=false; //if the associate/partner wants to come back, he will be allowed to claim a new token
            tokenClaimedList[to][ids[i]]=true; //otherwise recipient could claim a new token
        }
        super.safeBatchTransferFrom(from,to,ids,amounts,data);
    }

    function setInitialPolisAddress(address _newAddress) public onlyLeviathan(0){
        polisAddress = _newAddress;
    }

    function setInitialAgoraAddress(address _newAddress) public onlyLeviathan(0){
        agoraAddress = _newAddress;
    }

    function openTheCages() public onlyLeviathan(0){
        dao=true;
    }

}