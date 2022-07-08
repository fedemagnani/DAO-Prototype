//SPDX-License-Identifier: MIT
pragma solidity >0.6.0;

interface IDBT{
    function getCurrentPolisAddress()external view returns (address);
    function isFounder(address)external view returns (bool);
    function isAssociate(address)external view returns (bool);
    function isPartner(address)external view returns (bool);
    function getNumberAssociates() external view returns (uint256);
}

//Proposal Legend:
// 0 → change Polis contract
// 1 → add members 
// 2 → add partners
// 3 → ostracism member -----------------> MUST BE INTEGRATED
// 4 → ostracism partner -----------------> MUST BE INTEGRATED
// 5 → vote individual reputation

contract PolisDiscoverBlockchainDep{
    struct proposal{ //we don't create a vote limit, since people could vote a number of times that is higher of total associates
        uint256 id;
        uint256 endingVote;
        uint256 inFavour;
        uint256 expiration; //for being scrutinized
        string object;
        address author;
        uint8 typeOfProposal;
        bool isGovernanceProp;
        bool isReputationProp;
        bool integrated;
        bool approved;
        bool scrutinized;
        bool executed; //modified via a hook
    }
    //inheritance → SOLIDITY DOCS
    struct integration{
        mapping(address=>bool) hasVoted;
        address newPolisProposed;
        address[] proposedAddresses;
        mapping(address=>uint256) proposedReputationMembers;
    }
    
    //IN FUTURE VERSIONS, DO NOT ALTER THE PRE-EXISTENT ORDER OF VARIABLES AS DECLARED 
     
    uint256 public totalReputation;
    uint256 public totalProposals;
    address public addressDBT;
    mapping(uint256=>proposal) public proposals;
    mapping(uint256=>integration) public integrations;
    mapping(address=>uint256) public reputation;
    uint8 public reputationIncentiveIntegration = 5;
    uint8 public reputationIncentiveVote = 1;
    uint8 public reputationIncentiveUtils = 3; //generic incentive for calling functions
    // mapping(uint256=>mapping(address=>bool)) public hasVoted;

    //PROPOSAL INTEGRATIONS

    // mapping(uint256=>address) public newPolisProposed;
    // mapping(uint256=>address[]) public proposedAddresses; //Governance and reputation proposal will fall here
    // mapping(uint256=>mapping(address=>uint256)) public proposedReputationMembers;
    

    constructor(address _addressDBT){
        addressDBT=_addressDBT;
    }

    event newProposal(address,uint256);
    event proposalIntegrated(uint256);
    event proposalApproved(uint256);
    event proposalRejected(uint256);
    event proposalExecuted(uint256);
    event reputationTransferred(address,address,uint256);
    event newVote(address,uint256);

    modifier onlyFounder() {
        require(IDBT(addressDBT).isFounder(msg.sender), "Caller is not a Founder");
        _;
    }
    modifier onlyAssociate() {
        require(IDBT(addressDBT).isAssociate(msg.sender), "Caller is not an Associate");
        _;
    }
    modifier onlyPartner() {
        require(IDBT(addressDBT).isPartner(msg.sender), "Caller is not a Partner");
        _;
    }
    modifier preliminaryIntegrationCheck(uint _id){
        require(!proposals[_id].integrated,"Proposal already integrated");
        require(msg.sender==proposals[_id].author,"Only the author can integrate proposal"); //in this way we check it is also an associate, since createProposal is onlyAssociate method
        proposals[_id].integrated=true;
        _;
    }
    modifier preliminaryVotingCheck(uint _id){
        require(block.timestamp<proposals[_id].endingVote,"Voting has ended");
        require(!integrations[_id].hasVoted[msg.sender],"You've already voted");
        require(!proposals[_id].approved,"Proposal has already been approved");
        require(proposals[_id].integrated,"Proposal must integrated");
        integrations[_id].hasVoted[msg.sender]=true;
        _;
    }
    modifier preliminaryScrutinizingCheck(uint _id){
        require(block.timestamp>proposals[_id].endingVote,"Voting is still open");
        require(block.timestamp<proposals[_id].expiration,"Proposal expired");
        require(!proposals[_id].scrutinized,"Proposal already checked");
        proposals[_id].scrutinized=true;
        _;
    }

    function _getNumberAssociates() internal view returns(uint256){
        return IDBT(addressDBT).getNumberAssociates();
    }

    function getProposal(uint256 _id)public view returns(proposal memory){
        return proposals[_id];
    }
    function getNewPolisProposed(uint256 _id)public view returns(address){
        return integrations[_id].newPolisProposed;
    }
    function getProposedAddresses(uint256 _id) public view returns (address[]memory){
        return integrations[_id].proposedAddresses;
    }

    function createProposal(string memory _object, uint8 _type, bool _isGovernanceProp, bool _isReputationProp, uint256 _endingVote, uint256 _expiration) public onlyAssociate returns(uint256){
        //consider changing this function like integrate proposal
        require(_expiration>_endingVote,"Small expiration");
        proposals[totalProposals+1]=proposal({
            id:totalProposals+1,
            typeOfProposal:_type,
            // startingVote:block.timestamp,
            endingVote:_endingVote,
            inFavour:0,
            expiration:_expiration,
            author:msg.sender,
            object:_object,
            isGovernanceProp:_isGovernanceProp,
            isReputationProp:_isReputationProp,
            integrated:false,
            approved:false,
            scrutinized:false,
            executed:false
        });
        emit newProposal(msg.sender,totalProposals+1);
        totalProposals+=1;
        return totalProposals;
    }

    function _postProposalIntegration(address _author, uint256 _id) internal {
        reputation[_author]+=reputationIncentiveIntegration; //Add n unit of reputation for having integrated the proposal 
        totalReputation+=reputationIncentiveIntegration;
        emit proposalIntegrated(_id);
    }
    function _postVote(address _voter, uint256 _id) internal{
        proposals[_id].inFavour+=1;
        reputation[_voter]+=reputationIncentiveVote; //Increase reputation by one unit for having voted
        totalReputation+=reputationIncentiveVote;
        emit newVote(_voter,_id);
    }
    function _postScrutiny(address _scrutinizer, uint256 _id) internal{
        // reputationIncentiveScrutiny
        proposals[_id].approved=true;
        reputation[_scrutinizer]+=reputationIncentiveUtils; //Increase reputation by one unit for having voted
        totalReputation+=reputationIncentiveUtils;
        //No politics: we deliberately don't assign further reputation points to the author of the proposal
        emit proposalApproved(_id);
    }
    function _postExecutionProposal(address _caller, uint256 _id) internal {
        proposals[_id].executed=true;
        reputation[_caller]+=reputationIncentiveUtils; //Increase reputation by one unit for having voted
        totalReputation+=reputationIncentiveUtils;
        emit proposalExecuted(_id);
    }

    function integrateProposalAddress(uint256 _id, address _newPolis)public preliminaryIntegrationCheck(_id){
        //Propose new polis address
        integrations[_id].newPolisProposed = _newPolis;
        _postProposalIntegration(msg.sender,_id);
    }
    function integrateProposalArrayAddress(uint256 _id, address[] memory _newAddresses)public preliminaryIntegrationCheck(_id){
        // integration storage _int = integrations.push();
        // _int.proposedAddresses = _newAddresses;
        
        integrations[_id].proposedAddresses = _newAddresses;
        // integrations[_id]=_int;

        _postProposalIntegration(msg.sender,_id);
    }

    function voteGovernanceProposal(uint256 _id) public onlyAssociate preliminaryVotingCheck(_id){
        //good for proposals of type 0,1,2,3
        require(proposals[_id].isGovernanceProp,"Not a governance proposal");
        _postVote(msg.sender,_id);
    }

    function closeGovernanceProposal(uint256 _id) public preliminaryScrutinizingCheck(_id){ //no need to put it as onlyAssociate
        //good for proposals of type 0,1,2,3
        require(proposals[_id].isGovernanceProp,"Not a governance proposal");
        if(100*proposals[_id].inFavour>50*_getNumberAssociates()){
            _postScrutiny(msg.sender,_id);
        }
        else{
            emit proposalRejected(_id);
        }
    }

    function voteReputationProposal(uint256 _id, address _champion) public onlyAssociate preliminaryVotingCheck(_id){
        //good for proposals of type 4 
        require(proposals[_id].isReputationProp,"Not a reputation proposal");
        require(msg.sender!=_champion,"Self-voting");
        integrations[_id].proposedReputationMembers[_champion]+=1;
        //if the _champion is not present in proposedChampions[_id], the vote won't count since the reputation assignation will iterate proposedChampions[_id]
        _postVote(msg.sender,_id);
    }

    function closeReputationProposal(uint256 _id) public preliminaryScrutinizingCheck(_id){
        require(proposals[_id].isReputationProp,"Not a reputation proposal");
        for(uint i=0; i<integrations[_id].proposedAddresses.length; i++){
            //add the the number of received votes directly to the reputation score of the address
            reputation[integrations[_id].proposedAddresses[i]]+=integrations[_id].proposedReputationMembers[integrations[_id].proposedAddresses[i]];
        }
        _postScrutiny(msg.sender,_id);
    }

    function transferReputation(address _to, uint256 _amount) public {
        require(reputation[msg.sender]>=_amount,"Not enough reputation");
        unchecked {
            reputation[msg.sender] = reputation[msg.sender] - _amount;
        }
        reputation[_to] += _amount;
        emit reputationTransferred(msg.sender, _to, _amount);
    }

    //POST EXECUTION FUNCTIONS, called by other contracts such as DBT
    function removeReputation(address[]memory _ostracized, uint256 _id) public{
        //We force that this function is called via DBT and refers ro a ostracism proposal
        require(msg.sender==addressDBT&&proposals[_id].isGovernanceProp&&(proposals[_id].typeOfProposal==3||proposals[_id].typeOfProposal==4),"Unhautorized");
        for (uint i=0;i<_ostracized.length;i++){
            reputation[_ostracized[i]]=0;
        }
        _postExecutionProposal(tx.origin,_id);
    }
    function addedAssociatesOrPartners(uint256 _id)public{
        require(msg.sender==addressDBT&&proposals[_id].isGovernanceProp&&(proposals[_id].typeOfProposal==1||proposals[_id].typeOfProposal==2),"Unhautorized");
        _postExecutionProposal(tx.origin,_id);
    }
    function polisAddressChanged(uint256 _id)public{
        require(msg.sender==addressDBT&&proposals[_id].isGovernanceProp&&proposals[_id].typeOfProposal==0,"Unhautorized");
        _postExecutionProposal(tx.origin,_id);
    }
}