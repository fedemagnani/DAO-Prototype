//SPDX-License-Identifier: MIT
pragma solidity >0.6.0;
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

struct proposal{ 
    uint256 id;
    uint256 endingVote;
    uint256 inFavour;
    uint256 expiration; //for being scrutinized
    address author;
    uint8 typeOfProposal;
    bool isGovernanceProp;
    bool[] status; // scrutinized → approved → executed

    address[] proposedAddresses; //without mapping, reputation proposal becomes a correspondence between proposedAddresses and proposedUints, more versatile for future type of vote proposals
    uint256[] proposedUints;
    bool[] proposedBools;
    string[] proposedObjects;
    //... add others?
}

interface IPolis{
    //We've put everything under getProposal()
    function getProposal(uint256)external returns(proposal memory);
    function removeReputation(uint256 _id) external;
    function addedAssociatesOrPartners(uint256 _id)external;
    function polisAddressChanged(uint256 _id)external;
}

contract DiscoverBlockchainToken is ERC1155{

    event newAssociates(address[] _newMembers);
    event newPartners(address[] _newPartners);
    event newOstracismPartners(address[]);
    event newPolis(address);
    event newAgora(address);
    event tokenClaimed(address);

    uint256 public totalFounders;
    uint256 public totalAssociates;
    uint256 public totalPartners;
    uint256 public _totalSupply;
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
            totalFounders++;
            totalAssociates++;
        }
    }

    modifier onlyLeviathan() { //id of the proposal
        //id=0 won't exist. createProposal() create the first ever proposal with id=1
        require(founders[msg.sender]&&!dao||dao&&msg.sender==agoraAddress, "Caller is not the Leviathan"); //maybe you should put agora address
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
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
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
        return totalAssociates;
    }
    //////////////////////////////////////

    
    function setAgoraAddress(address _agoraAddress) public onlyLeviathan(){
        agoraAddress = _agoraAddress;
        emit newAgora(agoraAddress);
    }

    function setPolisAddress(address _polisAddress) public onlyLeviathan(){
        // proposal memory prop = IPolis(agoraAddress).getProposal(_id);
        // require(prop.typeOfProposal==0,"Not a new polis proposal");
        polisAddress = _polisAddress;
        // IPolis(agoraAddress).polisAddressChanged(_id);
        emit newPolis(polisAddress);
    }

    function addAssociates(address[]memory _newMembers) public onlyLeviathan(){
        // proposal memory prop = IPolis(agoraAddress).getProposal(_id);
        // require(prop.typeOfProposal==1,"Not a new associates proposal");
        // address[]memory _newMembers=prop.proposedAddresses;
        for(uint i=0;i<_newMembers.length;i++){
            associates[_newMembers[i]] = true;
            totalAssociates++;
        }
        // IPolis(agoraAddress).addedAssociatesOrPartners(_id);
        emit newAssociates(_newMembers);
    }

    function removeAssociates(address[]memory _oldMembers) public onlyLeviathan(){
        // proposal memory prop = IPolis(agoraAddress).getProposal(_id);
        // require(prop.typeOfProposal==3,"Not a ostracism associate proposal");
        // address[]memory _oldMembers=prop.proposedAddresses;
        for(uint i=0;i<_oldMembers.length;i++){
            if(tokenClaimedList[_oldMembers[i]][1]){ //we remove the tokens claimed; 
                burnToken(_oldMembers[i],1);
            }
            associates[_oldMembers[i]] = false;
            totalAssociates--;
        }
        // IPolis(agoraAddress).removeReputation(_id);
        emit newOstracismPartners(_oldMembers);
    }

    function addPartners(address[]memory _newPartners) public onlyLeviathan(){
        // proposal memory prop = IPolis(agoraAddress).getProposal(_id);
        // require(prop.typeOfProposal==2,"Not a new partners proposal");
        // address[]memory _newPartners=prop.proposedAddresses;
        for(uint i=0;i<_newPartners.length;i++){
            partners[_newPartners[i]] = true;
            totalPartners++;
        }
        // IPolis(agoraAddress).addedAssociatesOrPartners(_id);
        emit newPartners(_newPartners);
    }

    function removePartners(address[]memory _oldPartners) public onlyLeviathan(){
        // require(prop.typeOfProposal==4,"Not a ostracism partner proposal");
        // address[]memory _oldMembers=prop.proposedAddresses;
        for(uint i=0;i<_oldPartners.length;i++){
            if(tokenClaimedList[_oldPartners[i]][2]){ //we remove the tokens claimed; 
                burnToken(_oldPartners[i],2);
            }
            partners[_oldPartners[i]] = false;
            totalPartners--;
        }
        // IPolis(agoraAddress).removeReputation(_id);
        emit newOstracismPartners(_oldPartners);
    }

    function burnToken(address _ostracized, uint256 _tokenID)internal{
        tokenClaimedList[_ostracized][_tokenID]=false; //we leave the possibility to be accepted in future proposals
        _burn(_ostracized,_tokenID,balanceOf(_ostracized, _tokenID));
        _totalSupply--;
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
        _totalSupply++;
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

    function setInitialPolisAddress(address _newAddress) public onlyLeviathan(){
        polisAddress = _newAddress;
    }

    function setInitialAgoraAddress(address _newAddress) public onlyLeviathan(){
        agoraAddress = _newAddress;
    }

    function openTheCages() public onlyLeviathan(){
        dao=true;
    }

}